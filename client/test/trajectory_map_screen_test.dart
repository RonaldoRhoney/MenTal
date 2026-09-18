import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/trajectory_map_screen.dart';

/// MAPA_TRAJETORIA_MUNDOS_V1.md — prova que a tela só exibe o que
/// GET /progress/trajectory-map já devolve pronto (nome/%/status/
/// estrelas calculados no SERVIDOR, nunca aqui), no layout espacial
/// (Fase 3: mapa serpenteando, não mais lista) que replica o mockup
/// aprovado por Rhoney.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.nodes = const []}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  List<Map<String, dynamic>> nodes;

  @override
  Future<Map<String, dynamic>> trajectoryMap() async => {'nodes': nodes};
}

Future<void> _pump(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: TrajectoryMapScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista vazia mostra mensagem', (tester) async {
    await _pump(tester, _FakeApiClient());
    expect(find.text('Nenhum Mundo disponível ainda.'), findsOneWidget);
  });

  testWidgets('mostra nome, % e status de um Mundo em andamento exatamente como o backend mandou', (tester) async {
    final client = _FakeApiClient(nodes: [
      {
        'id': 'tecnologia',
        'type': 'world',
        'parent_id': null,
        'name': 'Mundo da Tecnologia',
        'territory_ids': ['tecnologia_fundamentos'],
        'xp_earned': 100,
        'xp_total': 200,
        'percent': 50.0,
        'status': 'in_progress',
        'stars': 1,
      },
    ]);
    await _pump(tester, client);

    expect(find.text('Seu universo'), findsOneWidget);
    expect(find.text('1 de 1 Mundos'), findsOneWidget);
    expect(find.text('Mundo da Tecnologia'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Em andamento'), findsWidgets);
    // Badge de estrela mostra a contagem numérica (1), não ícones soltos.
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('Mundo não iniciado aparece com cadeado, sem porcentagem nem badge de estrela', (tester) async {
    final client = _FakeApiClient(nodes: [
      {
        'id': 'tecnologia',
        'type': 'world',
        'parent_id': null,
        'name': 'Mundo da Tecnologia',
        'territory_ids': ['tecnologia_fundamentos'],
        'xp_earned': 0,
        'xp_total': 200,
        'percent': 0.0,
        'status': 'not_started',
        'stars': 0,
      },
    ]);
    await _pump(tester, client);

    expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    expect(find.text('0%'), findsNothing);
    expect(find.text('Não iniciado'), findsWidgets);
  });

  testWidgets('SubMundo aparece com o rótulo "SubMundo", conquistado sem % e com 3 estrelas', (tester) async {
    final client = _FakeApiClient(nodes: [
      {
        'id': 'tecnologia',
        'type': 'world',
        'parent_id': null,
        'name': 'Mundo da Tecnologia',
        'territory_ids': ['tecnologia_fundamentos'],
        'xp_earned': 0,
        'xp_total': 200,
        'percent': 0.0,
        'status': 'not_started',
        'stars': 0,
      },
      {
        'id': 'tecnologia:internet',
        'type': 'submundo',
        'parent_id': 'tecnologia',
        'name': 'Internet',
        'territory_ids': ['internet_origens'],
        'xp_earned': 200,
        'xp_total': 200,
        'percent': 100.0,
        'status': 'completed',
        'stars': 3,
      },
    ]);
    await _pump(tester, client);

    expect(find.text('SubMundo'), findsOneWidget);
    expect(find.text('Internet'), findsOneWidget);
    expect(find.text('Conquistado'), findsWidgets);
    expect(find.text('3'), findsOneWidget);
  });
}
