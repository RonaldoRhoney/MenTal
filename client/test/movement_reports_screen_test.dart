import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/movement_reports_screen.dart';

/// MOVIMENTO_GRAFICOS_RICOS_V1.md §7 (revisado 05/09/2026, "dia, semana,
/// mês e ano devem ter seus históricos fiéis") — achado da auditoria de
/// testes: esta tela (substitui as 3 telas antigas de detalhe) não
/// tinha nenhum teste de widget direto. Cobre o essencial: cada aba
/// carrega/mostra o PRÓPRIO histórico (nunca a mesma lista reaproveitada
/// entre abas) e a paginação ("Carregar mais") funciona por período.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final List<String> historyCallsLog = [];

  @override
  Future<Map<String, dynamic>> movementStatus() async {
    return {
      'daily_goal_steps': 10000,
      'current_cycle': {'id': 'cycle-1', 'steps_collected': 4000, 'xp_awarded': 20},
      'recent_cycles': [
        {'steps_collected': 3000, 'xp_awarded': 15, 'cycle_start_at': '2026-09-04T00:00:00'},
        {'steps_collected': 4000, 'xp_awarded': 20, 'cycle_start_at': '2026-09-05T00:00:00'},
      ],
    };
  }

  @override
  Future<Map<String, dynamic>> progress() async {
    return {
      'xp_total': 0, 'level': 1, 'xp_per_level': 100, 'territories': [], 'worlds': [], 'blocks': [],
      'streak': {'current_streak': 5, 'freeze_available': false},
    };
  }

  @override
  Future<Map<String, dynamic>> getMovementDailyChart({String? cycleId}) async {
    return {'sessions': []};
  }

  @override
  Future<Map<String, dynamic>> getMovementMonthlyChart({int? year, int? month}) async {
    return {'year': 2026, 'month': 9, 'days': [], 'total_steps': 0, 'total_xp_awarded': 0, 'active_days': 0, 'average_steps_per_active_day': 0};
  }

  @override
  Future<Map<String, dynamic>> getMovementYearlySummary({int? year}) async {
    return {'year': 2026, 'months': [], 'total_steps': 0, 'active_days': 0, 'average_steps_per_active_day': 0, 'best_month': null, 'total_xp_awarded': 0};
  }

  @override
  Future<Map<String, dynamic>> getMovementHistory({String period = 'day', String? before, int limit = 20}) async {
    historyCallsLog.add('$period:${before ?? "first"}');
    switch (period) {
      case 'day':
        if (before == null) {
          return {
            'items': [
              {'period_number': 2, 'label': '02 de setembro', 'is_current': false, 'steps': 500, 'xp_awarded': 10, 'cumulative_steps': 1500, 'goal_reached': false},
            ],
            'next_cursor': '1',
          };
        }
        return {
          'items': [
            {'period_number': 1, 'label': '01 de setembro', 'is_current': false, 'steps': 1000, 'xp_awarded': 20, 'cumulative_steps': 1000, 'goal_reached': false},
          ],
          'next_cursor': null,
        };
      case 'week':
        return {
          'items': [
            {'period_number': 1, 'label': '31 ago – 06 set', 'is_current': true, 'steps': 3500, 'xp_awarded': 30, 'cumulative_steps': 3500, 'goal_reached': false},
          ],
          'next_cursor': null,
        };
      default:
        return {'items': [], 'next_cursor': null};
    }
  }
}

Future<void> _pumpReportsScreen(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MovementReportsScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('aba Hoje mostra seu próprio histórico (dia a dia)', (tester) async {
    await _pumpReportsScreen(tester, _FakeApiClient());

    expect(find.text('02 de setembro'), findsOneWidget);
    expect(find.text('31 ago – 06 set'), findsNothing);
  });

  testWidgets('trocar pra aba Semana mostra um histórico DIFERENTE (nunca o mesmo do dia)', (tester) async {
    await _pumpReportsScreen(tester, _FakeApiClient());

    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();

    expect(find.text('31 ago – 06 set'), findsOneWidget);
    expect(find.text('02 de setembro'), findsNothing);
  });

  testWidgets('voltar pra aba Hoje depois de visitar Semana mantém o histórico do dia intacto', (tester) async {
    await _pumpReportsScreen(tester, _FakeApiClient());

    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();
    // "Hoje" também aparece como rótulo do dia atual dentro do gráfico
    // de barras da semana — a aba propriamente dita é a primeira
    // ocorrência (topo da tela).
    await tester.tap(find.text('Hoje').first);
    await tester.pumpAndSettle();

    expect(find.text('02 de setembro'), findsOneWidget);
  });

  testWidgets('"Carregar mais" busca a próxima página do MESMO período e acrescenta ao histórico', (tester) async {
    final client = _FakeApiClient();
    await _pumpReportsScreen(tester, client);

    expect(find.text('01 de setembro'), findsNothing);

    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    expect(find.text('02 de setembro'), findsOneWidget);
    expect(find.text('01 de setembro'), findsOneWidget);
    expect(client.historyCallsLog, containsAllInOrder(['day:first', 'day:1']));
  });

  testWidgets('sem mais páginas, botão "Carregar mais" não aparece', (tester) async {
    await _pumpReportsScreen(tester, _FakeApiClient());

    await tester.tap(find.text('Semana'));
    await tester.pumpAndSettle();

    expect(find.text('Carregar mais'), findsNothing);
  });

  testWidgets('abre já na aba pedida via initialPeriod', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MovementReportsScreen(client: _FakeApiClient(), initialPeriod: MovementReportPeriod.week),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('31 ago – 06 set'), findsOneWidget);
    expect(find.text('02 de setembro'), findsNothing);
  });
}
