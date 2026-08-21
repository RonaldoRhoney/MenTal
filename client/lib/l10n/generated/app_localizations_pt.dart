// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get preparingChallenge => 'Preparando seu desafio...';

  @override
  String get ageGateTitle => 'Antes de começar, qual é a sua idade?';

  @override
  String get ageGateSubtitle =>
      'Isso ajuda a manter a experiência adequada para você.';

  @override
  String get ageGateChildOption => 'Tenho menos de 18 anos';

  @override
  String get ageGateAdultOption => 'Tenho 18 anos ou mais';

  @override
  String get homeTitle => 'MENTAL';

  @override
  String progressSummary(int xp, int level, int streak) {
    return 'XP: $xp · Nível $level · Streak: $streak dias';
  }

  @override
  String newChallengeButton(String territory) {
    return 'Novo desafio — $territory';
  }

  @override
  String get territoryPalavras => 'Palavras';

  @override
  String get territoryNumeros => 'Números';

  @override
  String get territoryLogica => 'Lógica';

  @override
  String get territoryConhecimento => 'Conhecimento';

  @override
  String get territoryEnigmas => 'Enigmas';

  @override
  String get dailyLimitReachedMessage =>
      'Você mandou bem hoje! Volte amanhã para mais 24 desafios grátis.';

  @override
  String get territoryLockedMessage => 'Este território exige assinatura.';

  @override
  String get backToHomeButton => 'Voltar para o início';

  @override
  String get tryAgainButton => 'Tentar de novo';

  @override
  String get yourAnswerLabel => 'Sua resposta';

  @override
  String hintPrefix(String hint) {
    return 'Dica: $hint';
  }

  @override
  String get noMoreHintsMessage => 'Sem mais dicas para este desafio.';

  @override
  String get requestHintButton => 'Pedir uma dica';

  @override
  String get confirmAnswerButton => 'Confirmar resposta';

  @override
  String get correctAnswerFeedback => 'Você acertou!';

  @override
  String get incorrectAnswerFeedback => 'Não foi dessa vez.';

  @override
  String correctAnswerLabel(String answer) {
    return 'Resposta correta: $answer';
  }

  @override
  String xpEarnedLabel(int xp, int base, int hints) {
    return 'XP ganho: $xp (base: $base, dicas usadas: $hints)';
  }

  @override
  String get nextChallengeButton => 'Próximo desafio';

  @override
  String get progressTooltip => 'Progresso';

  @override
  String get rankingTooltip => 'Ranking';

  @override
  String get progressScreenTitle => 'Progresso';

  @override
  String levelLabel(int level) {
    return 'Nível $level';
  }

  @override
  String territoryXpLabel(int xp, int threshold) {
    return '$xp / $threshold XP';
  }

  @override
  String get conqueredBadge => 'Conquistado';

  @override
  String get inProgressBadge => 'Em progresso';

  @override
  String get streakSectionTitle => 'Sequência';

  @override
  String streakDaysLabel(int days) {
    return '$days dias seguidos';
  }

  @override
  String get streakFreezeAvailableMessage =>
      'Proteção de sequência disponível esta semana — uma falha não quebra sua sequência.';

  @override
  String get streakFreezeUsedMessage =>
      'Proteção de sequência já usada esta semana.';

  @override
  String get rankingScreenTitle => 'Ranking';

  @override
  String get rankingWindowLabel => 'Ranking da semana';

  @override
  String rankingPositionLabel(int rank) {
    return '#$rank';
  }

  @override
  String get rankingMePrefix => 'Você';

  @override
  String get rankingEmptyMessage =>
      'Ainda não há desafios respondidos esta semana. Jogue para aparecer no ranking!';

  @override
  String get badgesScreenTitle => 'Conquistas';

  @override
  String get viewBadgesButton => 'Ver conquistas';

  @override
  String get badgeEarnedLabel => 'Conquistado';

  @override
  String get badgeLockedLabel => 'Bloqueado';
}
