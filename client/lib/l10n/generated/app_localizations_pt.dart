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
    return 'Desafio $territory';
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
  String get territoryRedacao => 'Redação';

  @override
  String get territoryVisual => 'Visual';

  @override
  String get territoryEsportes => 'Esportes';

  @override
  String get territoryRegioes => 'Regiões';

  @override
  String get territoryCulturaPop => 'Cultura Pop';

  @override
  String get territoryCores => 'Cores';

  @override
  String get territoryMitologiaGrega => 'Mitologia Grega';

  @override
  String get territoryMitologiaNordica => 'Mitologia Nórdica';

  @override
  String get territoryMitologiaIndigena => 'Mitologia Indígena';

  @override
  String get territoryEnemLinguagens => 'ENEM: Linguagens';

  @override
  String get territoryEnemHumanas => 'ENEM: Humanas';

  @override
  String get territoryEnemNatureza => 'ENEM: Natureza';

  @override
  String get territoryEnemMatematica => 'ENEM: Matemática';

  @override
  String get territoryConcursosPortugues => 'Concursos: Português';

  @override
  String get territoryConcursosRaciocinio => 'Concursos: Lógica';

  @override
  String get territoryConcursosDireito => 'Concursos: Direito';

  @override
  String get territoryTecnologiaFundamentos => 'Tecnologia: Fundamentos';

  @override
  String get territoryTecnologiaProgramacao => 'Tecnologia: Programação';

  @override
  String get territoryTecnologiaSeguranca => 'Tecnologia: Segurança';

  @override
  String get territoryTecnologiaFronteira => 'Tecnologia: Fronteira';

  @override
  String get territoryFinancasPessoais => 'Finanças Pessoais';

  @override
  String get territoryFilosofia => 'Filosofia';

  @override
  String get territoryArtes => 'Artes';

  @override
  String get territorySaudeBemestar => 'Saúde e Bem-estar';

  @override
  String get territoryCuriosidadeRelampago => 'Curiosidade Relâmpago';

  @override
  String get territoryLibras => 'Libras';

  @override
  String get territoryCacaPalavras => 'Caça-palavras';

  @override
  String get territoryInvencoes => 'Invenções';

  @override
  String get territoryVeiculos => 'Carros, Motos e Aviões';

  @override
  String get territoryAstronomia => 'Astronomia e Espaço';

  @override
  String get territoryDetetiveMental => 'Detetive Mental';

  @override
  String get detectiveNextClueButton => 'Próxima pista';

  @override
  String get detectiveRevealQuestionButton => 'Ver pergunta';

  @override
  String detectiveClueLabel(int number) {
    return 'Pista $number';
  }

  @override
  String get territoryOuvidoAfiado => 'Ouvido Afiado';

  @override
  String get territoryInglesBasico => 'Inglês Básico';

  @override
  String get territoryInglesIntermediario => 'Inglês Intermediário';

  @override
  String get territoryInglesAvancado => 'Inglês Avançado';

  @override
  String get territoryEspanholBasico => 'Espanhol Básico';

  @override
  String get territoryEspanholIntermediario => 'Espanhol Intermediário';

  @override
  String get territoryEspanholAvancado => 'Espanhol Avançado';

  @override
  String get territoryFrancesBasico => 'Francês Básico';

  @override
  String get territoryFrancesIntermediario => 'Francês Intermediário';

  @override
  String get territoryFrancesAvancado => 'Francês Avançado';

  @override
  String get audioPlayButton => 'Tocar som';

  @override
  String get audioReplayButton => 'Ouvir de novo';

  @override
  String get audioLoadErrorMessage =>
      'Não foi possível carregar o áudio. Tente de novo.';

  @override
  String audioSourceCreditLabel(String source) {
    return 'Fonte: $source';
  }

  @override
  String get learningPauseButtonTooltip => 'Pausa para Aprender';

  @override
  String get learningPauseScreenTitle => 'Pausa para Aprender';

  @override
  String get learningPauseEmptyMessage =>
      'Ainda não há Pausas para Aprender neste território.';

  @override
  String get wordSearchEmptyMessage =>
      'Ainda não há Caça-palavras neste território.';

  @override
  String get wordSearchCompletedMessage => 'Você encontrou todas as palavras!';

  @override
  String wordSearchXpAwardedMessage(int xp) {
    return '+$xp XP';
  }

  @override
  String wordSearchSpeedBonusMessage(int bonus) {
    return 'Incluindo +$bonus XP de bônus de velocidade!';
  }

  @override
  String get learningPauseCompleteButton => 'Concluí a leitura';

  @override
  String get learningPauseWatchVideoButton => 'Assistir vídeo de referência';

  @override
  String institutionalVideoSourceLabel(String source) {
    return 'Fonte: $source';
  }

  @override
  String get institutionalVideoFallbackTitle => 'Abrir vídeo no YouTube?';

  @override
  String get institutionalVideoFallbackBody =>
      'Não foi possível abrir o vídeo dentro do MENTAL. Deseja abri-lo no YouTube?';

  @override
  String get institutionalVideoFallbackCancel => 'Cancelar';

  @override
  String get institutionalVideoFallbackConfirm => 'Abrir';

  @override
  String learningPauseXpAwardedMessage(int xp) {
    return '+$xp XP pela leitura!';
  }

  @override
  String get learningPauseAlreadyReadMessage =>
      'Você já leu essa Pausa antes — obrigado por revisitar!';

  @override
  String get adminMetricsMenuLabel => 'Painel Admin';

  @override
  String get tutorialSkipButton => 'Pular';

  @override
  String get tutorialNextButton => 'Próximo';

  @override
  String get tutorialStartButton => 'Vamos começar';

  @override
  String get tutorialMenuLabel => 'Como usar o MENTAL';

  @override
  String get tutorialPage1Title => 'Bem-vindo ao MENTAL';

  @override
  String get tutorialPage1Body =>
      'MENTAL é quem conquista com a mente. Você responde desafios de raciocínio, ganha XP e sobe de nível — sem pressa, no seu ritmo.';

  @override
  String get tutorialPage2Title => 'Territórios e Mundos';

  @override
  String get tutorialPage2Body =>
      'Cada território testa um tipo de raciocínio diferente — palavras, números, lógica, cultura geral e mais. Eles ficam agrupados em Mundos, na tela inicial.';

  @override
  String get tutorialPage3Title => 'Modo Relâmpago';

  @override
  String get tutorialPage3Body =>
      'Prefere emoção? O Relâmpago é o mesmo território, só que com cronômetro e bônus de XP por velocidade — quanto mais rápido acertar, maior o bônus.';

  @override
  String get tutorialPage4Title => 'Sequência e Movimento';

  @override
  String get tutorialPage4Body =>
      'Jogue todo dia pra manter sua sequência (streak) viva. E ative o Movimento pra transformar os passos da sua caminhada em XP e MentalCoins, mesmo com o app fechado.';

  @override
  String get tutorialPage5Title => 'MentalCoins e Ranking';

  @override
  String get tutorialPage5Body =>
      'Dispute o ranking semanal com seus amigos e ganhe MentalCoins — uma moeda de prestígio que você troca por itens exclusivos de perfil.';

  @override
  String get tutorialPage6Title => 'Do seu jeito';

  @override
  String get tutorialPage6Body =>
      'Em Ajuste, você troca entre tom claro e escuro, controla som e notificações — e pode rever este tutorial a qualquer momento.';

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
  String get batchCompletedMessage =>
      'Você completou todos os desafios disponíveis aqui por agora!';

  @override
  String get batchCompletedBackToHomeButton => 'Voltar para o Início';

  @override
  String roundReviewOfferMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Você errou $count perguntas nesta rodada.',
      one: 'Você errou 1 pergunta nesta rodada.',
    );
    return '$_temp0';
  }

  @override
  String get roundReviewDeclineButton => 'Não, obrigado';

  @override
  String get roundReviewAcceptButton => 'Refazer erros';

  @override
  String get roundReviewBadgeLabel => 'Modo revisão · sem XP';

  @override
  String roundReviewRemainingMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Faltam $count revisões.',
      one: 'Falta 1 revisão.',
    );
    return '$_temp0';
  }

  @override
  String get roundReviewNextButton => 'Próxima revisão';

  @override
  String get roundReviewFinishedMessage => 'Revisão concluída!';

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
  String get rankingTapHint =>
      'Toque em qualquer jogador para ver o desempenho completo';

  @override
  String rankingBadgeStreakSemantics(int days) {
    return 'Sequência de $days dias';
  }

  @override
  String rankingBadgeWorldsSemantics(int completed, int total) {
    return '$completed de $total mundos completos';
  }

  @override
  String rankingBadgeBadgesSemantics(int count) {
    return '$count conquistas';
  }

  @override
  String rankingBadgeMentalcoinsSemantics(int count) {
    return '$count MentalCoins';
  }

  @override
  String rankingBadgeStepsSemantics(int count) {
    return '$count passos';
  }

  @override
  String get badgesScreenTitle => 'Conquistas';

  @override
  String get publicProfileScreenTitle => 'Perfil';

  @override
  String publicProfileLevelLabel(int level) {
    return 'Nível $level';
  }

  @override
  String publicProfileXpLabel(int xp) {
    return '$xp XP';
  }

  @override
  String publicProfileStreakLabel(int days) {
    return '$days dias de sequência';
  }

  @override
  String get publicProfileBestTerritoryLabel => 'Melhor desempenho';

  @override
  String get publicProfileNoBestTerritory => 'Ainda sem território de destaque';

  @override
  String get publicProfileBadgesLabel => 'Conquistas';

  @override
  String get publicProfileNoBadges => 'Ainda sem conquistas';

  @override
  String get publicProfileWorldsLabel => 'Mundos';

  @override
  String get publicProfileTorcidaLabel => 'Mande uma torcida!';

  @override
  String publicProfileTorcidaSentToday(int count) {
    return 'Você já torceu ${count}x hoje';
  }

  @override
  String get publicProfileTorcidaSentFeedback => 'Torcida enviada!';

  @override
  String get publicProfileTorcidaLimitReached =>
      'Você já atingiu o limite de torcida hoje pra esta pessoa';

  @override
  String get viewBadgesButton => 'Ver conquistas';

  @override
  String get badgeEarnedLabel => 'Conquistado';

  @override
  String get badgeLockedLabel => 'Bloqueado';

  @override
  String get settingsTooltip => 'Ajuste';

  @override
  String get settingsScreenTitle => 'Ajuste';

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
  String get pushPrimingDialogTitle => 'Ativar notificações?';

  @override
  String get pushPrimingDialogMessage =>
      'O MENTAL usa notificações pra avisar quando alguém ultrapassa você no ranking e pra lembrar de manter sua sequência em dia. Você pode desativar cada tipo depois em Ajuste.';

  @override
  String get pushPrimingDialogAllowButton => 'Ativar';

  @override
  String get pushPrimingDialogDeclineButton => 'Agora não';

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
  String get movementOpenSettingsButton => 'Abrir configurações do aparelho';

  @override
  String get movementSensorUnavailableMessage =>
      'Não foi possível ler o sensor de passos agora.';

  @override
  String movementCurrentCycleLabel(int steps) {
    return 'Passos coletados neste ciclo: $steps';
  }

  @override
  String get movementOscillationPendingMessage =>
      'Ainda sem dados de oscilação hoje — ande um pouco pra ver o pico e o vale aparecerem.';

  @override
  String movementPendingReportLabel(int steps) {
    return 'Você ainda tem um ciclo anterior com $steps passos pra coletar — eles entram na próxima coleta.';
  }

  @override
  String get movementCollectPendingButton => 'Coletar';

  @override
  String get movementBonusAlertMessage => 'Colete seus bônus de Movimento';

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
  String get movementTodayCardTitle => 'Hoje';

  @override
  String get movementTodayCardSubtitle => 'Progressão do dia';

  @override
  String movementTodayCardValue(int steps, int percent) {
    return '$steps passos · $percent% da meta';
  }

  @override
  String movementTodayCardValueNoGoal(int steps) {
    return '$steps passos hoje';
  }

  @override
  String get movementWeekCardTitle => 'Semana';

  @override
  String get movementWeekCardSubtitle => 'Últimos 7 dias';

  @override
  String movementWeekCardValue(int average, int total) {
    return 'média $average · total $total';
  }

  @override
  String get movementYearCardTitle => 'Ano';

  @override
  String movementYearCardSubtitle(int year) {
    return 'Seu progresso em $year';
  }

  @override
  String get movementDailyDetailTitle => 'Progressão do dia';

  @override
  String get movementDailyDetailStepsLabel => 'Passos';

  @override
  String get movementDailyDetailXpLabel => 'XP';

  @override
  String get movementDailyDetailGoalLabel => 'Meta do dia';

  @override
  String get movementWeeklyDetailTitle => 'Progressão semanal';

  @override
  String get movementWeeklyDetailHint => 'Toque num dia para ver os detalhes.';

  @override
  String get movementYearlyDetailTitle => 'Progressão anual';

  @override
  String get movementYearlyTotalStepsLabel => 'Total de passos';

  @override
  String get movementYearlyAverageLabel => 'Média por dia ativo';

  @override
  String get movementYearlyActiveDaysLabel => 'Dias ativos';

  @override
  String get movementYearlyBestMonthLabel => 'Melhor mês';

  @override
  String get movementYearlyXpLabel => 'XP de Movimento no ano';

  @override
  String get movementYearlyEmptyMessage =>
      'Ainda não há dados de Movimento neste ano.';

  @override
  String get movementSyncFailedMessage =>
      'Dados atualizados localmente. Não foi possível sincronizar agora.';

  @override
  String get movementRetryButton => 'Tentar novamente';

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
  String get friendsSearchFieldHint => 'Buscar amigo pelo nome';

  @override
  String get friendsSearchSendInviteButton => 'Convidar';

  @override
  String get friendsSearchAlreadyFriendsLabel => 'Já são amigos';

  @override
  String get friendsSearchRequestPendingLabel => 'Pedido enviado';

  @override
  String get friendsSearchEmptyMessage =>
      'Nenhum resultado — confira se digitou o nome certo.';

  @override
  String get friendsAddFieldHint => 'Cole o código de um amigo';

  @override
  String get friendsAddButton => 'Adicionar';

  @override
  String get friendsListTitle => 'Seus amigos';

  @override
  String get friendsHelpTooltip => 'Como funciona';

  @override
  String get friendsHelpTitle => 'Amigos — como funciona';

  @override
  String get friendsHelpStep1Title => 'Convide pelo seu código';

  @override
  String get friendsHelpStep1Body =>
      'Copie seu código ou compartilhe direto com alguém. Quem receber pode colar esse código no campo \"Adicionar amigo\".';

  @override
  String get friendsHelpStep2Title => 'Adicionar não é automático';

  @override
  String get friendsHelpStep2Body =>
      'Colar o código de alguém envia um pedido de amizade — a pessoa precisa aceitar antes de vocês virarem amigos de verdade.';

  @override
  String get friendsHelpStep3Title => 'Aceitar ou recusar';

  @override
  String get friendsHelpStep3Body =>
      'Pedidos recebidos aparecem em \"Pedidos de amizade\", com botões para aceitar ou recusar cada um.';

  @override
  String get friendsHelpStep4Title => 'Desafie seus amigos';

  @override
  String get friendsHelpStep4Body =>
      'Depois de amigos, toque em \"Desafiar\" ao lado do nome dele pra criar uma Batalha entre vocês dois.';

  @override
  String get friendsHelpStep5Title => 'Denunciar ou bloquear';

  @override
  String get friendsHelpStep5Body =>
      'Toque nos \"⋮\" ao lado de um amigo ou pedido pra denunciar um comportamento inadequado ou bloquear a pessoa.';

  @override
  String get friendRequestsTitle => 'Pedidos de amizade';

  @override
  String get friendRequestSentMessage =>
      'Pedido de amizade enviado! A pessoa precisa aceitar.';

  @override
  String get friendRequestAcceptButton => 'Aceitar';

  @override
  String get friendRequestDeclineButton => 'Recusar';

  @override
  String get friendsEmptyMessage =>
      'Você ainda não tem amigos adicionados. Compartilhe seu código ou cole o código de alguém.';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get reportUserOption => 'Denunciar';

  @override
  String get blockUserOption => 'Bloquear';

  @override
  String get reportUserDialogTitle => 'Motivo da denúncia';

  @override
  String get reportUserDialogHint => 'Descreva o que aconteceu';

  @override
  String get reportUserDialogSendButton => 'Enviar denúncia';

  @override
  String get reportUserSuccessMessage =>
      'Denúncia enviada. Nossa equipe vai revisar.';

  @override
  String get blockUserDialogTitle => 'Bloquear usuário';

  @override
  String blockUserDialogMessage(String nickname) {
    return 'Bloquear $nickname? Isso encerra a amizade (se houver) e impede novos pedidos de amizade entre vocês dois.';
  }

  @override
  String blockUserSuccessMessage(String nickname) {
    return '$nickname foi bloqueado(a).';
  }

  @override
  String get friendMoreOptionsTooltip => 'Mais opções';

  @override
  String get blockedUsersSectionTitle => 'Usuários bloqueados';

  @override
  String get unblockUserButton => 'Desbloquear';

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
  String get shareAppButtonTooltip => 'Convidar amigos para o MENTAL';

  @override
  String shareAppInviteMessage(String playStoreUrl) {
    return 'Venha jogar MENTAL comigo — quem conquista, conquista com a mente! Baixe grátis: $playStoreUrl';
  }

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
  String shareAppXpAndCoinsRewardedMessage(int xp, int coins) {
    return '+$xp XP e +$coins MentalCoins por convidar um amigo!';
  }

  @override
  String get homeSearchHint => 'Buscar tema, frase ou palavra...';

  @override
  String homeSearchNotFoundMessage(String query) {
    return 'Não encontramos nada para \"$query\".';
  }

  @override
  String get homeSearchSuggestButton => 'Sugerir esse conteúdo';

  @override
  String get homeSearchSuggestionRegisteredMessage =>
      'Sugestão registrada! Um agente vai avaliar esse conteúdo.';

  @override
  String get homeMoreCardLabel => 'Mais';

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
  String get battlesHelpTooltip => 'Como funciona';

  @override
  String get battlesHelpTitle => 'Batalhas — como funciona';

  @override
  String get battlesHelpStep1Title => 'Só entre amigos';

  @override
  String get battlesHelpStep1Body =>
      'Uma batalha só pode ser criada com quem já é seu amigo — toque em \"Desafiar\" na tela Amigos.';

  @override
  String get battlesHelpStep2Title => 'Escolha território e nível';

  @override
  String get battlesHelpStep2Body =>
      'Ao desafiar, você escolhe o território e o nível de dificuldade (1 a 5) do desafio que os dois vão responder.';

  @override
  String get battlesHelpStep3Title => 'Cada um no seu tempo';

  @override
  String get battlesHelpStep3Body =>
      'A batalha não é ao vivo — cada pessoa responde quando quiser, sem precisar estar online ao mesmo tempo.';

  @override
  String get battlesHelpStep4Title => 'Quem vence';

  @override
  String get battlesHelpStep4Body =>
      'Acertar sempre vence errar. Se os dois acertarem, vence quem respondeu mais rápido. Se os dois errarem, é empate.';

  @override
  String get battlesHelpStep5Title => 'Limite e recompensa';

  @override
  String get battlesHelpStep5Body =>
      'Você pode enviar até 3 desafios por dia. Vencer uma batalha dá um bônus de +30 XP.';

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
  String get profilePhotoSectionTitle => 'Foto de perfil';

  @override
  String get profilePhotoChangeButton => 'Escolher foto';

  @override
  String get profilePhotoPendingLabel =>
      'Sua foto está em análise — só fica visível pra outros usuários depois de aprovada.';

  @override
  String get profilePhotoRejectedLabel =>
      'Sua foto foi rejeitada na moderação. Envie outra.';

  @override
  String get profilePhotoUploadError =>
      'Não foi possível enviar a foto. Tente novamente.';

  @override
  String get photoCropFailedError =>
      'Não foi possível recortar essa foto. Tente escolher outra ou tirar uma nova.';

  @override
  String get profileRealNameLabel => 'Nome real';

  @override
  String get profileRealNameHelperText =>
      'Aparece publicamente ao lado da sua foto de perfil, em Ranking, Amigos e Batalhas.';

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
  String get settingsDeleteAccountButton => 'Excluir minha conta';

  @override
  String get settingsDeleteAccountConfirmTitle => 'Excluir sua conta?';

  @override
  String get settingsDeleteAccountConfirmMessage =>
      'Isso apaga permanentemente seu perfil, progresso, amigos e foto de perfil. Não é possível desfazer.';

  @override
  String get settingsDeleteAccountConfirmButton => 'Excluir permanentemente';

  @override
  String get settingsDeleteAccountCancelButton => 'Cancelar';

  @override
  String get settingsDeleteAccountUnavailableError =>
      'Exclusão de conta indisponível no momento. Tente novamente mais tarde ou entre em contato pelo e-mail de suporte.';

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
  String get onboardingGenderOptionalTitle => 'Gênero (opcional)';

  @override
  String get onboardingPhotoTitle => 'Foto de perfil';

  @override
  String get onboardingPhotoChosenLabel => 'Trocar foto';

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
  String get feedbackMenuTooltip => 'Feedback';

  @override
  String get feedbackScreenTitle => 'Feedback';

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

  @override
  String get mentalCoinsTooltip => 'MentalCoins';

  @override
  String get mentalCoinsScreenTitle => 'MentalCoins';

  @override
  String mentalCoinsCycleNote(String end, String start) {
    return 'Ciclo iniciado em $start · fecha em $end';
  }

  @override
  String get mentalCoinsHowToEarnTitle => 'Como ganhar essa semana';

  @override
  String get mentalCoinsXpDailyLabel => 'Top 3 de XP do dia';

  @override
  String get mentalCoinsXpDailyValue => '1º: 10 · 2º: 5 · 3º: 3';

  @override
  String get mentalCoinsStepsWeekLabel => 'Campeão da semana em passos';

  @override
  String get mentalCoinsStepsWeekValue => '+20 MentalCoins';

  @override
  String get mentalCoinsStepsDayLabel => 'Recordista do dia em passos';

  @override
  String get mentalCoinsStepsDayValue => '+10 MentalCoins';

  @override
  String get mentalCoinsHallOfFameTitle => 'Hall da Fama da semana';

  @override
  String get mentalCoinsHallOfFameEmpty =>
      'Nenhuma semana fechada ainda — os vencedores aparecem aqui a partir do primeiro fechamento de ciclo.';

  @override
  String get mentalCoinsRedeemTitle => 'Resgatar';

  @override
  String get mentalCoinsRedeemedLabel => 'Resgatado';

  @override
  String get mentalCoinsRedeemButton => 'Resgatar';

  @override
  String get mentalCoinsRedeemSuccessMessage => 'Item resgatado!';

  @override
  String get mentalCoinsInsufficientBalanceError =>
      'Saldo insuficiente para resgatar este item.';

  @override
  String get feedbackMyHistoryTitle => 'Comentários da comunidade';

  @override
  String get feedbackAdminReplyLabel => 'Resposta da equipe';

  @override
  String get feedbackMineLabel => 'Você';

  @override
  String get adminFeedbackEmptyMessage =>
      'Nenhum feedback ainda. Seja o primeiro a comentar!';

  @override
  String get adminFeedbackReplyButton => 'Responder';

  @override
  String get adminFeedbackEditReplyButton => 'Editar resposta';

  @override
  String get adminFeedbackReplyDialogTitle => 'Responder feedback';

  @override
  String get adminFeedbackReplyHint => 'Escreva sua resposta...';

  @override
  String get adminFeedbackReplySendButton => 'Enviar resposta';

  @override
  String get movementGoalChipLight => '5k';

  @override
  String get movementGoalChipStandard => '10k';

  @override
  String get movementGoalChipIntense => '15k';

  @override
  String get movementGoalChipLightLabel => 'leve';

  @override
  String get movementGoalChipStandardLabel => 'padrão';

  @override
  String get movementGoalChipIntenseLabel => 'intenso';

  @override
  String get movementGoalSelectorTitle => 'Sua meta diária';

  @override
  String get movementGoalSelectorSubtitle => 'define seu ritmo de XP';

  @override
  String get movementStepsTodayLabel => 'passos hoje';

  @override
  String get movementXpTodayLabel => 'XP conquistado';

  @override
  String get movementConversionRuleText => 'A cada 100 passos = +2 XP';

  @override
  String get movementLiveLabel => 'AO VIVO';

  @override
  String get movementPeakLabel => 'pico';

  @override
  String get movementValleyLabel => 'vale';

  @override
  String get movementGoalGoButton => 'Ir';

  @override
  String get movementCurrentGoalLabel => 'Meta atual';

  @override
  String get movementCustomGoalHint => 'livre';

  @override
  String get movementGoalChipCustomLabel => 'sua meta';

  @override
  String get movementGoalChipCollectHint => 'toque p/ coletar';

  @override
  String get photoSourceExplanation =>
      'Sua foto de perfil é obrigatória e passa por moderação antes de aparecer para outros jogadores. Escolha como enviar:';

  @override
  String get photoSourceCameraOption => 'Tirar foto';

  @override
  String get photoSourceGalleryOption => 'Escolher da galeria';

  @override
  String get photoCropToolbarTitle => 'Ajustar foto';
}
