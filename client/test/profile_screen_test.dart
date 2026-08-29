import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/profile_screen.dart';
import 'package:mental/theme/app_theme.dart';

/// USER_PROFILE.md — o backend é a única autoridade sobre o que fica
/// salvo (GET/PUT /profile); esta tela só carrega/edita o que já vem
/// pronto. Revisão 27/08/2026: avatar emoji removido, upload de foto
/// real + nome real público (ver USER_PROFILE.md §3.1). O fluxo de
/// upload em si (image_picker + Supabase Storage) não é testável aqui —
/// exigiria mockar plataforma nativa/Supabase; cobre-se só o que a tela
/// controla diretamente (campos de texto, botão Salvar, indicador de
/// moderação).
class _FakeApiClient extends ApiClient {
  _FakeApiClient({String? photoModerationStatus})
      : super(baseUrl: 'http://fake', accessToken: 'fake-token') {
    profile = {
      'nickname': 'Lontra-Sabida',
      'real_name': null,
      'photo_url': null,
      'photo_moderation_status': photoModerationStatus ?? 'none',
      'location_state': null,
      'location_country': null,
      'location_public': false,
    };
  }

  late Map<String, dynamic> profile;
  Map<String, dynamic>? lastUpdate;

  @override
  Future<Map<String, dynamic>> getProfile() async => profile;

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
      'location_state': locationState,
      'location_country': locationCountry,
      'location_public': locationPublic,
      'city': city,
      'gender': gender,
      'age_range': ageRange,
    };
    profile = {
      'nickname': 'Lontra-Sabida',
      'photo_moderation_status': profile['photo_moderation_status'],
      ...lastUpdate!,
    };
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
  testWidgets('carrega o perfil vazio e mostra o botão de escolher foto', (tester) async {
    await _pumpProfileScreen(tester, _FakeApiClient());

    expect(find.text('Escolher foto'), findsOneWidget);
    expect(find.text('Foto de perfil'), findsOneWidget);
  });

  testWidgets('preenche nome real e localização e salva via PUT /profile', (tester) async {
    final client = _FakeApiClient();
    await _pumpProfileScreen(tester, client);

    await tester.enterText(find.widgetWithText(TextField, 'Nome real'), 'Fulano de Tal');
    await tester.enterText(find.widgetWithText(TextField, 'Estado'), 'SP');
    await tester.enterText(find.widgetWithText(TextField, 'País'), 'Brasil');
    await tester.tap(find.byType(Switch));
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    expect(client.lastUpdate, {
      'real_name': 'Fulano de Tal',
      'photo_path': null,
      'location_state': 'SP',
      'location_country': 'Brasil',
      'location_public': true,
      'city': null,
      'gender': null,
      'age_range': null,
    });
    expect(find.text('Perfil salvo!'), findsOneWidget);
  });

  testWidgets('nome real agora é anunciado como público — helper text reflete isso', (tester) async {
    await _pumpProfileScreen(tester, _FakeApiClient());
    expect(find.textContaining('Aparece publicamente'), findsOneWidget);
  });

  testWidgets('foto pendente mostra aviso de moderação', (tester) async {
    await _pumpProfileScreen(tester, _FakeApiClient(photoModerationStatus: 'pending'));
    expect(find.textContaining('em análise'), findsOneWidget);
  });

  testWidgets('foto rejeitada mostra aviso pra reenviar', (tester) async {
    await _pumpProfileScreen(tester, _FakeApiClient(photoModerationStatus: 'rejected'));
    expect(find.textContaining('rejeitada'), findsOneWidget);
  });
}
