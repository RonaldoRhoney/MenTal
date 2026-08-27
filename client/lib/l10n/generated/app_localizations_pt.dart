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
  String get ageGateTitle =>
      'Este aplicativo é destinado a maiores de 18 anos.';

  @override
  String get ageGateSubtitle =>
      'Confirme que você tem 18 anos ou mais para continuar.';

  @override
  String get ageGateCheckboxLabel => 'Confirmo que tenho 18 anos ou mais.';

  @override
  String get ageGateTermsLinkPrefix => 'Ao continuar, você concorda com os ';

  @override
  String get ageGateTermsLinkText =>
      'Termos de Uso e a Política de Privacidade';

  @override
  String get ageGateContinueButton => 'Continuar';

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
  String get territoryTextos => 'Textos';

  @override
  String get territoryVisual => 'Visual';

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
  String get levelFeedbackHeading => 'Como foi esse nível?';

  @override
  String get levelFeedbackRepeatAction => 'Repetir este nível';

  @override
  String get levelFeedbackContinueAction => 'Seguir em frente';

  @override
  String get levelFeedbackDifficultyFacil => 'Fácil';

  @override
  String get levelFeedbackDifficultyMedio => 'Médio';

  @override
  String get levelFeedbackDifficultyDificil => 'Difícil';

  @override
  String get levelFeedbackDifficultyMuitoDificil => 'Muito difícil';

  @override
  String get levelFeedbackCommentHint => 'Comentário (opcional)';

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

  @override
  String get settingsTooltip => 'Configurações';

  @override
  String get settingsScreenTitle => 'Configurações';

  @override
  String get soundSectionTitle => 'Som';

  @override
  String get soundToggleLabel => 'Efeitos sonoros';

  @override
  String get soundVolumeLabel => 'Volume dos efeitos';

  @override
  String get soundSilencedNote =>
      'O som não toca enquanto o aparelho estiver no modo silencioso ou vibrar.';

  @override
  String levelUpMessage(int level) {
    return 'Nível $level alcançado!';
  }

  @override
  String get territoryConqueredCelebrationMessage => 'Território conquistado!';

  @override
  String worldCompletedCelebrationMessage(String world, int xp) {
    return '$world completo! +$xp XP de bônus';
  }

  @override
  String badgeUnlockedCelebrationMessage(String badgeName) {
    return 'Nova conquista: $badgeName!';
  }

  @override
  String streakExtendedCelebrationMessage(int days) {
    return 'Sequência de $days dias mantida!';
  }

  @override
  String get statsTooltip => 'Estatísticas';

  @override
  String get statsScreenTitle => 'Estatísticas';

  @override
  String get viewStatsButton => 'Ver estatísticas';

  @override
  String get statsOverviewSectionTitle => 'Visão geral';

  @override
  String get statsTotalAttemptsLabel => 'Desafios respondidos';

  @override
  String get statsAccuracyLabel => 'Acerto geral';

  @override
  String get statsHintFreeCorrectLabel => 'Acertos sem dica';

  @override
  String get statsHintsUsedLabel => 'Dicas usadas';

  @override
  String get statsCorrectWithHintLegend => 'Acertos com dica';

  @override
  String get statsIncorrectLegend => 'Erros';

  @override
  String get statsStreakLabel => 'Sequência atual / mais longa';

  @override
  String statsStreakValue(int current, int longest) {
    return '$current / $longest dias';
  }

  @override
  String get statsBadgesLabel => 'Conquistas desbloqueadas';

  @override
  String statsBadgesValue(int earned, int total) {
    return '$earned / $total';
  }

  @override
  String get statsByTerritorySectionTitle => 'Desempenho por território';

  @override
  String statsTerritoryAttemptsAndAccuracy(int attempts, String accuracy) {
    return '$attempts respondidos · $accuracy de acerto';
  }

  @override
  String statsTerritoryDifficultyLabel(int level) {
    return 'Nível de dificuldade atual: $level';
  }

  @override
  String get statsNoAttemptsYet =>
      'Ainda sem desafios respondidos neste território.';

  @override
  String get notificationsSectionTitle => 'Notificações';

  @override
  String get notifReengagementLabel => 'Lembretes diários';

  @override
  String get notifReengagementDescription => 'Após 24h e 48h sem abrir o app';

  @override
  String get notifSocialLabel => 'Ranking';

  @override
  String get notifSocialDescription => 'Quando alguém avança no seu ranking';

  @override
  String get movementTooltip => 'Movimento';

  @override
  String get movementScreenTitle => 'Movimento';

  @override
  String get movementIntro =>
      'Jogar não precisa ser só ficar parado. Ative o contador de passos e transforme sua caminhada em pontos — sem esforço extra.';

  @override
  String get movementEnableButton => 'Ativar contador de passos';

  @override
  String get movementDisableButton => 'Desativar';

  @override
  String get movementPermissionDeniedMessage =>
      'Sem permissão de atividade física, o contador de passos fica indisponível. Você pode conceder depois, nas configurações do aparelho.';

  @override
  String get movementSensorUnavailableMessage =>
      'Não foi possível ler o sensor de passos agora.';

  @override
  String movementCurrentCycleLabel(int steps) {
    return 'Passos coletados neste ciclo: $steps';
  }

  @override
  String movementDetectedStepsLabel(int steps) {
    return '$steps passos detectados agora, ainda não coletados';
  }

  @override
  String get movementCollectButton => 'Coletar passos';

  @override
  String get movementNoStepsToCollect => 'Nenhum passo novo pra coletar agora.';

  @override
  String movementPendingReportLabel(int steps) {
    return 'Você ainda tem um ciclo anterior com $steps passos pra coletar!';
  }

  @override
  String get movementCollectPreviousButton => 'Coletar ciclo anterior';

  @override
  String movementXpCollectedFeedback(int xp) {
    return '+$xp XP dos seus passos!';
  }

  @override
  String movementGoalLabel(int goal) {
    return 'Meta diária: $goal passos';
  }

  @override
  String get movementNoGoalLabel => 'Nenhuma meta diária definida';

  @override
  String get movementSetGoalButton => 'Definir meta diária';

  @override
  String get movementEditGoalButton => 'Editar meta';

  @override
  String get movementGoalDialogTitle => 'Sua meta diária de passos';

  @override
  String get movementGoalDialogHint => 'Ex.: 20000';

  @override
  String get movementGoalSaveButton => 'Salvar';

  @override
  String get movementGoalCancelButton => 'Cancelar';

  @override
  String movementGoalReachedMessage(int xp) {
    return 'Meta batida! +$xp XP extra por superar seu próprio objetivo 🎉';
  }

  @override
  String movementGoalProgressLabel(int percent) {
    return '$percent% da meta';
  }

  @override
  String get movementNoGoalProgressLabel => 'Sem meta';

  @override
  String get movementWeeklyChartTitle => 'Últimos 7 dias';

  @override
  String get movementWeeklyChartSubtitle =>
      'Passos coletados por dia — veja em quais você caminhou mais.';

  @override
  String get movementTodayChartTitle => 'Seu dia até agora';

  @override
  String get movementTodayChartSubtitle =>
      'Como seus passos foram acumulando ao longo do ciclo.';

  @override
  String movementCheckpointReachedMessage(int count, int xp) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count checkpoints do dia batidos! +$xp XP extra 🚶',
      one: 'Checkpoint do dia batido! +$xp XP extra 🚶',
    );
    return '$_temp0';
  }

  @override
  String get friendsTooltip => 'Amigos';

  @override
  String get friendsScreenTitle => 'Amigos';

  @override
  String friendsInviteCodeLabel(String code) {
    return 'Seu código: $code';
  }

  @override
  String get friendsCopyCodeButton => 'Copiar código';

  @override
  String get friendsCodeCopiedMessage => 'Código copiado!';

  @override
  String get friendsAddFieldHint => 'Cole o código de um amigo';

  @override
  String get friendsAddButton => 'Adicionar';

  @override
  String get friendsListTitle => 'Seus amigos';

  @override
  String get friendsEmptyMessage =>
      'Você ainda não tem amigos adicionados. Compartilhe seu código ou cole o código de alguém.';

  @override
  String get friendsInviteNotFoundError => 'Código de convite não encontrado.';

  @override
  String get friendsCannotAddSelfError =>
      'Você não pode adicionar a si mesmo como amigo.';

  @override
  String get rankingScopeGlobal => 'Global';

  @override
  String get rankingScopeFriends => 'Amigos';

  @override
  String get shareButtonLabel => 'Compartilhar';

  @override
  String shareTerritoryConqueredMessage(String territory) {
    return 'Conquistei o território $territory no MENTAL! 🏆';
  }

  @override
  String shareWorldCompletedMessage(String world) {
    return 'Completei o $world no MENTAL! 🎉';
  }

  @override
  String shareLevelUpMessage(int level) {
    return 'Alcancei o Nível $level no MENTAL! 🚀';
  }

  @override
  String shareBadgeUnlockedMessage(String badge) {
    return 'Desbloqueei a conquista \"$badge\" no MENTAL! 🏅';
  }

  @override
  String get shareMovementGoalMessage =>
      'Bati minha meta de passos no MENTAL e ganhei XP de bônus! 🚶💪';

  @override
  String shareXpRewardedMessage(int xp) {
    return '+$xp XP por compartilhar!';
  }

  @override
  String get friendsInviteShareButton => 'Indicar';

  @override
  String friendsInviteShareMessage(String code) {
    return 'Bora treinar a mente comigo? Baixe o MENTAL e use meu código de convite: $code';
  }

  @override
  String relampagoSecondsRemainingLabel(int seconds) {
    return '${seconds}s';
  }

  @override
  String get relampagoTimedOutFeedback => 'Quase lá! Tenta de novo';

  @override
  String relampagoSpeedBonusMessage(int xp) {
    return '+$xp XP de bônus de velocidade! ⚡';
  }

  @override
  String get relampagoModeLabel => '⚡ Relâmpago';

  @override
  String get backButton => 'Voltar';

  @override
  String get battlesTooltip => 'Batalhas';

  @override
  String get battlesScreenTitle => 'Batalhas';

  @override
  String get battleChallengeButton => 'Desafiar';

  @override
  String battleDialogTitle(String nickname) {
    return 'Desafiar $nickname';
  }

  @override
  String get battleDialogTerritoryLabel => 'Território';

  @override
  String get battleDialogDifficultyLabel => 'Nível de dificuldade';

  @override
  String get battleDialogSendButton => 'Enviar desafio';

  @override
  String get battleDailyLimitReachedMessage =>
      'Você já enviou o máximo de desafios hoje. Volte amanhã!';

  @override
  String get battlesEmptyMessage =>
      'Nenhuma batalha ainda. Desafie um amigo na tela de Amigos!';

  @override
  String get battleStatusPendingWaitingMe => 'Sua vez de responder';

  @override
  String battleStatusPendingWaitingOpponent(String nickname) {
    return 'Aguardando $nickname responder';
  }

  @override
  String battleStatusWon(int xp) {
    return 'Você venceu! +$xp XP';
  }

  @override
  String battleStatusLost(String nickname) {
    return '$nickname levou essa';
  }

  @override
  String get battleStatusTie => 'Empate — os dois erraram';

  @override
  String get battleAnswerButton => 'Responder';

  @override
  String territoryDetentorGainedMessage(String territory) {
    return 'Você assumiu $territory entre seus amigos! 🏰';
  }

  @override
  String territoryDetentorLabel(String nickname) {
    return 'Detentor: $nickname';
  }

  @override
  String get territoryDetentorIsMeLabel => 'Você é o detentor';

  @override
  String shareTerritoryDetentorMessage(String territory) {
    return 'Assumi $territory entre meus amigos no MENTAL! 🏰';
  }

  @override
  String get profileTooltip => 'Perfil';

  @override
  String get profileScreenTitle => 'Meu Perfil';

  @override
  String get profileAvatarSectionTitle => 'Avatar';

  @override
  String get profileRealNameLabel => 'Nome real (opcional)';

  @override
  String get profileRealNameHelperText =>
      'Nunca aparece publicamente — só uso interno, ex.: suporte. Seu apelido já te identifica no jogo.';

  @override
  String get profileLocationSectionTitle => 'Localização (opcional)';

  @override
  String get profileLocationStateLabel => 'Estado';

  @override
  String get profileLocationCountryLabel => 'País';

  @override
  String get profileLocationPublicLabel => 'Mostrar meu estado/país no perfil';

  @override
  String get profileSaveButton => 'Salvar';

  @override
  String get profileSavedMessage => 'Perfil salvo!';

  @override
  String get loginTitle => 'MENTAL';

  @override
  String get loginSlogan => 'Mental é quem conquista com a mente.';

  @override
  String get loginEmailLabel => 'E-mail';

  @override
  String get loginPasswordLabel => 'Senha';

  @override
  String get loginSignInButton => 'Entrar';

  @override
  String get loginSignUpButton => 'Criar conta';

  @override
  String get loginToggleToSignUp => 'Ainda não tem conta? Criar uma';

  @override
  String get loginToggleToSignIn => 'Já tem conta? Entrar';

  @override
  String get loginCheckEmailMessage =>
      'Conta criada! Confira seu e-mail para confirmar antes de entrar.';

  @override
  String get loginMissingFieldsError => 'Preencha e-mail e senha.';

  @override
  String get settingsSignOutButton => 'Sair';

  @override
  String get loginGoogleButton => 'Continuar com Google';

  @override
  String get loginFacebookButton => 'Continuar com Facebook';

  @override
  String get loginOrDivider => 'ou';

  @override
  String get onboardingTitle => 'Antes de começar';

  @override
  String get onboardingSubtitle =>
      'Só algumas informações básicas — leva menos de um minuto.';

  @override
  String get onboardingNameLabel => 'Nome';

  @override
  String get onboardingCountryLabel => 'País';

  @override
  String get onboardingCityLabel => 'Cidade';

  @override
  String get onboardingGenderTitle => 'Gênero';

  @override
  String get onboardingGenderMasculino => 'Masculino';

  @override
  String get onboardingGenderFeminino => 'Feminino';

  @override
  String get onboardingGenderNaoBinario => 'Não-binário';

  @override
  String get onboardingGenderPrefiroNaoInformar => 'Prefiro não informar';

  @override
  String get onboardingAgeRangeTitle => 'Faixa etária';

  @override
  String get onboardingContinueButton => 'Continuar';

  @override
  String get feedbackMenuTooltip => 'Enviar feedback';

  @override
  String get feedbackScreenTitle => 'Enviar feedback';

  @override
  String get feedbackScreenIntro =>
      'Conta pra gente o que você acha do MENTAL — sugestão, elogio ou algo que travou. Sua opinião ajuda a melhorar o app.';

  @override
  String get feedbackCommentHint => 'Escreva aqui...';

  @override
  String get feedbackSendButton => 'Enviar';

  @override
  String get feedbackSentMessage =>
      'Feedback enviado! Obrigado por ajudar a melhorar o MENTAL. 🙌';

  @override
  String get homeNavLabel => 'Início';

  @override
  String get moreNavLabel => 'Mais';
}
