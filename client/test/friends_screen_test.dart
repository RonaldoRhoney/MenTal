import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/friends_screen.dart';
import 'package:mental/theme/app_theme.dart';

/// V2 item 12 — Amigos. O backend é a autoridade sobre a amizade e
/// sobre a anonimização de nickname para child_safe_mode — esta tela só
/// exibe o que já vem pronto (GET /social/invite-code, GET/POST
/// /social/friends).
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.addFriendError}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  ApiException? addFriendError;
  List<Map<String, dynamic>> friends = [];
  final List<String> addedCodes = [];

  @override
  Future<Map<String, dynamic>> getInviteCode() async => {'invite_code': 'ABC123'};

  @override
  Future<Map<String, dynamic>> getFriends() async => {'friends': friends};

  // Achado de auditoria de segurança (28/08/2026): resgatar o
  // invite_code não cria mais amizade direto, só um pedido pendente.
  List<Map<String, dynamic>> friendRequests = [];
  String? acceptedFriendshipId;
  String? declinedFriendshipId;

  @override
  Future<Map<String, dynamic>> getFriendRequests() async => {'requests': friendRequests};

  @override
  Future<Map<String, dynamic>> acceptFriendRequest(String friendshipId) async {
    acceptedFriendshipId = friendshipId;
    friendRequests = [];
    return {'status': 'accepted'};
  }

  @override
  Future<Map<String, dynamic>> declineFriendRequest(String friendshipId) async {
    declinedFriendshipId = friendshipId;
    friendRequests = [];
    return {'status': 'declined'};
  }

  @override
  Future<Map<String, dynamic>> addFriend(String inviteCode) async {
    addedCodes.add(inviteCode);
    if (addFriendError != null) throw addFriendError!;
    friends = [
      {'user_id': 'friend-user-id', 'nickname': 'Amigo Novo', 'xp_total': 50, 'level': 1},
    ];
    return {'status': 'pending'};
  }

  // Auditoria de conformidade Google Play (29/08/2026, item 6).
  String? blockedUserId;
  String? reportedUserId;
  String? reportReason;

  @override
  Future<Map<String, dynamic>> blockUser(String blockedUserId) async {
    this.blockedUserId = blockedUserId;
    friends = [];
    friendRequests = [];
    return {'status': 'blocked'};
  }

  @override
  Future<Map<String, dynamic>> reportUser({required String reportedUserId, required String reason}) async {
    this.reportedUserId = reportedUserId;
    reportReason = reason;
    return {'status': 'reported'};
  }
}

Future<void> _pumpFriendsScreen(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      // Tema real do app, não o default do Material — achado real
      // (2026-08-22): o bug de "BoxConstraints forces an infinite width"
      // só existe por causa do minimumSize: Size.fromHeight(48) definido
      // em AppTheme pro FilledButton; sem o tema real, o teste passava
      // mesmo com o bug presente.
      theme: AppTheme.themeData,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: FriendsScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra o próprio código de convite e lista de amigos vazia', (tester) async {
    final client = _FakeApiClient();
    await _pumpFriendsScreen(tester, client);

    expect(find.text('Seu código: ABC123'), findsOneWidget);
    expect(find.textContaining('ainda não tem amigos'), findsOneWidget);
  });

  testWidgets('adiciona um amigo via código e atualiza a lista', (tester) async {
    final client = _FakeApiClient();
    await _pumpFriendsScreen(tester, client);

    await tester.enterText(find.byType(TextField), 'XYZ789');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(client.addedCodes, ['XYZ789']);
    expect(find.text('Amigo Novo'), findsOneWidget);
    expect(find.text('50 XP'), findsOneWidget);
  });

  testWidgets('mostra mensagem amigável quando o código não existe', (tester) async {
    final client = _FakeApiClient(
      addFriendError: ApiException(statusCode: 404, code: 'INVITE_NOT_FOUND', message: 'not found'),
    );
    await _pumpFriendsScreen(tester, client);

    await tester.enterText(find.byType(TextField), 'BAD_CODE');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('Código de convite não encontrado.'), findsOneWidget);
  });

  testWidgets('mostra o botão Indicar e não quebra ao tocar', (tester) async {
    final client = _FakeApiClient();
    await _pumpFriendsScreen(tester, client);

    expect(find.text('Indicar'), findsOneWidget);
    // ShareService.share nunca deixa a falha escapar (sem app de
    // compartilhamento no ambiente de teste), mesmo princípio de
    // FeedbackService/PushService.
    await tester.tap(find.text('Indicar'));
    await tester.pump();
  });

  testWidgets('mostra pedidos de amizade pendentes e permite aceitar', (tester) async {
    final client = _FakeApiClient()
      ..friendRequests = [
        {'friendship_id': 'req-1', 'from_user_id': 'someone', 'from_nickname': 'Fulano'},
      ];
    await _pumpFriendsScreen(tester, client);

    expect(find.text('Fulano'), findsOneWidget);
    expect(find.text('Aceitar'), findsOneWidget);
    expect(find.text('Recusar'), findsOneWidget);

    await tester.tap(find.text('Aceitar'));
    await tester.pumpAndSettle();

    expect(client.acceptedFriendshipId, 'req-1');
    expect(find.text('Fulano'), findsNothing);
  });

  testWidgets('permite recusar um pedido de amizade pendente', (tester) async {
    final client = _FakeApiClient()
      ..friendRequests = [
        {'friendship_id': 'req-2', 'from_user_id': 'someone', 'from_nickname': 'Beltrano'},
      ];
    await _pumpFriendsScreen(tester, client);

    await tester.tap(find.text('Recusar'));
    await tester.pumpAndSettle();

    expect(client.declinedFriendshipId, 'req-2');
    expect(find.text('Beltrano'), findsNothing);
  });

  // Auditoria de conformidade Google Play (29/08/2026, item 6) — cada
  // amigo/pedido tem um menu "mais opções" com Denunciar/Bloquear.
  testWidgets('bloquear um amigo chama a API e o remove da lista', (tester) async {
    final client = _FakeApiClient()
      ..friends = [
        {'user_id': 'friend-user-id', 'nickname': 'Amigo Chato', 'xp_total': 10, 'level': 1},
      ];
    await _pumpFriendsScreen(tester, client);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bloquear'));
    await tester.pumpAndSettle();
    // Confirmação do diálogo.
    await tester.tap(find.widgetWithText(FilledButton, 'Bloquear'));
    await tester.pumpAndSettle();

    expect(client.blockedUserId, 'friend-user-id');
    expect(find.text('Amigo Chato'), findsNothing);
  });

  testWidgets('denunciar um amigo chama a API com o motivo digitado', (tester) async {
    final client = _FakeApiClient()
      ..friends = [
        {'user_id': 'friend-user-id', 'nickname': 'Amigo Chato', 'xp_total': 10, 'level': 1},
      ];
    await _pumpFriendsScreen(tester, client);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Denunciar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Comportamento impróprio');
    await tester.tap(find.text('Enviar denúncia'));
    await tester.pumpAndSettle();

    expect(client.reportedUserId, 'friend-user-id');
    expect(client.reportReason, 'Comportamento impróprio');
    // Denunciar não remove o amigo da lista (só bloquear faz isso).
    expect(find.text('Amigo Chato'), findsOneWidget);
  });
}
