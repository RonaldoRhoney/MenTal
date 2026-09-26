import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/brasilia_time.dart';
import 'package:mental/services/health_steps_source.dart';
import 'package:mental/widgets/health_connect_card.dart';

/// Movimento/HealthConnect/DESENHO_TECNICO_V1.md (aprovado 25/09/2026): o cartão só
/// EXIBE passos do Health Connect; nada vale XP nem vai ao servidor.
class _FakeSource implements HealthStepsSource {
  _FakeSource(this.current, {this.steps, this.grantsOnRequest = true});

  HealthStepsStatus current;
  int? steps;
  bool grantsOnRequest;
  int requests = 0;

  @override
  Future<HealthStepsStatus> status() async => current;

  @override
  Future<bool> requestPermission() async {
    requests++;
    if (grantsOnRequest) current = HealthStepsStatus.connected;
    return grantsOnRequest;
  }

  @override
  Future<int?> todaySteps() async => steps;
}

Widget _app(HealthStepsSource s) => MaterialApp(home: Scaffold(body: HealthConnectCard(source: s)));

void main() {
  testWidgets('sem Health Connect no aparelho: o cartão não aparece', (tester) async {
    await tester.pumpWidget(_app(_FakeSource(HealthStepsStatus.unavailable)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('health_connect_card')), findsNothing);
  });

  testWidgets('sem permissão: mostra Conectar e só pede a permissão ao toque', (tester) async {
    final source = _FakeSource(HealthStepsStatus.notPermitted, steps: 4321);
    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('health_connect_button')), findsOneWidget);
    expect(source.requests, 0); // consentimento nunca é pedido sozinho

    await tester.tap(find.byKey(const Key('health_connect_button')));
    await tester.pumpAndSettle();
    expect(source.requests, 1);
    expect(find.text('Health Connect: 4321 passos hoje (não geram XP)'), findsOneWidget);
    expect(find.byKey(const Key('health_connect_button')), findsNothing);
  });

  testWidgets('permissão negada: continua oferecendo Conectar', (tester) async {
    final source = _FakeSource(HealthStepsStatus.notPermitted, grantsOnRequest: false);
    await tester.pumpWidget(_app(source));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('health_connect_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('health_connect_button')), findsOneWidget);
  });

  testWidgets('conectado: mostra o total e avisa que não gera XP', (tester) async {
    await tester.pumpWidget(_app(_FakeSource(HealthStepsStatus.connected, steps: 8000)));
    await tester.pumpAndSettle();
    expect(find.text('Health Connect: 8000 passos hoje (não geram XP)'), findsOneWidget);
  });

  testWidgets('conectado sem dado (ou erro de leitura): mensagem honesta, sem número inventado', (tester) async {
    await tester.pumpWidget(_app(_FakeSource(HealthStepsStatus.connected, steps: null)));
    await tester.pumpAndSettle();
    expect(find.text('Health Connect conectado — sem dados de hoje'), findsOneWidget);
  });

  test('brasiliaDayStartUtc: o dia começa 03:00 UTC (00:00 em Brasília)', () {
    expect(brasiliaDayStartUtc(DateTime.utc(2026, 9, 25, 12, 0)), DateTime.utc(2026, 9, 25, 3));
    // 01:00 UTC ainda é o dia anterior em Brasília (22:00 do dia 24).
    expect(brasiliaDayStartUtc(DateTime.utc(2026, 9, 25, 1, 0)), DateTime.utc(2026, 9, 24, 3));
    // 03:00 UTC em ponto = 00:00 do dia 25 em Brasília.
    expect(brasiliaDayStartUtc(DateTime.utc(2026, 9, 25, 3, 0)), DateTime.utc(2026, 9, 25, 3));
  });
}
