import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/age_gate_screen.dart';

/// MENTAL-DIR-001/POL-002 (24/08/2026): MENTAL passa a ser exclusivo
/// pra maiores de 18 anos — confirmação única obrigatória, sem opção
/// de "menor de idade" em lugar nenhum da tela.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  bool confirmMajorityCalled = false;

  @override
  Future<Map<String, dynamic>> confirmMajority() async {
    confirmMajorityCalled = true;
    return {
      'nickname': 'Jogador-teste',
      'age_confirmed_at': DateTime.now().toIso8601String(),
      'terms_version_accepted': '1.0',
    };
  }
}

Future<void> _pumpAgeGateScreen(WidgetTester tester, ApiClient client, VoidCallback onDone) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: AgeGateScreen(client: client, onDone: onDone),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('não existe opção de "menor de 18 anos" em lugar nenhum da tela', (tester) async {
    await _pumpAgeGateScreen(tester, _FakeApiClient(), () {});

    expect(find.textContaining('menos de 18'), findsNothing);
    expect(find.text('Confirmo que tenho 18 anos ou mais.'), findsOneWidget);
  });

  testWidgets('botão Continuar começa desabilitado até marcar a confirmação', (tester) async {
    var done = false;
    await _pumpAgeGateScreen(tester, _FakeApiClient(), () => done = true);

    final continueButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(continueButton.onPressed, isNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(done, isFalse, reason: 'não deveria avançar sem confirmar');
  });

  testWidgets('marcar a confirmação habilita o Continuar e chama confirmMajority', (tester) async {
    final client = _FakeApiClient();
    var done = false;
    await _pumpAgeGateScreen(tester, client, () => done = true);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    final continueButton = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(continueButton.onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(client.confirmMajorityCalled, isTrue);
    expect(done, isTrue);
  });
}
