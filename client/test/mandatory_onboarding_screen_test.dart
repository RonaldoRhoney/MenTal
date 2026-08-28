import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/mandatory_onboarding_screen.dart';

/// Cadastro mínimo obrigatório (26/08/2026) — nome, país, cidade, gênero
/// e faixa etária, exigidos antes de liberar o jogo.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  Map<String, dynamic>? lastUpdate;

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? avatarId,
    String? realName,
    String? photoUrl,
    String? locationState,
    String? locationCountry,
    required bool locationPublic,
    String? city,
    String? gender,
    String? ageRange,
  }) async {
    lastUpdate = {
      'real_name': realName,
      'location_country': locationCountry,
      'city': city,
      'gender': gender,
      'age_range': ageRange,
    };
    return {'onboarding_completed_at': DateTime.now().toIso8601String(), ...lastUpdate!};
  }
}

Future<void> _pump(WidgetTester tester, ApiClient client, VoidCallback onDone) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MandatoryOnboardingScreen(client: client, onDone: onDone),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('botão Continuar só habilita com os 5 campos preenchidos', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client, () {});

    await tester.scrollUntilVisible(find.widgetWithText(FilledButton, 'Continuar'), 200, scrollable: find.byType(Scrollable).first);
    FilledButton continueButton() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar'));

    expect(continueButton().onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Maria Silva');
    await tester.enterText(find.widgetWithText(TextField, 'País'), 'Brasil');
    await tester.enterText(find.widgetWithText(TextField, 'Cidade'), 'Belém');
    await tester.pump();
    expect(continueButton().onPressed, isNull, reason: 'ainda faltam gênero e faixa etária');

    await tester.tap(find.text('Feminino'));
    await tester.pump();
    expect(continueButton().onPressed, isNull, reason: 'ainda falta a faixa etária');

    await tester.tap(find.text('26-30'));
    await tester.pump();
    expect(continueButton().onPressed, isNotNull);
  });

  testWidgets('ao continuar, salva os 5 campos e chama onDone', (tester) async {
    final client = _FakeApiClient();
    var doneCalled = false;
    await _pump(tester, client, () => doneCalled = true);

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Maria Silva');
    await tester.enterText(find.widgetWithText(TextField, 'País'), 'Brasil');
    await tester.enterText(find.widgetWithText(TextField, 'Cidade'), 'Belém');
    await tester.tap(find.text('Feminino'));
    await tester.tap(find.text('26-30'));
    await tester.pump();

    await tester.scrollUntilVisible(find.widgetWithText(FilledButton, 'Continuar'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(client.lastUpdate, {
      'real_name': 'Maria Silva',
      'location_country': 'Brasil',
      'city': 'Belém',
      'gender': 'feminino',
      'age_range': '26-30',
    });
    expect(doneCalled, isTrue);
  });
}
