import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/services/guest_challenge_service.dart';

/// MENTAL_FLUXO_GUEST_3_QUESTOES_DIAGNOSTICO_TECNICO_V1.md §3.3 — estado
/// local das 3 questões respondidas sem conta, antes do cadastro/login.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('não está dismissed por padrão', () async {
    expect(await GuestChallengeService.isDismissed(), isFalse);
  });

  test('dismiss() persiste e isDismissed() reflete', () async {
    await GuestChallengeService.dismiss();
    expect(await GuestChallengeService.isDismissed(), isTrue);
  });

  test('sem respostas salvas, getAnswers() devolve lista vazia', () async {
    expect(await GuestChallengeService.getAnswers(), isEmpty);
  });

  test('addAnswer() acumula em ordem, preservando xp_preview e is_correct', () async {
    await GuestChallengeService.addAnswer(
      const GuestAnswer(challengeId: 'c1', submittedAnswer: 'x', isCorrect: false, xpPreview: 0, completionToken: 'tok1'),
    );
    await GuestChallengeService.addAnswer(
      const GuestAnswer(challengeId: 'c2', submittedAnswer: 'y', isCorrect: true, xpPreview: 3, completionToken: 'tok2'),
    );

    final answers = await GuestChallengeService.getAnswers();
    expect(answers, hasLength(2));
    expect(answers[0].challengeId, 'c1');
    expect(answers[0].isCorrect, isFalse);
    expect(answers[1].challengeId, 'c2');
    expect(answers[1].isCorrect, isTrue);
    expect(answers[1].xpPreview, 3);
  });

  test('setTerritoryId()/getTerritoryId() round-trip', () async {
    expect(await GuestChallengeService.getTerritoryId(), isNull);
    await GuestChallengeService.setTerritoryId('libras');
    expect(await GuestChallengeService.getTerritoryId(), 'libras');
  });

  test('clearProgress() remove território e respostas, mas não mexe em dismissed', () async {
    await GuestChallengeService.setTerritoryId('libras');
    await GuestChallengeService.addAnswer(
      const GuestAnswer(challengeId: 'c1', submittedAnswer: 'x', isCorrect: true, xpPreview: 3, completionToken: 'tok1'),
    );
    await GuestChallengeService.dismiss();

    await GuestChallengeService.clearProgress();

    expect(await GuestChallengeService.getTerritoryId(), isNull);
    expect(await GuestChallengeService.getAnswers(), isEmpty);
    expect(await GuestChallengeService.isDismissed(), isTrue);
  });

  test('toJson()/fromJson() preservam todos os campos', () {
    const answer = GuestAnswer(challengeId: 'c1', submittedAnswer: 'resposta', isCorrect: true, xpPreview: 5, completionToken: 'tok1');
    final roundTripped = GuestAnswer.fromJson(answer.toJson());
    expect(roundTripped.challengeId, answer.challengeId);
    expect(roundTripped.submittedAnswer, answer.submittedAnswer);
    expect(roundTripped.isCorrect, answer.isCorrect);
    expect(roundTripped.xpPreview, answer.xpPreview);
  });
}
