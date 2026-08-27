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

  @override
  Future<Map<String, dynamic>> submitAppFeedback(String comment) async {
    sentComment = comment;
    return {'ok': true};
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
}
