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

  // Achado real (01/09/2026): uma falha transitória de rede deixava o
  // aviso "Sem conexão com o servidor" preso na tela pra sempre, mesmo
  // depois de um recarregamento bem-sucedido — simula exatamente isso
  // (falha só na 1ª chamada, sucesso nas seguintes).
  int failStatusCallsRemaining = 0;

  @override
  Future<Map<String, dynamic>> movementStatus() async {
    calls.add('status');
    if (failStatusCallsRemaining > 0) {
      failStatusCallsRemaining--;
      throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Sem conexão com o servidor. Tente novamente.');
    }
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

  Map<String, dynamic>? yearlySummary;

  @override
  Future<Map<String, dynamic>> getMovementYearlySummary({int? year}) async {
    return yearlySummary ?? {'year': year ?? DateTime.now().year, 'months': [], 'total_steps': 0, 'active_days': 0, 'average_steps_per_active_day': 0, 'best_month': null, 'total_xp_awarded': 0};
  }

  @override
  Future<Map<String, dynamic>> getMovementCycle(String cycleId) async {
    return currentCycle ?? {};
  }

  @override
  Future<Map<String, dynamic>> progress() async {
    return {
      'xp_total': 0, 'level': 1, 'xp_per_level': 100, 'territories': [], 'worlds': [], 'blocks': [],
      'streak': {'current_streak': 0, 'freeze_available': false},
    };
  }

  Map<String, dynamic>? dailyChart;
  @override
  Future<Map<String, dynamic>> getMovementDailyChart({String? cycleId}) async {
    return dailyChart ?? {'sessions': []};
  }

  Map<String, dynamic>? monthlyChart;
  @override
  Future<Map<String, dynamic>> getMovementMonthlyChart({int? year, int? month}) async {
    return monthlyChart ?? {'year': year ?? 2026, 'month': month ?? 1, 'days': [], 'total_steps': 0, 'total_xp_awarded': 0, 'active_days': 0, 'average_steps_per_active_day': 0};
  }

  @override
  Future<Map<String, dynamic>> getMovementHistory({String? before, int limit = 20}) async {
    return {'items': [], 'next_cursor': null};
  }
}

Future<void> _pumpMovementScreen(WidgetTester tester, ApiClient client, {Key? key}) async {
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
      home: MovementScreen(key: key, client: client),
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

  testWidgets('erro de rede transitório some depois de um recarregamento bem-sucedido', (tester) async {
    // Achado real (01/09/2026): _load() nunca limpava _error no início —
    // uma falha de rede transitória na 1ª chamada ficava presa na tela
    // pra sempre, mesmo reabrindo a tela depois com a rede normalizada.
    // Reabrir a tela (novo mount, novo initState→_load()) é o caminho
    // real que o usuário tem pra tentar de novo, sem depender do fluxo
    // de permissão do botão "Ativar" (não mockável neste nível de teste).
    final client = _FakeApiClient(movementEnabled: false)..failStatusCallsRemaining = 1;
    await _pumpMovementScreen(tester, client, key: UniqueKey());
    expect(find.text('Sem conexão com o servidor. Tente novamente.'), findsOneWidget);

    // Novo Key força um remount de verdade (novo State, novo
    // initState→_load()) — simula o usuário saindo e reabrindo a tela,
    // que é como ele de fato tentaria de novo na prática.
    await _pumpMovementScreen(tester, client, key: UniqueKey());
    expect(find.text('Sem conexão com o servidor. Tente novamente.'), findsNothing);
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

    expect(find.text('4000'), findsWidgets);
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

    // Sem botão dedicado (29/08/2026, pedido de Rhoney) — o aviso é só
    // informativo, a coleta em si acontece ao tocar num nível de meta
    // atingido no seletor.
    expect(find.textContaining('7000 passos pra coletar'), findsOneWidget);
    expect(find.text('Coletar ciclo anterior'), findsNothing);
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

    expect(find.text('50% da meta'), findsOneWidget);
    expect(find.text('10k'), findsOneWidget);
    expect(find.byType(PieChart), findsWidgets);
  });

  testWidgets('tocar num chip de meta e confirmar com Go chama PUT /movement/goal', (tester) async {
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

    expect(find.text('15k'), findsOneWidget);
    await tester.tap(find.text('15k'));
    await tester.pump();

    // Tocar no chip só marca a seleção pendente — precisa confirmar com
    // "Go" antes de valer pra tela (pedido de Rhoney 29/08/2026: dá o
    // momento explícito de "começar a valer").
    expect(client.calls, isNot(contains('set_goal')));
    await tester.tap(find.text('Ir'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(client.calls, contains('set_goal'));
    expect(client.dailyGoalSteps, 15000);
  });

  testWidgets('digitar meta no último card (editável) e confirmar com Go chama PUT /movement/goal', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-4b',
        'cycle_start_at': DateTime.utc(2026, 8, 22).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 23).toIso8601String(),
        'steps_collected': 0,
        'xp_awarded': 0,
      },
    );
    await _pumpMovementScreen(tester, client);

    // 4º card do seletor é o próprio campo editável (29/08/2026, pedido
    // de Rhoney: "o último card deve ser editável, isso resolve o
    // problema do jogador estabelecer sua própria meta") — quem
    // caminha/corre/treina facilmente passa dos tiers fixos.
    await tester.enterText(find.byType(TextField), '25000');
    await tester.pump();

    await tester.tap(find.text('Ir'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));

    expect(client.calls, contains('set_goal'));
    expect(client.dailyGoalSteps, 25000);
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

    expect(find.text('3200'), findsWidgets);
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

    // MENTAL_ESPECIFICACAO_TECNICA_APROVADA_MOVIMENTO_v2.docx §12/§19 —
    // "resumo na superfície, profundidade sob demanda": o gráfico
    // completo não fica mais na tela principal, só o card "Semana" com
    // média/total; o gráfico só aparece depois de tocar o card.
    expect(find.text('Semana'), findsOneWidget);
    expect(find.byType(BarChart), findsNothing);

    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();

    expect(find.text('Últimos 7 dias'), findsOneWidget);
    expect(find.byType(BarChart), findsOneWidget);
  });

  testWidgets('card Hoje leva à tela unificada de relatórios, aba Dia', (tester) async {
    // MOVIMENTO_GRAFICOS_RICOS_V1.md — as 3 telas de detalhe separadas
    // (Hoje/Semana/Ano) foram substituídas por uma tela só com abas
    // Dia/Semana/Mês/Ano; o card "Hoje" abre direto na aba Dia.
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
    )..dailyChart = {
        'sessions': [
          {'label': 'Madrugada', 'emoji': '🌙', 'start_hour': 0, 'end_hour': 4, 'steps': 0, 'is_peak': false, 'description': 'Nenhum passo registrado ainda hoje.'},
          {'label': 'Início da manhã', 'emoji': '🌅', 'start_hour': 4, 'end_hour': 8, 'steps': 1000, 'is_peak': true, 'description': 'Pico do dia — maior atividade registrada.'},
          {'label': 'Fim da manhã', 'emoji': '☀️', 'start_hour': 8, 'end_hour': 12, 'steps': 0, 'is_peak': false, 'description': 'Sem passos registrados nessa janela.'},
          {'label': 'Início da tarde', 'emoji': '🌤️', 'start_hour': 12, 'end_hour': 16, 'steps': 0, 'is_peak': false, 'description': 'Sem passos registrados nessa janela.'},
          {'label': 'Fim da tarde', 'emoji': '🌇', 'start_hour': 16, 'end_hour': 20, 'steps': 0, 'is_peak': false, 'description': 'Sem passos registrados nessa janela.'},
          {'label': 'Noite', 'emoji': '🌃', 'start_hour': 20, 'end_hour': 24, 'steps': 0, 'is_peak': false, 'description': 'Sem passos registrados nessa janela.'},
        ],
      };
    await _pumpMovementScreen(tester, client);

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Seu dia, sessão a sessão'), findsNothing);

    await tester.tap(find.text('Hoje'));
    await tester.pumpAndSettle();

    expect(find.text('Seu dia, sessão a sessão'), findsOneWidget);
    expect(find.byType(LineChart), findsOneWidget);
  });

  testWidgets('card Ano leva à tela unificada de relatórios, aba Ano', (tester) async {
    final client = _FakeApiClient(
      movementEnabled: true,
      currentCycle: {
        'id': 'cycle-8',
        'cycle_start_at': DateTime.utc(2026, 8, 26).toIso8601String(),
        'cycle_end_at': DateTime.utc(2026, 8, 27).toIso8601String(),
        'steps_collected': 1000,
        'xp_awarded': 0,
      },
    )..yearlySummary = {
        'year': 2026,
        'months': [
          {'month': 8, 'total_steps': 1000, 'active_days': 1, 'is_best': true},
        ],
        'total_steps': 1000,
        'active_days': 1,
        'average_steps_per_active_day': 1000,
        'best_month': 8,
        'total_xp_awarded': 20,
      };
    await _pumpMovementScreen(tester, client);

    expect(find.text('Ano'), findsOneWidget);

    // 3º card, dentro do scroll local da seção — garante que está
    // visível antes de tocar (mesmo achado real que os outros cards
    // acima não precisaram, por estarem mais perto do topo).
    await tester.ensureVisible(find.text('Ano'));
    await tester.tap(find.text('Ano'));
    await tester.pumpAndSettle();

    expect(find.text('Progressão anual'), findsOneWidget);
    expect(find.textContaining('1000'), findsWidgets);
  });
}
