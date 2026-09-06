import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/feed_screen.dart';

/// Revisão visual (06/09/2026) trocou o Text simples do card por um
/// RichText (nome em negrito + resto da frase) — find.text não
/// enxerga RichText, então os testes que checam o texto do evento
/// usam este finder por conteúdo combinado (mesmo texto que o backend
/// mandou, só verificando que ele aparece renderizado, sem se importar
/// com a formatação interna dos spans).
Finder _findRichTextContaining(String text) {
  return find.byWidgetPredicate((widget) => widget is RichText && widget.text.toPlainText().contains(text));
}

/// FEED_SOCIAL_V1.md — prova que a tela só exibe o texto/paginação que
/// o backend já devolve prontos (nenhum cálculo de texto no client) e
/// que reagir a um evento reaproveita POST /profile/{id}/torcida.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.pages = const []}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final List<Map<String, dynamic>> pages;
  int getFeedCalls = 0;
  String? lastReactionTargetUserId;
  String? lastReactionType;
  ApiException? torcidaError;

  @override
  Future<Map<String, dynamic>> getFeed({String? before}) async {
    final index = before == null ? 0 : getFeedCalls;
    getFeedCalls += 1;
    return pages[index];
  }

  @override
  Future<Map<String, dynamic>> sendTorcida(String userId, String reactionType) async {
    lastReactionTargetUserId = userId;
    lastReactionType = reactionType;
    if (torcidaError != null) throw torcidaError!;
    return {'ok': true, 'sent_today_by_me': 1};
  }
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
      home: FeedScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('feed vazio mostra estado vazio', (tester) async {
    final client = _FakeApiClient(pages: [
      {'events': [], 'next_cursor': null},
    ]);
    await _pump(tester, client);

    expect(find.text('Nada por aqui ainda. Conquistas de amigos e de quem você segue vão aparecer neste feed.'), findsOneWidget);
  });

  testWidgets('mostra o texto de cada evento pronto do backend, sem reformatar', (tester) async {
    final client = _FakeApiClient(pages: [
      {
        'events': [
          {
            'id': 'evt-1',
            'user_id': 'user-1',
            'nickname': 'joao123',
            'photo_url': null,
            'event_type': 'level_up_milestone',
            'text': 'joao123 chegou ao Nível 20! ⭐',
            'created_at': '2026-09-06T10:00:00',
          },
        ],
        'next_cursor': null,
      },
    ]);
    await _pump(tester, client);

    expect(_findRichTextContaining('joao123 chegou ao Nível 20! ⭐'), findsOneWidget);
  });

  testWidgets('reagir a um evento chama Torcida com o user_id do evento', (tester) async {
    final client = _FakeApiClient(pages: [
      {
        'events': [
          {
            'id': 'evt-1',
            'user_id': 'user-1',
            'nickname': 'joao123',
            'photo_url': null,
            'event_type': 'level_up_milestone',
            'text': 'joao123 chegou ao Nível 20! ⭐',
            'created_at': '2026-09-06T10:00:00',
          },
        ],
        'next_cursor': null,
      },
    ]);
    await _pump(tester, client);

    await tester.tap(find.text('💚'));
    await tester.pumpAndSettle();

    expect(client.lastReactionTargetUserId, 'user-1');
    expect(client.lastReactionType, 'coracao');
    expect(find.text('Torcida enviada!'), findsOneWidget);
  });

  testWidgets('botão carregar mais busca a próxima página com o cursor certo', (tester) async {
    final client = _FakeApiClient(pages: [
      {
        'events': [
          {
            'id': 'evt-1',
            'user_id': 'user-1',
            'nickname': 'joao123',
            'photo_url': null,
            'event_type': 'level_up_milestone',
            'text': 'Primeira página',
            'created_at': '2026-09-06T10:00:00',
          },
        ],
        'next_cursor': '2026-09-06T10:00:00',
      },
      {
        'events': [
          {
            'id': 'evt-2',
            'user_id': 'user-2',
            'nickname': 'maria456',
            'photo_url': null,
            'event_type': 'level_up_milestone',
            'text': 'Segunda página',
            'created_at': '2026-09-05T10:00:00',
          },
        ],
        'next_cursor': null,
      },
    ]);
    await _pump(tester, client);

    expect(_findRichTextContaining('Primeira página'), findsOneWidget);
    expect(_findRichTextContaining('Segunda página'), findsNothing);

    await tester.tap(find.text('Carregar mais'));
    await tester.pumpAndSettle();

    expect(_findRichTextContaining('Primeira página'), findsOneWidget);
    expect(_findRichTextContaining('Segunda página'), findsOneWidget);
    expect(find.text('Carregar mais'), findsNothing);
  });
}
