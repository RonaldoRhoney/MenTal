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
  List<Map<String, dynamic>> replies = const [],
}) {
  return {
    'id': id,
    'user_id': 'u-$id',
    'user_nickname': nickname,
    'comment': comment,
    'created_at': DateTime.now().toUtc().toIso8601String(),
    'admin_reply': adminReply,
    'like_count': likeCount,
    'love_count': loveCount,
    'my_reactions': myReactions,
    'replies': replies,
  };
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.isAdmin = false})
      : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final bool isAdmin;
  bool failFeed = false;
  String? repliedToFeedbackId;
  String? userReplyText;
  String? deletedReplyId;
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

  List<Map<String, dynamic>> _feedItemsAfterSubmit(String comment) =>
      [_feedItem(id: 'novo', comment: comment)];

  @override
  Future<Map<String, dynamic>> getAppFeedback() async {
    if (failFeed)
      throw ApiException(statusCode: 500, code: 'X', message: 'falhou');
    return {'items': feed};
  }

  @override
  Future<Map<String, dynamic>> replyToFeedback(
      String feedbackId, String comment) async {
    repliedToFeedbackId = feedbackId;
    userReplyText = comment;
    return {'id': 'r-new'};
  }

  @override
  Future<Map<String, dynamic>> deleteFeedbackReply(String replyId) async {
    deletedReplyId = replyId;
    return {'ok': true};
  }

  @override
  Future<Map<String, dynamic>> getProfile() async =>
      {'role': isAdmin ? 'admin' : 'user'};

  @override
  Future<Map<String, dynamic>> reactToAppFeedback(
      String feedbackId, String reactionType) async {
    reactedFeedbackId = feedbackId;
    reactedType = reactionType;
    return {'reacted': true};
  }

  @override
  Future<Map<String, dynamic>> replyAppFeedback(
      String feedbackId, String reply) async {
    repliedFeedbackId = feedbackId;
    repliedText = reply;
    feed = feed
        .map((i) => i['id'] == feedbackId ? {...i, 'admin_reply': reply} : i)
        .toList();
    return {'ok': true};
  }
}

Future<void> _pump(WidgetTester tester, ApiClient client) async {
  // Tela alta: o compositor ocupa espaço e a lista é preguiçosa.
  tester.view.physicalSize = const Size(800, 3000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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
  Map<String, dynamic> reply(
          {String id = 'r1',
          String name = 'João',
          String text = 'Concordo!',
          bool mine = false}) =>
      {
        'id': id,
        'user_id': 'u-$id',
        'user_nickname': name,
        'user_real_name': null,
        'comment': text,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'is_mine': mine,
      };

  testWidgets(
      'Mural aberto: qualquer usuário (não só admin) vê o botão Responder e envia resposta',
      (tester) async {
    final client = _FakeApiClient()
      ..feed = [_feedItem(id: 'a', nickname: 'Maria', comment: 'Ótimo app')];
    await _pump(tester, client);

    expect(find.text('Responder pela equipe'),
        findsNothing); // botão oficial segue só do admin
    await tester.tap(find.byKey(const Key('reply_toggle_a')));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byKey(const Key('reply_field_a')), 'Também acho!');
    await tester.pump();
    await tester.tap(find.byKey(const Key('reply_send_a')));
    await tester.pumpAndSettle();

    expect(client.repliedToFeedbackId, 'a');
    expect(client.userReplyText, 'Também acho!');
  });

  testWidgets('respostas dos usuários aparecem no comentário, com contagem',
      (tester) async {
    final client = _FakeApiClient()
      ..feed = [
        _feedItem(id: 'a', nickname: 'Maria', comment: 'Ótimo app', replies: [
          reply(id: 'r1', name: 'João', text: 'Concordo!'),
          reply(id: 'r2', name: 'Ana', text: 'Eu também')
        ])
      ];
    await _pump(tester, client);
    expect(find.text('Concordo!'), findsOneWidget);
    expect(find.text('Eu também'), findsOneWidget);
    expect(find.text('2 respostas'), findsOneWidget);
  });

  testWidgets(
      'só a própria resposta tem botão de apagar (admin apaga qualquer uma)',
      (tester) async {
    final feed = [
      _feedItem(id: 'a', nickname: 'Maria', comment: 'Ótimo app', replies: [
        reply(id: 'minha', mine: true),
        reply(id: 'alheia', name: 'Ana', text: 'oi')
      ])
    ];
    final client = _FakeApiClient()..feed = feed;
    await _pump(tester, client);
    expect(find.byKey(const Key('reply_delete_minha')), findsOneWidget);
    expect(find.byKey(const Key('reply_delete_alheia')), findsNothing);

    await tester.tap(find.byKey(const Key('reply_delete_minha')));
    await tester.pumpAndSettle();
    expect(client.deletedReplyId, 'minha');

    final admin = _FakeApiClient(isAdmin: true)..feed = feed;
    await tester.pumpWidget(const SizedBox());
    await _pump(tester, admin);
    expect(find.byKey(const Key('reply_delete_alheia')), findsOneWidget);
  });

  testWidgets(
      'Design profissional: compositor em cartão, contador e contagem de comentários',
      (tester) async {
    final client = _FakeApiClient()
      ..feed = [
        _feedItem(id: 'a', nickname: 'Maria', comment: 'Ótimo!'),
        _feedItem(id: 'b', nickname: 'João', comment: 'Bom')
      ];
    await _pump(tester, client);

    expect(find.text('Sua opinião'), findsOneWidget);
    expect(find.text('0/2000'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Olá');
    await tester.pump();
    expect(find.text('3/2000'), findsOneWidget);
    expect(find.text('2 comentários'), findsOneWidget);
    // avatar com a inicial do autor
    expect(find.text('M'), findsOneWidget);
    expect(find.text('agora mesmo'), findsWidgets);
  });

  testWidgets('mural vazio mostra estado vazio (sem quebrar o compositor)',
      (tester) async {
    await _pump(tester, _FakeApiClient());
    expect(find.byKey(const Key('feedback_empty')), findsOneWidget);
    expect(find.text('Sua opinião'), findsOneWidget);
  });

  testWidgets(
      'falha ao carregar o mural mostra aviso com "Tentar de novo" e recarrega',
      (tester) async {
    final client = _FakeApiClient()..failFeed = true;
    await _pump(tester, client);
    expect(find.byKey(const Key('feedback_load_error')), findsOneWidget);

    client
      ..failFeed = false
      ..feed = [_feedItem(id: 'a', nickname: 'Maria', comment: 'Voltou')];
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();
    expect(find.text('Voltou'), findsOneWidget);
    expect(find.byKey(const Key('feedback_load_error')), findsNothing);
  });

  testWidgets('botão Enviar começa desabilitado até digitar algo',
      (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    FilledButton sendButton() => tester
        .widget<FilledButton>(find.widgetWithText(FilledButton, 'Enviar'));
    expect(sendButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Adorei o app!');
    await tester.pump();
    expect(sendButton().onPressed, isNotNull);
  });

  testWidgets('enviar chama a API e mostra confirmação', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    await tester.enterText(
        find.byType(TextField), 'Sugestão: mais territórios!');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Enviar'));
    await tester.pump();

    expect(client.sentComment, 'Sugestão: mais territórios!');
    expect(find.textContaining('Feedback enviado'), findsOneWidget);
  });

  testWidgets(
      'mural mostra feedback de outros usuários com nickname e resposta',
      (tester) async {
    final client = _FakeApiClient()
      ..feed = [
        _feedItem(
            id: '1',
            nickname: 'Maria',
            comment: 'O app trava ao marcar a resposta',
            adminReply: 'Já corrigimos, atualize o app!')
      ];
    await _pump(tester, client);

    expect(find.text('Comentários da comunidade'), findsOneWidget);
    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('O app trava ao marcar a resposta'), findsOneWidget);
    expect(find.text('Já corrigimos, atualize o app!'), findsOneWidget);
  });

  testWidgets('feedback sem resposta não mostra bloco de resposta',
      (tester) async {
    final client = _FakeApiClient()
      ..feed = [_feedItem(id: '1', comment: 'Sugestão qualquer')];
    await _pump(tester, client);

    expect(find.text('Sugestão qualquer'), findsOneWidget);
    expect(find.text('Resposta da equipe'), findsNothing);
  });

  testWidgets('tocar em curtir chama a API de reação', (tester) async {
    final client = _FakeApiClient()
      ..feed = [_feedItem(id: '1', comment: 'Curte isso')];
    await _pump(tester, client);

    await tester.tap(find.text('👍'));
    await tester.pump();

    expect(client.reactedFeedbackId, '1');
    expect(client.reactedType, 'like');
  });

  testWidgets('contador de reações aparece quando maior que zero',
      (tester) async {
    final client = _FakeApiClient()
      ..feed = [
        _feedItem(id: '1', comment: 'Muito curtido', likeCount: 3, loveCount: 1)
      ];
    await _pump(tester, client);

    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('usuário comum não vê botão de responder', (tester) async {
    final client = _FakeApiClient(isAdmin: false)
      ..feed = [_feedItem(id: '1', comment: 'teste')];
    await _pump(tester, client);

    expect(find.text('Responder pela equipe'), findsNothing);
  });

  testWidgets('admin vê botão de responder e consegue enviar resposta',
      (tester) async {
    final client = _FakeApiClient(isAdmin: true)
      ..feed = [_feedItem(id: 'abc', comment: 'Precisa de ajuda')];
    await _pump(tester, client);

    expect(find.text('Responder pela equipe'), findsOneWidget);

    await tester.tap(find.text('Responder pela equipe'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Já vamos te ajudar!');
    await tester.tap(find.text('Enviar resposta'));
    await tester.pumpAndSettle();

    expect(client.repliedFeedbackId, 'abc');
    expect(client.repliedText, 'Já vamos te ajudar!');
    expect(find.text('Já vamos te ajudar!'), findsOneWidget);
  });
}
