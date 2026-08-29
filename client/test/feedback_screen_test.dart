import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/feedback_screen.dart';

/// Menu de feedback geral (26/08/2026) — comentário livre, sem gatilho
/// além do usuário querer comentar (diferente do Feedback Pós-Nível).
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  String? sentComment;
  List<Map<String, dynamic>> myFeedback = [];

  @override
  Future<Map<String, dynamic>> submitAppFeedback(String comment) async {
    sentComment = comment;
    myFeedback = [...myFeedback, {'id': 'novo', 'comment': comment, 'created_at': DateTime.now().toIso8601String(), 'admin_reply': null}];
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> getMyAppFeedback() async => {'items': myFeedback};
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
      home: FeedbackScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('botão Enviar começa desabilitado até digitar algo', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    FilledButton sendButton() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Enviar'));
    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Adorei o app!');
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);
  });

  testWidgets('enviar chama a API e mostra confirmação', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    await tester.enterText(find.byType(TextField), 'Sugestão: mais territórios!');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pump();

    expect(client.sentComment, 'Sugestão: mais territórios!');
    expect(find.textContaining('Feedback enviado'), findsOneWidget);
  });

  testWidgets('mostra resposta da equipe num feedback já respondido', (tester) async {
    final client = _FakeApiClient()
      ..myFeedback = [
        {'id': '1', 'comment': 'O app trava ao marcar a resposta', 'created_at': DateTime.now().toIso8601String(), 'admin_reply': 'Já corrigimos, atualize o app!'},
      ];
    await _pump(tester, client);

    expect(find.text('Meus feedbacks'), findsOneWidget);
    expect(find.text('O app trava ao marcar a resposta'), findsOneWidget);
    expect(find.text('Já corrigimos, atualize o app!'), findsOneWidget);
  });

  testWidgets('feedback sem resposta não mostra bloco de resposta', (tester) async {
    final client = _FakeApiClient()
      ..myFeedback = [
        {'id': '1', 'comment': 'Sugestão qualquer', 'created_at': DateTime.now().toIso8601String(), 'admin_reply': null},
      ];
    await _pump(tester, client);

    expect(find.text('Sugestão qualquer'), findsOneWidget);
    expect(find.text('Resposta da equipe'), findsNothing);
  });
}
