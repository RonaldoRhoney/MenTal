import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/challenge_screen.dart';

/// REGRA_REVISAO_ERROS_FIM_RODADA.md — ao errar uma pergunta que também
/// é a última do lote (batch_exhausted), o jogador vê a oferta de
/// revisão antes da tela normal de fim de lote. Aceitar reapresenta a
/// mesma pergunta via GET /challenges/{id}/reattempt (nunca /next);
/// acertar na revisão nunca gera XP.
Map<String, dynamic> _basePayload() => {
      'correct_answer': '4',
      'explanation': '2 + 2 = 4.',
      'xp_base': 10,
      'hints_used': 0,
      'streak': {'current_streak': 1, 'freeze_available': true},
      'level_up': false,
      'new_level': null,
      'territory_just_conquered': false,
      'world_just_completed': false,
      'completed_world_name': null,
      'world_completion_bonus_xp': 0,
      'streak_just_extended': false,
      'newly_awarded_badges': <Map<String, dynamic>>[],
    };

class _RoundReviewFakeApiClient extends ApiClient {
  _RoundReviewFakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  int reattemptCalls = 0;
  String? lastReattemptedChallengeId;

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'q1',
      'attempt_id': 'a1',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Quanto é 2 + 2?',
      'options': ['3', '4', '5', '6'],
      'hints_available': 0,
    };
  }

  @override
  Future<Map<String, dynamic>> submitAnswer(
    String challengeId,
    String attemptId,
    String submittedAnswer, {
    int? responseTimeMs,
    bool timedOut = false,
  }) async {
    if (attemptId == 'a1') {
      // Errou a última pergunta do lote.
      return {
        ..._basePayload(),
        'is_correct': false,
        'xp_awarded': 0,
        'batch_exhausted': true,
      };
    }
    // Resposta durante a revisão (attempt_id vindo de reattemptChallenge).
    return {
      ..._basePayload(),
      'is_correct': submittedAnswer == '4',
      'xp_awarded': 0,
      'batch_exhausted': false,
    };
  }

  @override
  Future<Map<String, dynamic>> reattemptChallenge(String challengeId) async {
    reattemptCalls++;
    lastReattemptedChallengeId = challengeId;
    return {
      'challenge_id': challengeId,
      'attempt_id': 'review-attempt-1',
      'territory_id': 'numeros',
      'difficulty_level': 1,
      'prompt': 'Quanto é 2 + 2?',
      'options': ['3', '4', '5', '6'],
      'hints_available': 0,
    };
  }
}

Future<void> _answerWrongOnLastBatchItem(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChallengeScreen(client: client, territoryId: 'numeros', territoryLabel: 'Números'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(RadioListTile<String>, '3'));
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Confirmar resposta'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('errar a última pergunta do lote oferece revisar, com as duas opções', (tester) async {
    await _answerWrongOnLastBatchItem(tester, _RoundReviewFakeApiClient());

    expect(find.text('Você errou 1 pergunta nesta rodada.'), findsOneWidget);
    expect(find.text('Não, obrigado'), findsOneWidget);
    expect(find.text('Refazer erros'), findsOneWidget);
    // Tela normal de fim de lote NÃO aparece enquanto a oferta está ativa.
    expect(find.text('Você completou todos os desafios disponíveis aqui por agora!'), findsNothing);
  });

  testWidgets('recusar a revisão mostra a tela normal de fim de lote', (tester) async {
    await _answerWrongOnLastBatchItem(tester, _RoundReviewFakeApiClient());

    await tester.tap(find.text('Não, obrigado'));
    await tester.pump();

    expect(find.text('Você completou todos os desafios disponíveis aqui por agora!'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Voltar para o Início'), findsOneWidget);
  });

  testWidgets('aceitar a revisão reapresenta a MESMA pergunta via reattempt, com o selo de revisão', (tester) async {
    final client = _RoundReviewFakeApiClient();
    await _answerWrongOnLastBatchItem(tester, client);

    await tester.tap(find.text('Refazer erros'));
    await tester.pumpAndSettle();

    expect(client.reattemptCalls, 1);
    expect(client.lastReattemptedChallengeId, 'q1');
    expect(find.text('Quanto é 2 + 2?'), findsOneWidget);
    expect(find.text('Modo revisão · sem XP'), findsOneWidget);
  });

  testWidgets('acertar na revisão não gera XP e mostra "Revisão concluída!"', (tester) async {
    final client = _RoundReviewFakeApiClient();
    await _answerWrongOnLastBatchItem(tester, client);
    await tester.tap(find.text('Refazer erros'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(RadioListTile<String>, '4'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar resposta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Revisão concluída!'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Voltar para o Início'), findsOneWidget);
    // xp_awarded=0 no payload — nenhum texto de XP ganho maior que zero.
    expect(find.textContaining('XP ganho: 0'), findsOneWidget);
  });
}
