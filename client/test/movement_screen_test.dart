import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/movement_screen.dart';

/// V2 item 9 — Contador de passos. O sensor real (pacote `pedometer`) usa
/// um canal de plataforma que não existe em ambiente de teste de widget
/// — MovementService.currentStepsSinceBoot() captura essa falha e
/// retorna null (mesmo princípio de resiliência do FeedbackService), o
/// que a tela trata como "sensor indisponível agora", nunca como erro
/// fatal. Isso é o que permite testar o layout sem mockar hardware.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    required this.movementEnabled,
    this.currentCycle,
    this.pendingCycle,
    this.dailyGoalSteps,
    this.recentCycles = const [],
  }) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  bool movementEnabled;
  Map<String, dynamic>? currentCycle;
  Map<String, dynamic>? pendingCycle;
  int? dailyGoalSteps;
  List<Map<String, dynamic>> recentCycles;
  final List<String> calls = [];

  @override
  Future<Map<String, dynamic>> movementStatus() async {
    calls.add('status');
    return {
      'movement_enabled': movementEnabled,
      'daily_goal_steps': dailyGoalSteps,
      'current_cycle': currentCycle,
      'pending_report_cycle': pendingCycle,
      'recent_cycles': recentCycles,
    };
  }

  @override
  Future<Map<String, dynamic>> setMovementGoal(int? dailyGoalSteps) async {
    calls.add('set_goal');
    this.dailyGoalSteps = dailyGoalSteps;
    return {'daily_goal_steps': dailyGoalSteps};
  }

  @override
  Future<Map<String, dynamic>> enableMovement() async {
    calls.add('enable');
    movementEnabled = true;
    return {'status': 'ok'};
  }

  @override
  Future<Map<String, dynamic>> disableMovement() async {
    calls.add('disable');
    movementEnabled = false;
    return {'status': 'ok'};
  }
}

Future<void> _pumpMovementScreen(WidgetTester tester, ApiClient client) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MovementScreen(client: client),
    ),
  );
  // pumpAndSettle trava com o CelebrationOverlay (confete usa animação
  // indeterminada) — mesmo achado já documentado em challenge_screen
  // tests. currentStepsSinceBoot() usa um timeout real de 5s esperando
  // o canal de plataforma do sensor (inexistente em teste) — o pump de
  // 6s garante que esse timeout já resolveu antes das asserções.
  await tester.pump();
  await tester.pump(const Duration(seconds: 6));
}

void main() {
  testWidgets('mostra botão de ativar quando o movimento está desligado', (tester) async {
    final client = _FakeApiClient(movementEnabled: false);
    await _pumpMovementScreen(tester, client);

    expect(find.text('Ativar contador de passos'), findsOneWidget);
    expect(find.text('Desativar'), findsNothing);
  });

  testWidgets('mostra ciclo atual e trata sensor indisponível quando já ativado', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-1',
        'cycle_start_at': DateTime.utc(2026, 8, 21).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 22).toIso8601String(),
        'steps_collected': 4000,
        'xp_awarded': 20,
      },
    );
    await _pumpMovementScreen(tester, client);

    expect(find.text('Passos coletados neste ciclo: 4000'), findsOneWidget);
    // Sem canal de plataforma mockado, o sensor é tratado como
    // indisponível — a tela nunca deve travar ou lançar exceção por isso.
    expect(find.text('Não foi possível ler o sensor de passos agora.'), findsOneWidget);
    expect(find.text('Desativar'), findsOneWidget);
  });

  testWidgets('mostra aviso de ciclo pendente dentro da janela de graça', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-2',
        'cycle_start_at': DateTime.utc(2026, 8, 22).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 23).toIso8601String(),
        'steps_collected': 0,
        'xp_awarded': 0,
      },
      pendingCycle: {
        'id': 'cycle-1',
        'cycle_start_at': DateTime.utc(2026, 8, 21).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 22).toIso8601String(),
        'steps_collected': 7000,
        'xp_awarded': 40,
      },
    );
    await _pumpMovementScreen(tester, client);

    expect(find.textContaining('7000 passos pra coletar'), findsOneWidget);
    expect(find.text('Coletar ciclo anterior'), findsOneWidget);
  });

  testWidgets('mostra gráfico de progresso e rótulo quando há meta diária definida', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      dailyGoalSteps: 10000,
      currentCycle: {
        'id': 'cycle-3',
        'cycle_start_at': DateTime.utc(2026, 8, 22).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 23).toIso8601String(),
        'steps_collected': 5000,
        'xp_awarded': 40,
      },
    );
    await _pumpMovementScreen(tester, client);

    expect(find.text('Meta diária: 10000 passos'), findsOneWidget);
    expect(find.text('50% da meta'), findsOneWidget);
    expect(find.text('Editar meta'), findsOneWidget);
    expect(find.byType(PieChart), findsWidgets);
  });

  testWidgets('define uma meta nova via diálogo e chama PUT /movement/goal', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-4',
        'cycle_start_at': DateTime.utc(2026, 8, 22).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 23).toIso8601String(),
        'steps_collected': 0,
        'xp_awarded': 0,
      },
    );
    await _pumpMovementScreen(tester, client);

    expect(find.text('Definir meta diária'), findsOneWidget);
    await tester.tap(find.text('Definir meta diária'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '20000');
    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(client.calls, contains('set_goal'));
    expect(client.dailyGoalSteps, 20000);
    expect(find.text('Meta diária: 20000 passos'), findsOneWidget);
  });

  testWidgets('sem meta definida, o anel mostra o total de passos em vez de sumir (regressão)', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-5',
        'cycle_start_at': DateTime.utc(2026, 8, 22).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 23).toIso8601String(),
        'steps_collected': 3200,
        'xp_awarded': 20,
      },
    );
    await _pumpMovementScreen(tester, client);

    expect(find.text('3200'), findsOneWidget);
    expect(find.text('Sem meta'), findsOneWidget);
  });

  testWidgets('gráfico semanal aparece com pelo menos 2 ciclos e destaca o dia recorde', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-today',
        'cycle_start_at': DateTime.utc(2026, 8, 26).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 27).toIso8601String(),
        'steps_collected': 4000,
        'xp_awarded': 20,
      },
      recentCycles: [
        {
          'id': 'cycle-today',
          'cycle_start_at': DateTime.utc(2026, 8, 26).toIso8601String(),
          'cycle_end_at': DateTime.utc(2026, 8, 27).toIso8601String(),
          'steps_collected': 4000,
          'xp_awarded': 20,
        },
        {
          'id': 'cycle-yesterday',
          'cycle_start_at': DateTime.utc(2026, 8, 25).toIso8601String(),
          'cycle_end_at': DateTime.utc(2026, 8, 26).toIso8601String(),
          'steps_collected': 9000,
          'xp_awarded': 60,
        },
      ],
    );
    await _pumpMovementScreen(tester, client);

    expect(find.text('Últimos 7 dias'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('com só 1 coleta no ciclo, gráfico intradiário ainda não aparece', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-6',
        'cycle_start_at': DateTime.utc(2026, 8, 26).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 27).toIso8601String(),
        'steps_collected': 1000,
        'xp_awarded': 0,
        'snapshots': [
          {'recorded_at': DateTime.utc(2026, 8, 26, 6).toIso8601String(), 'steps_total': 1000},
        ],
      },
    );
    await _pumpMovementScreen(tester, client);
    expect(find.text('Seu dia até agora'), findsNothing);
  });

  testWidgets('com 2+ coletas no ciclo, gráfico intradiário aparece', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-7',
        'cycle_start_at': DateTime.utc(2026, 8, 26).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 27).toIso8601String(),
        'steps_collected': 2500,
        'xp_awarded': 0,
        'snapshots': [
          {'recorded_at': DateTime.utc(2026, 8, 26, 6).toIso8601String(), 'steps_total': 1000},
          {'recorded_at': DateTime.utc(2026, 8, 26, 12).toIso8601String(), 'steps_total': 2500},
        ],
      },
    );
    await _pumpMovementScreen(tester, client);
    expect(find.text('Seu dia até agora'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });
}
