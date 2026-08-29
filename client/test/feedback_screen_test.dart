import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/feedback_screen.dart';

/// Mural de feedback geral (26/08/2026; revisado 29/08/2026, decisão de
/// Rhoney) — PÚBLICO desde a revisão: qualquer usuário vê o feedback de
/// qualquer outro, com reações de curtir/amei. Resposta continua
/// exclusiva de quem tem role=admin.
Map<String, dynamic> _feedItem({
  required String id,
  String nickname = 'Maria',
  String comment = 'Ótimo app!',
  String? adminReply,
  int likeCount = 0,
  int loveCount = 0,
  List<String> myReactions = const [],
}) {
  return {
    'id': id,
    'user_id': 'u-$id',
    'user_nickname': nickname,
    'comment': comment,
    'created_at': DateTime.now().toIso8601String(),
    'admin_reply': adminReply,
    'like_count': likeCount,
    'love_count': loveCount,
    'my_reactions': myReactions,
  };
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.isAdmin = false}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final bool isAdmin;
  String? sentComment;
  List<Map<String, dynamic>> feed = [];
  String? reactedFeedbackId;
  String? reactedType;
  String? repliedFeedbackId;
  String? repliedText;

  @override
  Future<Map<String, dynamic>> submitAppFeedback(String comment) async {
    sentComment = comment;
    feed = [..._feedItemsAfterSubmit(comment), ...feed];
    return {'ok': true};
  }

  List<Map<String, dynamic>> _feedItemsAfterSubmit(String comment) => [_feedItem(id: 'novo', comment: comment)];

  @override
  Future<Map<String, dynamic>> getAppFeedback() async => {'items': feed};

  @override
  Future<Map<String, dynamic>> getProfile() async => {'role': isAdmin ? 'admin' : 'user'};

  @override
  Future<Map<String, dynamic>> reactToAppFeedback(String feedbackId, String reactionType) async {
    reactedFeedbackId = feedbackId;
    reactedType = reactionType;
    return {'reacted': true};
  }

  @override
  Future<Map<String, dynamic>> replyAppFeedback(String feedbackId, String reply) async {
    repliedFeedbackId = feedbackId;
    repliedText = reply;
    feed = feed.map((i) => i['id'] == feedbackId ? {...i, 'admin_reply': reply} : i).toList();
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

  testWidgets('mural mostra feedback de outros usuários com nickname e resposta', (tester) async {
    final client = _FakeApiClient()..feed = [_feedItem(id: '1', nickname: 'Maria', comment: 'O app trava ao marcar a resposta', adminReply: 'Já corrigimos, atualize o app!')];
    await _pump(tester, client);

    expect(find.text('Comentários da comunidade'), findsOneWidget);
    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('O app trava ao marcar a resposta'), findsOneWidget);
    expect(find.text('Já corrigimos, atualize o app!'), findsOneWidget);
  });

  testWidgets('feedback sem resposta não mostra bloco de resposta', (tester) async {
    final client = _FakeApiClient()..feed = [_feedItem(id: '1', comment: 'Sugestão qualquer')];
    await _pump(tester, client);

    expect(find.text('Sugestão qualquer'), findsOneWidget);
    expect(find.text('Resposta da equipe'), findsNothing);
  });

  testWidgets('tocar em curtir chama a API de reação', (tester) async {
    final client = _FakeApiClient()..feed = [_feedItem(id: '1', comment: 'Curte isso')];
    await _pump(tester, client);

    await tester.tap(find.text('👍'));
    await tester.pump();

    expect(client.reactedFeedbackId, '1');
    expect(client.reactedType, 'like');
  });

  testWidgets('contador de reações aparece quando maior que zero', (tester) async {
    final client = _FakeApiClient()..feed = [_feedItem(id: '1', comment: 'Muito curtido', likeCount: 3, loveCount: 1)];
    await _pump(tester, client);

    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('usuário comum não vê botão de responder', (tester) async {
    final client = _FakeApiClient(isAdmin: false)..feed = [_feedItem(id: '1', comment: 'teste')];
    await _pump(tester, client);

    expect(find.text('Responder'), findsNothing);
  });

  testWidgets('admin vê botão de responder e consegue enviar resposta', (tester) async {
    final client = _FakeApiClient(isAdmin: true)..feed = [_feedItem(id: 'abc', comment: 'Precisa de ajuda')];
    await _pump(tester, client);

    expect(find.text('Responder'), findsOneWidget);

    await tester.tap(find.text('Responder'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Já vamos te ajudar!');
    await tester.tap(find.text('Enviar resposta'));
    await tester.pumpAndSettle();

    expect(client.repliedFeedbackId, 'abc');
    expect(client.repliedText, 'Já vamos te ajudar!');
    expect(find.text('Já vamos te ajudar!'), findsOneWidget);
  });
}
