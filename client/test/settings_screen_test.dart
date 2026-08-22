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
}
