import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/admin_feedback_screen.dart';

/// Painel admin de feedback (29/08/2026, pedido de Rhoney: "área para
/// receber os feedbacks... e responder, discutir e interagir com o
/// usuário"). A autorização de verdade é sempre do backend — esta tela
/// só exibe o que a API já filtrou.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  List<Map<String, dynamic>> items = [];
  String? repliedFeedbackId;
  String? repliedText;

  @override
  Future<Map<String, dynamic>> getAdminAppFeedback() async => {'items': items};

  @override
  Future<Map<String, dynamic>> replyAppFeedback(String feedbackId, String reply) async {
    repliedFeedbackId = feedbackId;
    repliedText = reply;
    items = items.map((i) => i['id'] == feedbackId ? {...i, 'admin_reply': reply} : i).toList();
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
      home: AdminFeedbackScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra estado vazio quando não há feedbacks', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    expect(find.text('Nenhum feedback recebido ainda.'), findsOneWidget);
  });

  testWidgets('lista feedbacks com nickname e comentário', (tester) async {
    final client = _FakeApiClient()
      ..items = [
        {'id': '1', 'user_id': 'u1', 'user_nickname': 'Maria', 'comment': 'Ótimo app!', 'created_at': DateTime.now().toIso8601String(), 'admin_reply': null},
      ];
    await _pump(tester, client);

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Ótimo app!'), findsOneWidget);
    expect(find.text('Responder'), findsOneWidget);
  });

  testWidgets('responder um feedback chama a API e atualiza a lista', (tester) async {
    final client = _FakeApiClient()
      ..items = [
        {'id': 'abc', 'user_id': 'u1', 'user_nickname': 'Maria', 'comment': 'Ótimo app!', 'created_at': DateTime.now().toIso8601String(), 'admin_reply': null},
      ];
    await _pump(tester, client);

    await tester.tap(find.text('Responder'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Obrigado pelo feedback!');
    await tester.tap(find.text('Enviar resposta'));
    await tester.pumpAndSettle();

    expect(client.repliedFeedbackId, 'abc');
    expect(client.repliedText, 'Obrigado pelo feedback!');
    expect(find.text('Obrigado pelo feedback!'), findsOneWidget);
    expect(find.text('Editar resposta'), findsOneWidget);
  });
}
