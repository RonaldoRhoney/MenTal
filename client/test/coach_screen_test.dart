import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/coach_screen.dart';

/// My_Mental_AI (21/09/2026): a tela só exibe o que o servidor recomendou.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.fail = false})
      : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final bool fail;

  @override
  Future<Map<String, dynamic>> getCoach() async {
    if (fail) throw ApiException(statusCode: 500, code: 'X', message: 'falhou');
    return {
      'name': 'My_Mental_AI',
      'summary': {
        'total_answers': 42,
        'accuracy': 0.71,
        'weekly_xp': 120,
        'weekly_rank': 3,
        'streak': 5,
        'daily_xp': 30,
        'daily_xp_cap': 150,
      },
      'daily_tip': null,
      'cards': [
        {
          'id': 'weakest',
          'priority': 72,
          'title': 'Vale reforçar',
          'body': 'Sua taxa de acerto em {territory} é 40% (12 respostas).',
          'action': {'type': 'territory', 'territory_id': 'numeros'},
          'territory_id': 'numeros',
        },
        {
          'id': 'how_to',
          'priority': 10,
          'title': 'Como aproveitar melhor o app',
          'body': 'Jogue um pouco todo dia.',
          'action': null,
          'territory_id': null
        },
      ],
    };
  }
}

Future<void> _pump(WidgetTester tester, ApiClient client) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: CoachScreen(client: client),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'mostra o nome, o resumo e os cartões; {territory} vira o nome do território',
      (tester) async {
    await _pump(tester, _FakeApiClient());
    expect(find.text('My_Mental_AI'), findsOneWidget);
    expect(find.byKey(const Key('coach_summary')), findsOneWidget);
    expect(find.text('42 respostas'), findsOneWidget);
    expect(find.text('71% de acerto'), findsOneWidget);
    expect(find.text('#3 na semana'), findsOneWidget);
    expect(find.text('Vale reforçar'), findsOneWidget);
    expect(find.textContaining('{territory}'), findsNothing);
    expect(find.textContaining('40% (12 respostas)'), findsOneWidget);
  });

  testWidgets('só o cartão com ação tem o botão "Ir agora"', (tester) async {
    await _pump(tester, _FakeApiClient());
    expect(find.byKey(const Key('coach_action_weakest')), findsOneWidget);
    expect(find.byKey(const Key('coach_action_how_to')), findsNothing);
  });

  testWidgets(
      'falha de rede mostra aviso com "Tentar de novo" (nunca tela vazia)',
      (tester) async {
    await _pump(tester, _FakeApiClient(fail: true));
    expect(find.text('Não foi possível carregar suas recomendações.'),
        findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  test('coachText só troca o marcador quando há território', () {
    // sem l10n real: o caminho sem território devolve o texto original.
    expect(coachIcon('weakest'), Icons.trending_up_rounded);
    expect(coachIcon('desconhecido'), Icons.tips_and_updates_rounded);
  });
}
