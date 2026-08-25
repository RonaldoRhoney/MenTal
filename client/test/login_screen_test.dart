import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/login_screen.dart';
import 'package:mental/theme/app_theme.dart';

/// Login real via Supabase Auth (SUPABASE_SETUP.md §5). Testa só o que
/// não depende de rede real (validação, alternância de modo) — chamadas
/// de fato a signIn/signUp exigiriam um backend Supabase real.
Future<void> _pumpLoginScreen(WidgetTester tester) async {
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
      home: const LoginScreen(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(url: 'https://fake.supabase.co', publishableKey: 'fake-key');
  });

  testWidgets('BRAND.md §1: nome nunca aparece sem o slogan por perto', (tester) async {
    await _pumpLoginScreen(tester);
    expect(find.text('MENTAL'), findsOneWidget);
    expect(find.text('Mental é quem conquista com a mente.'), findsOneWidget);
  });

  testWidgets('modo padrão é entrar, com link pra alternar pra criar conta', (tester) async {
    await _pumpLoginScreen(tester);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(find.text('Ainda não tem conta? Criar uma'), findsOneWidget);

    await tester.tap(find.text('Ainda não tem conta? Criar uma'));
    await tester.pump();

    expect(find.widgetWithText(FilledButton, 'Criar conta'), findsOneWidget);
    expect(find.text('Já tem conta? Entrar'), findsOneWidget);
  });

  testWidgets('campos vazios mostram erro de validação sem tentar rede', (tester) async {
    await _pumpLoginScreen(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(find.text('Preencha e-mail e senha.'), findsOneWidget);
  });

  testWidgets(
    'Ordem decidida por Rhoney (24/08/2026, pós-DIR-001): Google, depois Facebook, depois email/senha',
    (tester) async {
      await _pumpLoginScreen(tester);

      final googleButton = tester.getRect(find.widgetWithText(ElevatedButton, 'Continuar com Google'));
      final facebookButton = tester.getRect(find.widgetWithText(ElevatedButton, 'Continuar com Facebook'));
      final emailField = tester.getRect(find.widgetWithText(TextField, 'E-mail'));

      expect(googleButton.top, lessThan(facebookButton.top));
      expect(facebookButton.top, lessThan(emailField.top));
    },
  );
}
