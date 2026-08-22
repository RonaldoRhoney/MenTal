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
  _FakeApiClient({this.addFriendError}) : super(baseUrl: 'http://fake', userId: 'fake-user');

  ApiException? addFriendError;
  List<Map<String, dynamic>> friends = [];
  final List<String> addedCodes = [];

  @override
  Future<Map<String, dynamic>> getInviteCode() async => {'invite_code': 'ABC123'};

  @override
  Future<Map<String, dynamic>> getFriends() async => {'friends': friends};

  @override
  Future<Map<String, dynamic>> addFriend(String inviteCode) async {
    addedCodes.add(inviteCode);
    if (addFriendError != null) throw addFriendError!;
    friends = [
      {'nickname': 'Amigo Novo', 'xp_total': 50, 'level': 1},
    ];
    return {'status': 'ok'};
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
}
