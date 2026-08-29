import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/settings_screen.dart';

/// V2 item 8 — Notificações. Ao contrário do toggle de som (local), a
/// preferência de notificação vive no backend — este teste prova que a
/// tela carrega o estado real de GET /notifications/preferences e que
/// mudar o toggle chama PUT /notifications/preferences, não só muda
/// estado local.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  Map<String, dynamic> preferences = {'reengagement_enabled': true, 'social_enabled': false};
  final List<Map<String, dynamic>> updateCalls = [];

  // Achado de auditoria de segurança (28/08/2026) — DIR-001 item 5, LGPD.
  ApiException? deleteAccountError;
  int deleteAccountCalls = 0;

  @override
  Future<Map<String, dynamic>> deleteAccount() async {
    deleteAccountCalls++;
    if (deleteAccountError != null) throw deleteAccountError!;
    return {'status': 'deleted'};
  }

  @override
  Future<Map<String, dynamic>> getNotificationPreferences() async => preferences;

  @override
  Future<Map<String, dynamic>> updateNotificationPreferences({
    required bool reengagementEnabled,
    required bool socialEnabled,
  }) async {
    final body = {'reengagement_enabled': reengagementEnabled, 'social_enabled': socialEnabled};
    updateCalls.add(body);
    preferences = body;
    return body;
  }
}

void main() {
  testWidgets('SettingsScreen carrega preferências reais do backend e persiste mudança via PUT', (tester) async {
    // Achado real: sem isto, FeedbackService.ensureLoaded() trava para
    // sempre esperando SharedPreferences.getInstance() (o plugin de
    // teste precisa de valores mock explícitos, mesma exigência já
    // documentada em widget_test.dart) — pumpAndSettle() nunca retorna.
    SharedPreferences.setMockInitialValues({});
    final client = _FakeApiClient();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(client: client),
      ),
    );
    await tester.pumpAndSettle();

    // Estado inicial vem do backend fake: reengajamento ligado, social desligado.
    final reengagementSwitch = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Lembretes diários'),
    );
    final socialSwitch = tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Ranking'));
    expect(reengagementSwitch.value, isTrue);
    expect(socialSwitch.value, isFalse);

    // Liga o toggle de ranking — deve chamar PUT com os dois valores.
    await tester.tap(find.widgetWithText(SwitchListTile, 'Ranking'));
    await tester.pump();

    expect(client.updateCalls, hasLength(1));
    expect(client.updateCalls.single, {'reengagement_enabled': true, 'social_enabled': true});
  });

  testWidgets('"Sair" esvazia a pilha de navegação, revelando a tela por baixo (regressão)', (tester) async {
    // Achado real (2026-08-26): SettingsScreen chega via Navigator.push
    // a partir da Home — sem esvaziar a pilha antes do signOut, ela (ou
    // qualquer outra tela empilhada) continuava visível por cima mesmo
    // depois da sessão cair, escondendo a transição automática pro
    // Login que main.dart (authStateChanges) já faz na raiz.
    SharedPreferences.setMockInitialValues({});
    final client = _FakeApiClient();
    var signOutCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      client: client,
                      signOut: () async => signOutCalled = true,
                    ),
                  ),
                ),
                child: const Text('abrir configurações'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('abrir configurações'));
    await tester.pumpAndSettle();
    expect(find.text('Sair'), findsOneWidget);

    await tester.tap(find.text('Sair'));
    await tester.pumpAndSettle();

    expect(signOutCalled, isTrue);

    expect(find.text('abrir configurações'), findsOneWidget, reason: 'a pilha deve voltar pra raiz, revelando a tela de baixo');
    expect(find.text('Sair'), findsNothing);
  });

  // Empilha SettingsScreen sobre uma tela-raiz de mentira, igual ao
  // fluxo real (chega via Navigator.push a partir da Home) — achado
  // real ao escrever o teste de exclusão de conta: com SettingsScreen
  // diretamente como `home:`, popUntil(isFirst) não navega pra lugar
  // nenhum (já é a raiz), o widget nunca desmonta, e o
  // CircularProgressIndicator do botão de exclusão continua girando
  // pra sempre — pumpAndSettle() nunca retorna. Mesmo princípio já
  // documentado no teste de "Sair" logo acima.
  Future<void> pumpSettingsScreenPushed(WidgetTester tester, ApiClient client, {Future<void> Function()? signOut}) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(client: client, signOut: signOut ?? () async {}),
                  ),
                ),
                child: const Text('abrir configurações'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir configurações'));
    await tester.pumpAndSettle();
  }

  testWidgets('excluir conta pede confirmação e, ao confirmar, chama a API e encerra a sessão', (tester) async {
    final client = _FakeApiClient();
    var signOutCalled = false;
    await pumpSettingsScreenPushed(tester, client, signOut: () async => signOutCalled = true);

    await tester.scrollUntilVisible(find.text('Excluir minha conta'), 100);
    await tester.ensureVisible(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();

    // Diálogo de confirmação aparece — ainda não chamou a API.
    expect(find.text('Excluir sua conta?'), findsOneWidget);
    expect(client.deleteAccountCalls, 0);

    await tester.tap(find.text('Excluir permanentemente'));
    await tester.pumpAndSettle();

    expect(client.deleteAccountCalls, 1);
    expect(signOutCalled, isTrue);
  });

  testWidgets('cancelar o diálogo de exclusão não chama a API', (tester) async {
    final client = _FakeApiClient();
    await pumpSettingsScreenPushed(tester, client);

    await tester.scrollUntilVisible(find.text('Excluir minha conta'), 100);
    await tester.ensureVisible(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(client.deleteAccountCalls, 0);
    expect(find.text('Excluir sua conta?'), findsNothing);
  });

  testWidgets('exclusão indisponível mostra mensagem amigável, sem travar a tela', (tester) async {
    final client = _FakeApiClient()
      ..deleteAccountError = ApiException(statusCode: 501, code: 'ACCOUNT_DELETION_UNAVAILABLE', message: 'unavailable');
    await pumpSettingsScreenPushed(tester, client);

    await tester.scrollUntilVisible(find.text('Excluir minha conta'), 100);
    await tester.ensureVisible(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir minha conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir permanentemente'));
    await tester.pumpAndSettle();

    expect(find.textContaining('indisponível'), findsOneWidget);
    // A tela continua utilizável — o botão volta a ficar habilitado.
    expect(find.widgetWithText(OutlinedButton, 'Excluir minha conta'), findsOneWidget);
  });
}
