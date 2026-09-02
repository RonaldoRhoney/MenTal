import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/challenge_screen.dart';

/// V4 — Detetive Mental (V4/V4_NOVOS_TERRITORIOS.md §4). Prova que a
/// tela revela as pistas em etapas (nunca todas de uma vez, nem o
/// prompt/opções antes da última pista) e que, no modo Relâmpago, o
/// cronômetro só começa depois que a pergunta é revelada.
class _DetectiveFakeApiClient extends ApiClient {
  _DetectiveFakeApiClient({this.timeLimitSeconds}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final int? timeLimitSeconds;

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-detective-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Caso 1: Quem sou eu?',
      'options': ['Elefante', 'Rinoceronte', 'Girafa', 'Hipopótamo'],
      'hints_available': 2,
      'clues': ['Sou o maior animal terrestre vivo hoje.', 'Tenho uma tromba enorme.'],
      'time_limit_seconds': timeLimitSeconds,
    };
  }

  @override
  Future<Map<String, dynamic>> submitAnswer(String challengeId, String attemptId, String submittedAnswer, {int? responseTimeMs, bool timedOut = false}) async {
    return {
      'is_correct': submittedAnswer == 'Elefante',
      'correct_answer': 'Elefante',
      'explanation': 'As duas pistas juntas apontam para o elefante.',
      'xp_awarded': 10,
      'xp_base': 10,
      'hints_used': 0,
      'streak': {'current_streak': 1, 'freeze_available': true},
    };
  }
}

Future<void> _pump(WidgetTester tester, ApiClient client, {bool relampago = false}) async {
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
        client: client,
        territoryId: 'detetive_mental',
        territoryLabel: 'Detetive Mental',
        relampago: relampago,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra só a primeira pista ao carregar, prompt/opções ficam escondidos', (tester) async {
    await _pump(tester, _DetectiveFakeApiClient());

    expect(find.text('Sou o maior animal terrestre vivo hoje.'), findsOneWidget);
    expect(find.text('Tenho uma tromba enorme.'), findsNothing);
    expect(find.text('Caso 1: Quem sou eu?'), findsNothing);
    expect(find.text('Elefante'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Próxima pista'), findsOneWidget);
  });

  testWidgets('"Próxima pista" revela a segunda pista e troca o botão para "Ver pergunta"', (tester) async {
    await _pump(tester, _DetectiveFakeApiClient());

    await tester.tap(find.widgetWithText(FilledButton, 'Próxima pista'));
    await tester.pump();

    expect(find.text('Sou o maior animal terrestre vivo hoje.'), findsOneWidget);
    expect(find.text('Tenho uma tromba enorme.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Próxima pista'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Ver pergunta'), findsOneWidget);
    expect(find.text('Caso 1: Quem sou eu?'), findsNothing);
  });

  testWidgets('"Ver pergunta" revela o prompt e as opções de múltipla escolha', (tester) async {
    await _pump(tester, _DetectiveFakeApiClient());

    await tester.tap(find.widgetWithText(FilledButton, 'Próxima pista'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Ver pergunta'));
    await tester.pump();

    expect(find.text('Caso 1: Quem sou eu?'), findsOneWidget);
    expect(find.widgetWithText(RadioListTile<String>, 'Elefante'), findsOneWidget);
  });

  testWidgets('responder corretamente depois de revelar a pergunta funciona como qualquer MCQ', (tester) async {
    await _pump(tester, _DetectiveFakeApiClient());

    await tester.tap(find.widgetWithText(FilledButton, 'Próxima pista'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Ver pergunta'));
    await tester.pump();

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Elefante'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar resposta'));
    await tester.pumpAndSettle();

    expect(find.textContaining('As duas pistas juntas apontam'), findsOneWidget);
  });

  testWidgets('no modo Relâmpago, o cronômetro NÃO aparece durante as pistas, só depois de "Ver pergunta"', (tester) async {
    await _pump(tester, _DetectiveFakeApiClient(timeLimitSeconds: 20), relampago: true);

    // Ainda na fase de pistas: nenhuma contagem regressiva visível.
    expect(find.textContaining('20s'), findsNothing);
    expect(find.text('Sou o maior animal terrestre vivo hoje.'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Próxima pista'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Ver pergunta'));
    await tester.pump();

    // Só agora, com a pergunta revelada, o cronômetro do Relâmpago aparece.
    expect(find.textContaining('20s'), findsOneWidget);
    expect(find.text('Caso 1: Quem sou eu?'), findsOneWidget);
  });
}
