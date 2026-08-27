import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/profile_screen.dart';
import 'package:mental/theme/app_theme.dart';

/// USER_PROFILE.md — o backend é a única autoridade sobre o que fica
/// salvo (GET/PUT /profile); esta tela só carrega/edita o que já vem
/// pronto.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  Map<String, dynamic> profile = {
    'nickname': 'Lontra-Sabida',
    'avatar_id': null,
    'real_name': null,
    'location_state': null,
    'location_country': null,
    'location_public': false,
  };
  Map<String, dynamic>? lastUpdate;

  @override
  Future<Map<String, dynamic>> getProfile() async => profile;

  @override
  Future<Map<String, dynamic>> updateProfile({
    String? avatarId,
    String? realName,
    String? locationState,
    String? locationCountry,
    required bool locationPublic,
    String? city,
    String? gender,
    String? ageRange,
  }) async {
    lastUpdate = {
      'avatar_id': avatarId,
      'real_name': realName,
      'location_state': locationState,
      'location_country': locationCountry,
      'location_public': locationPublic,
      'city': city,
      'gender': gender,
      'age_range': ageRange,
    };
    profile = {'nickname': 'Lontra-Sabida', ...lastUpdate!};
    return profile;
  }
}

Future<void> _pumpProfileScreen(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ProfileScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('carrega o perfil vazio e mostra os 8 avatares', (tester) async {
    await _pumpProfileScreen(tester, _FakeApiClient());

    expect(find.text('🦉'), findsOneWidget);
    expect(find.text('🦊'), findsOneWidget);
    expect(find.text('🦦'), findsOneWidget);
  });

  testWidgets('escolhe avatar, preenche campos e salva via PUT /profile', (tester) async {
    final client = _FakeApiClient();
    await _pumpProfileScreen(tester, client);

    await tester.tap(find.text('🦊'));
    await tester.pump();

    await tester.enterText(find.widgetWithText(TextField, 'Nome real (opcional)'), 'Fulano de Tal');
    await tester.enterText(find.widgetWithText(TextField, 'Estado'), 'SP');
    await tester.enterText(find.widgetWithText(TextField, 'País'), 'Brasil');
    await tester.tap(find.byType(Switch));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(client.lastUpdate, {
      'avatar_id': 'fox',
      'real_name': 'Fulano de Tal',
      'location_state': 'SP',
      'location_country': 'Brasil',
      'location_public': true,
      'city': null,
      'gender': null,
      'age_range': null,
    });
    expect(find.text('Perfil salvo!'), findsOneWidget);
  });

  testWidgets('nome real nunca some sozinho — helper text sempre visível', (tester) async {
    await _pumpProfileScreen(tester, _FakeApiClient());
    expect(find.textContaining('Nunca aparece publicamente'), findsOneWidget);
  });
}
