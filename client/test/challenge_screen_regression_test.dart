import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/challenge_screen.dart';

/// Regressão para BUGS_TEST_REPORT_01.md — Bug 1.
///
/// Causa raiz confirmada: o TextField do desafio sem múltipla escolha
/// atualizava `_selectedOption` sem `setState()`, então o botão
/// "Confirmar resposta" (que depende de `_selectedOption != null`)
/// continuava desabilitado na renderização até algum OUTRO evento (ex.:
/// pedir dica) forçar um rebuild. Este teste prova que digitar sozinho,
/// sem nenhuma outra interação, já habilita o botão.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId) async {
    return {
      'challenge_id': 'fake-challenge-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': "Reordene as letras 'SALCA' para formar uma palavra.",
      'options': null,
      'hints_available': 2,
    };
  }
}

void main() {
  testWidgets(
    'botão "Confirmar resposta" habilita ao digitar, sem precisar de outra interação (regressão Bug 1)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _FakeApiClient(),
            territoryId: 'palavras',
            territoryLabel: 'Palavras',
          ),
        ),
      );
      await tester.pumpAndSettle();

      FilledButton confirmButton() =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar resposta'));

      expect(confirmButton().onPressed, isNull, reason: 'antes de digitar, deve estar desabilitado');

      await tester.enterText(find.byType(TextField), 'CASAL');
      await tester.pump();

      expect(
        confirmButton().onPressed,
        isNotNull,
        reason: 'ao digitar, o botão deve habilitar imediatamente — sem precisar de outra ação (ex.: pedir dica)',
      );
    },
  );
}
