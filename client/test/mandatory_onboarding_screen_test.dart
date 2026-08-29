import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/mandatory_onboarding_screen.dart';

/// Cadastro mínimo obrigatório (26/08/2026, revisado 28/08/2026) —
/// nome, país, cidade, faixa etária e foto de perfil, exigidos antes de
/// liberar o jogo. Gênero passou a ser OPCIONAL nessa revisão.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  Map<String, dynamic>? lastUpdate;

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? avatarId,
    String? realName,
    String? photoPath,
    String? locationState,
    String? locationCountry,
    required bool locationPublic,
    String? city,
    String? gender,
    String? ageRange,
  }) async {
    lastUpdate = {
      'real_name': realName,
      'photo_path': photoPath,
      'location_country': locationCountry,
      'city': city,
      'gender': gender,
      'age_range': ageRange,
    };
    return {'onboarding_completed_at': DateTime.now().toIso8601String(), ...lastUpdate!};
  }
}

Future<void> _pump(
  WidgetTester tester,
  ApiClient client,
  VoidCallback onDone, {
  Future<String?> Function(BuildContext)? pickAndUploadPhoto,
}) async {
  // Tela virtual bem mais alta que o normal: a lista tem bastante
  // conteúdo (foto + 3 campos + gênero + faixa etária + botão) e não
  // cabe nos 600px padrão de teste — em vez de fazer scroll manual pra
  // cada widget (frágil: um ListView lazy não constrói o que está fora
  // do viewport + cacheExtent, então scrollar pra um widget mais abaixo
  // pode "esconder" um widget mais acima que o teste ainda precisa
  // tocar), aumenta o viewport pra tudo ficar visível de uma vez.
  tester.view.physicalSize = const Size(800, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MandatoryOnboardingScreen(
        client: client,
        onDone: onDone,
        pickAndUploadPhoto: pickAndUploadPhoto ?? (_) async => 'fake-user-id/photo.jpg',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('botão Continuar só habilita com nome, país, cidade, faixa etária e foto', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client, () {});

    FilledButton continueButton() =>
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar'));

    expect(continueButton().onPressed, isNull);

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Maria Silva');
    await tester.enterText(find.widgetWithText(TextField, 'País'), 'Brasil');
    await tester.enterText(find.widgetWithText(TextField, 'Cidade'), 'Belém');
    await tester.pump();
    expect(continueButton().onPressed, isNull, reason: 'ainda faltam faixa etária e foto');

    await tester.tap(find.text('26-35'));
    await tester.pump();
    expect(continueButton().onPressed, isNull, reason: 'ainda falta a foto — gênero é opcional, nunca bloqueia');

    // Escolher foto (fake, sem picker nativo real).
    await tester.tap(find.text('Escolher foto'));
    await tester.pumpAndSettle();
    expect(continueButton().onPressed, isNotNull);
  });

  testWidgets('ao continuar, salva os campos obrigatórios (gênero fica null se não escolhido) e chama onDone', (tester) async {
    final client = _FakeApiClient();
    var doneCalled = false;
    await _pump(tester, client, () => doneCalled = true);

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Maria Silva');
    await tester.enterText(find.widgetWithText(TextField, 'País'), 'Brasil');
    await tester.enterText(find.widgetWithText(TextField, 'Cidade'), 'Belém');
    await tester.tap(find.text('26-35'));
    await tester.tap(find.text('Escolher foto'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(client.lastUpdate, {
      'real_name': 'Maria Silva',
      'photo_path': 'fake-user-id/photo.jpg',
      'location_country': 'Brasil',
      'city': 'Belém',
      'gender': null,
      'age_range': '26-35',
    });
    expect(doneCalled, isTrue);
  });

  testWidgets('escolher gênero é opcional, mas quando escolhido é enviado', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client, () {});

    await tester.enterText(find.widgetWithText(TextField, 'Nome'), 'Maria Silva');
    await tester.enterText(find.widgetWithText(TextField, 'País'), 'Brasil');
    await tester.enterText(find.widgetWithText(TextField, 'Cidade'), 'Belém');
    await tester.tap(find.text('Feminino'));
    await tester.tap(find.text('26-35'));
    await tester.tap(find.text('Escolher foto'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();

    expect(client.lastUpdate!['gender'], 'feminino');
  });
}
