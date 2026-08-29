import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('pt')];

  /// Loading state shown during cold start / initial bootstrap
  ///
  /// In pt, this message translates to:
  /// **'Preparando seu desafio...'**
  String get preparingChallenge;

  /// MENTAL-POL-002 §3.1 — single majority confirmation screen main text
  ///
  /// In pt, this message translates to:
  /// **'Este aplicativo é destinado a maiores de 18 anos.'**
  String get ageGateTitle;

  /// Age confirmation supporting text
  ///
  /// In pt, this message translates to:
  /// **'Confirme que você tem 18 anos ou mais para continuar.'**
  String get ageGateSubtitle;

  /// MENTAL-POL-002 §3.1 — mandatory majority confirmation checkbox
  ///
  /// In pt, this message translates to:
  /// **'Confirmo que tenho 18 anos ou mais.'**
  String get ageGateCheckboxLabel;

  /// Text before the Terms/Privacy Policy link
  ///
  /// In pt, this message translates to:
  /// **'Ao continuar, você concorda com os '**
  String get ageGateTermsLinkPrefix;

  /// Tappable Terms of Use / Privacy Policy link text
  ///
  /// In pt, this message translates to:
  /// **'Termos de Uso e a Política de Privacidade'**
  String get ageGateTermsLinkText;

  /// Single continue button, enabled only when checkbox is checked
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get ageGateContinueButton;

  /// Home app bar title (brand wordmark)
  ///
  /// In pt, this message translates to:
  /// **'MENTAL'**
  String get homeTitle;

  /// Home progress summary line
  ///
  /// In pt, this message translates to:
  /// **'XP: {xp} · Nível {level} · Streak: {streak} dias'**
  String progressSummary(int xp, int level, int streak);

  /// Primary CTA per territory on Home
  ///
  /// In pt, this message translates to:
  /// **'Desafio {territory}'**
  String newChallengeButton(String territory);

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Palavras'**
  String get territoryPalavras;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Números'**
  String get territoryNumeros;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Lógica'**
  String get territoryLogica;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Conhecimento'**
  String get territoryConhecimento;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Enigmas'**
  String get territoryEnigmas;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Textos'**
  String get territoryTextos;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Visual'**
  String get territoryVisual;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Esportes'**
  String get territoryEsportes;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Regiões'**
  String get territoryRegioes;

  /// Territory display name
  ///
  /// In pt, this message translates to:
  /// **'Cultura Pop'**
  String get territoryCulturaPop;

  /// Celebratory daily-limit message, MONETIZATION_UPDATE_FREE_LAUNCH.md §3
  ///
  /// In pt, this message translates to:
  /// **'Você mandou bem hoje! Volte amanhã para mais 24 desafios grátis.'**
  String get dailyLimitReachedMessage;

  /// Territory locked message
  ///
  /// In pt, this message translates to:
  /// **'Este território exige assinatura.'**
  String get territoryLockedMessage;

  /// Button for permanent-for-today errors (daily limit / locked)
  ///
  /// In pt, this message translates to:
  /// **'Voltar para o início'**
  String get backToHomeButton;

  /// Button for transient/retryable errors
  ///
  /// In pt, this message translates to:
  /// **'Tentar de novo'**
  String get tryAgainButton;

  /// Free-text answer field label
  ///
  /// In pt, this message translates to:
  /// **'Sua resposta'**
  String get yourAnswerLabel;

  /// Shown hint content, prefixed
  ///
  /// In pt, this message translates to:
  /// **'Dica: {hint}'**
  String hintPrefix(String hint);

  /// Shown once hints_available is exhausted
  ///
  /// In pt, this message translates to:
  /// **'Sem mais dicas para este desafio.'**
  String get noMoreHintsMessage;

  /// Hint request button
  ///
  /// In pt, this message translates to:
  /// **'Pedir uma dica'**
  String get requestHintButton;

  /// Primary CTA to submit an answer
  ///
  /// In pt, this message translates to:
  /// **'Confirmar resposta'**
  String get confirmAnswerButton;

  /// Result screen headline when correct
  ///
  /// In pt, this message translates to:
  /// **'Você acertou!'**
  String get correctAnswerFeedback;

  /// Result screen headline when incorrect, non-punitive tone
  ///
  /// In pt, this message translates to:
  /// **'Não foi dessa vez.'**
  String get incorrectAnswerFeedback;

  /// Shows the correct answer after submission
  ///
  /// In pt, this message translates to:
  /// **'Resposta correta: {answer}'**
  String correctAnswerLabel(String answer);

  /// XP breakdown after answering
  ///
  /// In pt, this message translates to:
  /// **'XP ganho: {xp} (base: {base}, dicas usadas: {hints})'**
  String xpEarnedLabel(int xp, int base, int hints);

  /// Button to load the next challenge
  ///
  /// In pt, this message translates to:
  /// **'Próximo desafio'**
  String get nextChallengeButton;

  /// FEEDBACK_POS_NIVEL.md — heading for the post-level feedback blocks
  ///
  /// In pt, this message translates to:
  /// **'Como foi esse nível?'**
  String get levelFeedbackHeading;

  /// FEEDBACK_POS_NIVEL.md — action block, option to redo the same level
  ///
  /// In pt, this message translates to:
  /// **'Repetir este nível'**
  String get levelFeedbackRepeatAction;

  /// FEEDBACK_POS_NIVEL.md — action block, option to advance to the next level
  ///
  /// In pt, this message translates to:
  /// **'Seguir em frente'**
  String get levelFeedbackContinueAction;

  /// FEEDBACK_POS_NIVEL.md — difficulty rating option
  ///
  /// In pt, this message translates to:
  /// **'Fácil'**
  String get levelFeedbackDifficultyFacil;

  /// FEEDBACK_POS_NIVEL.md — difficulty rating option
  ///
  /// In pt, this message translates to:
  /// **'Médio'**
  String get levelFeedbackDifficultyMedio;

  /// FEEDBACK_POS_NIVEL.md — difficulty rating option
  ///
  /// In pt, this message translates to:
  /// **'Difícil'**
  String get levelFeedbackDifficultyDificil;

  /// FEEDBACK_POS_NIVEL.md — difficulty rating option
  ///
  /// In pt, this message translates to:
  /// **'Muito difícil'**
  String get levelFeedbackDifficultyMuitoDificil;

  /// FEEDBACK_POS_NIVEL.md — optional free-text comment field hint
  ///
  /// In pt, this message translates to:
  /// **'Comentário (opcional)'**
  String get levelFeedbackCommentHint;

  /// Home app bar icon tooltip, opens Progress screen
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get progressTooltip;

  /// Home app bar icon tooltip, opens Ranking screen
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get rankingTooltip;

  /// Progress screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get progressScreenTitle;

  /// Level headline
  ///
  /// In pt, this message translates to:
  /// **'Nível {level}'**
  String levelLabel(int level);

  /// Per-territory XP progress caption
  ///
  /// In pt, this message translates to:
  /// **'{xp} / {threshold} XP'**
  String territoryXpLabel(int xp, int threshold);

  /// Badge shown on a conquered territory
  ///
  /// In pt, this message translates to:
  /// **'Conquistado'**
  String get conqueredBadge;

  /// Badge shown on a territory not yet conquered
  ///
  /// In pt, this message translates to:
  /// **'Em progresso'**
  String get inProgressBadge;

  /// Streak section title on Progress screen
  ///
  /// In pt, this message translates to:
  /// **'Sequência'**
  String get streakSectionTitle;

  /// Current streak count
  ///
  /// In pt, this message translates to:
  /// **'{days} dias seguidos'**
  String streakDaysLabel(int days);

  /// Streak freeze available explanation
  ///
  /// In pt, this message translates to:
  /// **'Proteção de sequência disponível esta semana — uma falha não quebra sua sequência.'**
  String get streakFreezeAvailableMessage;

  /// Streak freeze already used explanation
  ///
  /// In pt, this message translates to:
  /// **'Proteção de sequência já usada esta semana.'**
  String get streakFreezeUsedMessage;

  /// Ranking screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get rankingScreenTitle;

  /// Ranking window caption (weekly)
  ///
  /// In pt, this message translates to:
  /// **'Ranking da semana'**
  String get rankingWindowLabel;

  /// Rank position prefix
  ///
  /// In pt, this message translates to:
  /// **'#{rank}'**
  String rankingPositionLabel(int rank);

  /// Marks the current user's row in the ranking list
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get rankingMePrefix;

  /// Empty ranking state
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há desafios respondidos esta semana. Jogue para aparecer no ranking!'**
  String get rankingEmptyMessage;

  /// Badges screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Conquistas'**
  String get badgesScreenTitle;

  /// Button on Progress screen linking to Badges screen
  ///
  /// In pt, this message translates to:
  /// **'Ver conquistas'**
  String get viewBadgesButton;

  /// Badge earned status
  ///
  /// In pt, this message translates to:
  /// **'Conquistado'**
  String get badgeEarnedLabel;

  /// Badge not-yet-earned status
  ///
  /// In pt, this message translates to:
  /// **'Bloqueado'**
  String get badgeLockedLabel;

  /// Home app bar icon tooltip, opens Settings screen
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTooltip;

  /// Settings screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsScreenTitle;

  /// Sound settings section title, MICROINTERACTIONS.md/AUDIO_FEEDBACK.md
  ///
  /// In pt, this message translates to:
  /// **'Som'**
  String get soundSectionTitle;

  /// Sound effects on/off toggle label
  ///
  /// In pt, this message translates to:
  /// **'Efeitos sonoros'**
  String get soundToggleLabel;

  /// Sound effects volume slider label
  ///
  /// In pt, this message translates to:
  /// **'Volume dos efeitos'**
  String get soundVolumeLabel;

  /// Explains that device silent/vibrate mode is respected, AUDIO_FEEDBACK.md §3
  ///
  /// In pt, this message translates to:
  /// **'O som não toca enquanto o aparelho estiver no modo silencioso ou vibrar.'**
  String get soundSilencedNote;

  /// Level up celebration message
  ///
  /// In pt, this message translates to:
  /// **'Nível {level} alcançado!'**
  String levelUpMessage(int level);

  /// Territory just conquered celebration message
  ///
  /// In pt, this message translates to:
  /// **'Território conquistado!'**
  String get territoryConqueredCelebrationMessage;

  /// World just completed celebration message, including the completion bonus XP
  ///
  /// In pt, this message translates to:
  /// **'{world} completo! +{xp} XP de bônus'**
  String worldCompletedCelebrationMessage(String world, int xp);

  /// Badge just unlocked celebration message
  ///
  /// In pt, this message translates to:
  /// **'Nova conquista: {badgeName}!'**
  String badgeUnlockedCelebrationMessage(String badgeName);

  /// Streak extended/protected celebration message
  ///
  /// In pt, this message translates to:
  /// **'Sequência de {days} dias mantida!'**
  String streakExtendedCelebrationMessage(int days);

  /// Home app bar icon tooltip, opens Stats screen
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get statsTooltip;

  /// Stats screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Estatísticas'**
  String get statsScreenTitle;

  /// Button on Progress screen linking to Stats screen
  ///
  /// In pt, this message translates to:
  /// **'Ver estatísticas'**
  String get viewStatsButton;

  /// Stats screen overview section title
  ///
  /// In pt, this message translates to:
  /// **'Visão geral'**
  String get statsOverviewSectionTitle;

  /// Total attempts stat label
  ///
  /// In pt, this message translates to:
  /// **'Desafios respondidos'**
  String get statsTotalAttemptsLabel;

  /// Overall accuracy stat label
  ///
  /// In pt, this message translates to:
  /// **'Acerto geral'**
  String get statsAccuracyLabel;

  /// Hint-free correct answers stat label
  ///
  /// In pt, this message translates to:
  /// **'Acertos sem dica'**
  String get statsHintFreeCorrectLabel;

  /// Total hints used stat label
  ///
  /// In pt, this message translates to:
  /// **'Dicas usadas'**
  String get statsHintsUsedLabel;

  /// Answer breakdown donut legend: correct answers that used a hint
  ///
  /// In pt, this message translates to:
  /// **'Acertos com dica'**
  String get statsCorrectWithHintLegend;

  /// Answer breakdown donut legend: incorrect answers
  ///
  /// In pt, this message translates to:
  /// **'Erros'**
  String get statsIncorrectLegend;

  /// Current / longest streak stat label
  ///
  /// In pt, this message translates to:
  /// **'Sequência atual / mais longa'**
  String get statsStreakLabel;

  /// Current / longest streak value
  ///
  /// In pt, this message translates to:
  /// **'{current} / {longest} dias'**
  String statsStreakValue(int current, int longest);

  /// Badges earned stat label
  ///
  /// In pt, this message translates to:
  /// **'Conquistas desbloqueadas'**
  String get statsBadgesLabel;

  /// Badges earned / total value
  ///
  /// In pt, this message translates to:
  /// **'{earned} / {total}'**
  String statsBadgesValue(int earned, int total);

  /// Stats screen per-territory section title
  ///
  /// In pt, this message translates to:
  /// **'Desempenho por território'**
  String get statsByTerritorySectionTitle;

  /// Per-territory attempts and accuracy caption
  ///
  /// In pt, this message translates to:
  /// **'{attempts} respondidos · {accuracy} de acerto'**
  String statsTerritoryAttemptsAndAccuracy(int attempts, String accuracy);

  /// Per-territory current adaptive difficulty level
  ///
  /// In pt, this message translates to:
  /// **'Nível de dificuldade atual: {level}'**
  String statsTerritoryDifficultyLabel(int level);

  /// Empty state for a territory with zero attempts
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem desafios respondidos neste território.'**
  String get statsNoAttemptsYet;

  /// Notifications settings section title
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get notificationsSectionTitle;

  /// Title of the priming dialog shown before the system push notification permission prompt
  ///
  /// In pt, this message translates to:
  /// **'Ativar notificações?'**
  String get pushPrimingDialogTitle;

  /// Explanation shown before asking for the system push notification permission
  ///
  /// In pt, this message translates to:
  /// **'O MENTAL usa notificações pra avisar quando alguém ultrapassa você no ranking e pra lembrar de manter sua sequência em dia. Você pode desativar cada tipo depois em Configurações.'**
  String get pushPrimingDialogMessage;

  /// Button that proceeds to the real system permission prompt
  ///
  /// In pt, this message translates to:
  /// **'Ativar'**
  String get pushPrimingDialogAllowButton;

  /// Button that skips the system permission prompt for now
  ///
  /// In pt, this message translates to:
  /// **'Agora não'**
  String get pushPrimingDialogDeclineButton;

  /// Reengagement notification toggle label
  ///
  /// In pt, this message translates to:
  /// **'Lembretes diários'**
  String get notifReengagementLabel;

  /// Reengagement notification toggle description
  ///
  /// In pt, this message translates to:
  /// **'Após 24h e 48h sem abrir o app'**
  String get notifReengagementDescription;

  /// Social/ranking notification toggle label
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get notifSocialLabel;

  /// Social/ranking notification toggle description
  ///
  /// In pt, this message translates to:
  /// **'Quando alguém avança no seu ranking'**
  String get notifSocialDescription;

  /// Home app bar icon tooltip, opens Movement screen
  ///
  /// In pt, this message translates to:
  /// **'Movimento'**
  String get movementTooltip;

  /// Movement screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Movimento'**
  String get movementScreenTitle;

  /// Movement screen intro explaining the feature
  ///
  /// In pt, this message translates to:
  /// **'Jogar não precisa ser só ficar parado. Ative o contador de passos e transforme sua caminhada em pontos — sem esforço extra.'**
  String get movementIntro;

  /// Button to enable step counting
  ///
  /// In pt, this message translates to:
  /// **'Ativar contador de passos'**
  String get movementEnableButton;

  /// Button to disable step counting
  ///
  /// In pt, this message translates to:
  /// **'Desativar'**
  String get movementDisableButton;

  /// Shown when the user denies the activity recognition permission
  ///
  /// In pt, this message translates to:
  /// **'Sem permissão de atividade física, o contador de passos fica indisponível. Você pode conceder depois, nas configurações do aparelho.'**
  String get movementPermissionDeniedMessage;

  /// Shown when the step sensor is unavailable
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível ler o sensor de passos agora.'**
  String get movementSensorUnavailableMessage;

  /// Steps collected so far in the current cycle
  ///
  /// In pt, this message translates to:
  /// **'Passos coletados neste ciclo: {steps}'**
  String movementCurrentCycleLabel(int steps);

  /// Shown in place of the peak/valley oscillation metrics when there are not enough snapshots yet today
  ///
  /// In pt, this message translates to:
  /// **'Ainda sem dados de oscilação hoje — ande um pouco pra ver o pico e o vale aparecerem.'**
  String get movementOscillationPendingMessage;

  /// Previous cycle still within the grace window, pending final collection (folded into the next tap-to-collect level)
  ///
  /// In pt, this message translates to:
  /// **'Você ainda tem um ciclo anterior com {steps} passos pra coletar — eles entram na próxima coleta.'**
  String movementPendingReportLabel(int steps);

  /// Feedback after collecting movement XP
  ///
  /// In pt, this message translates to:
  /// **'+{xp} XP dos seus passos!'**
  String movementXpCollectedFeedback(int xp);

  /// Shows the user's configured daily step goal
  ///
  /// In pt, this message translates to:
  /// **'Meta diária: {goal} passos'**
  String movementGoalLabel(int goal);

  /// Shown when the user has not set a daily goal
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma meta diária definida'**
  String get movementNoGoalLabel;

  /// Button to open the goal-setting dialog
  ///
  /// In pt, this message translates to:
  /// **'Definir meta diária'**
  String get movementSetGoalButton;

  /// Button to edit the existing daily goal
  ///
  /// In pt, this message translates to:
  /// **'Editar meta'**
  String get movementEditGoalButton;

  /// Title of the goal-setting dialog
  ///
  /// In pt, this message translates to:
  /// **'Sua meta diária de passos'**
  String get movementGoalDialogTitle;

  /// Input hint for the goal text field
  ///
  /// In pt, this message translates to:
  /// **'Ex.: 20000'**
  String get movementGoalDialogHint;

  /// Save button in the goal dialog
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get movementGoalSaveButton;

  /// Cancel button in the goal dialog
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get movementGoalCancelButton;

  /// Celebration message shown when the user's daily goal is exceeded
  ///
  /// In pt, this message translates to:
  /// **'Meta batida! +{xp} XP extra por superar seu próprio objetivo 🎉'**
  String movementGoalReachedMessage(int xp);

  /// Percentage of the daily goal reached, shown inside the progress chart
  ///
  /// In pt, this message translates to:
  /// **'{percent}% da meta'**
  String movementGoalProgressLabel(int percent);

  /// Shown inside the progress ring when no daily goal is set yet
  ///
  /// In pt, this message translates to:
  /// **'Sem meta'**
  String get movementNoGoalProgressLabel;

  /// Weekly steps bar chart title
  ///
  /// In pt, this message translates to:
  /// **'Últimos 7 dias'**
  String get movementWeeklyChartTitle;

  /// Weekly steps bar chart subtitle
  ///
  /// In pt, this message translates to:
  /// **'Passos coletados por dia — veja em quais você caminhou mais.'**
  String get movementWeeklyChartSubtitle;

  /// Intraday steps line chart title
  ///
  /// In pt, this message translates to:
  /// **'Seu dia até agora'**
  String get movementTodayChartTitle;

  /// Intraday steps line chart subtitle
  ///
  /// In pt, this message translates to:
  /// **'Como seus passos foram acumulando ao longo do ciclo.'**
  String get movementTodayChartSubtitle;

  /// Celebration message for one or more intraday checkpoints reached in a single collection
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{Checkpoint do dia batido! +{xp} XP extra 🚶} other{{count} checkpoints do dia batidos! +{xp} XP extra 🚶}}'**
  String movementCheckpointReachedMessage(int count, int xp);

  /// Home app bar icon tooltip, opens Friends screen
  ///
  /// In pt, this message translates to:
  /// **'Amigos'**
  String get friendsTooltip;

  /// Friends screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Amigos'**
  String get friendsScreenTitle;

  /// Shows the user's own invite code to share with friends
  ///
  /// In pt, this message translates to:
  /// **'Seu código: {code}'**
  String friendsInviteCodeLabel(String code);

  /// Button to copy the invite code to clipboard
  ///
  /// In pt, this message translates to:
  /// **'Copiar código'**
  String get friendsCopyCodeButton;

  /// Snackbar shown after copying the invite code
  ///
  /// In pt, this message translates to:
  /// **'Código copiado!'**
  String get friendsCodeCopiedMessage;

  /// Input hint for adding a friend by code
  ///
  /// In pt, this message translates to:
  /// **'Cole o código de um amigo'**
  String get friendsAddFieldHint;

  /// Button to add a friend by code
  ///
  /// In pt, this message translates to:
  /// **'Adicionar'**
  String get friendsAddButton;

  /// Section title for the friends list
  ///
  /// In pt, this message translates to:
  /// **'Seus amigos'**
  String get friendsListTitle;

  /// Section title for pending friend requests
  ///
  /// In pt, this message translates to:
  /// **'Pedidos de amizade'**
  String get friendRequestsTitle;

  /// Shown after redeeming an invite code, since it no longer creates the friendship immediately
  ///
  /// In pt, this message translates to:
  /// **'Pedido de amizade enviado! A pessoa precisa aceitar.'**
  String get friendRequestSentMessage;

  /// Accept a pending friend request
  ///
  /// In pt, this message translates to:
  /// **'Aceitar'**
  String get friendRequestAcceptButton;

  /// Decline a pending friend request
  ///
  /// In pt, this message translates to:
  /// **'Recusar'**
  String get friendRequestDeclineButton;

  /// Empty state for the friends list
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem amigos adicionados. Compartilhe seu código ou cole o código de alguém.'**
  String get friendsEmptyMessage;

  /// Generic cancel button used across confirmation dialogs
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancelButton;

  /// Bottom sheet option to report a user
  ///
  /// In pt, this message translates to:
  /// **'Denunciar'**
  String get reportUserOption;

  /// Bottom sheet option to block a user
  ///
  /// In pt, this message translates to:
  /// **'Bloquear'**
  String get blockUserOption;

  /// Title of the dialog asking for a report reason
  ///
  /// In pt, this message translates to:
  /// **'Motivo da denúncia'**
  String get reportUserDialogTitle;

  /// Hint text for the report reason input
  ///
  /// In pt, this message translates to:
  /// **'Descreva o que aconteceu'**
  String get reportUserDialogHint;

  /// Button to submit the report
  ///
  /// In pt, this message translates to:
  /// **'Enviar denúncia'**
  String get reportUserDialogSendButton;

  /// Confirmation shown after a report is submitted
  ///
  /// In pt, this message translates to:
  /// **'Denúncia enviada. Nossa equipe vai revisar.'**
  String get reportUserSuccessMessage;

  /// Title of the block confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Bloquear usuário'**
  String get blockUserDialogTitle;

  /// Confirmation message before blocking a user
  ///
  /// In pt, this message translates to:
  /// **'Bloquear {nickname}? Isso encerra a amizade (se houver) e impede novos pedidos de amizade entre vocês dois.'**
  String blockUserDialogMessage(String nickname);

  /// Confirmation shown after a user is blocked
  ///
  /// In pt, this message translates to:
  /// **'{nickname} foi bloqueado(a).'**
  String blockUserSuccessMessage(String nickname);

  /// Tooltip for the three-dot menu button next to a friend or friend request
  ///
  /// In pt, this message translates to:
  /// **'Mais opções'**
  String get friendMoreOptionsTooltip;

  /// Settings section title listing users the player has blocked
  ///
  /// In pt, this message translates to:
  /// **'Usuários bloqueados'**
  String get blockedUsersSectionTitle;

  /// Button to unblock a previously blocked user
  ///
  /// In pt, this message translates to:
  /// **'Desbloquear'**
  String get unblockUserButton;

  /// Error shown when the invite code does not exist
  ///
  /// In pt, this message translates to:
  /// **'Código de convite não encontrado.'**
  String get friendsInviteNotFoundError;

  /// Error shown when trying to add own invite code
  ///
  /// In pt, this message translates to:
  /// **'Você não pode adicionar a si mesmo como amigo.'**
  String get friendsCannotAddSelfError;

  /// Ranking scope toggle: global
  ///
  /// In pt, this message translates to:
  /// **'Global'**
  String get rankingScopeGlobal;

  /// Ranking scope toggle: friends
  ///
  /// In pt, this message translates to:
  /// **'Amigos'**
  String get rankingScopeFriends;

  /// Generic share button label
  ///
  /// In pt, this message translates to:
  /// **'Compartilhar'**
  String get shareButtonLabel;

  /// Share text for territory conquered achievement
  ///
  /// In pt, this message translates to:
  /// **'Conquistei o território {territory} no MENTAL! 🏆'**
  String shareTerritoryConqueredMessage(String territory);

  /// Share text for world completed achievement
  ///
  /// In pt, this message translates to:
  /// **'Completei o {world} no MENTAL! 🎉'**
  String shareWorldCompletedMessage(String world);

  /// Share text for level up achievement
  ///
  /// In pt, this message translates to:
  /// **'Alcancei o Nível {level} no MENTAL! 🚀'**
  String shareLevelUpMessage(int level);

  /// Share text for badge unlocked achievement
  ///
  /// In pt, this message translates to:
  /// **'Desbloqueei a conquista \"{badge}\" no MENTAL! 🏅'**
  String shareBadgeUnlockedMessage(String badge);

  /// Share text for movement daily goal achievement
  ///
  /// In pt, this message translates to:
  /// **'Bati minha meta de passos no MENTAL e ganhei XP de bônus! 🚶💪'**
  String get shareMovementGoalMessage;

  /// Snackbar shown after sharing when the daily share-XP reward is granted
  ///
  /// In pt, this message translates to:
  /// **'+{xp} XP por compartilhar!'**
  String shareXpRewardedMessage(int xp);

  /// Button to share the invite code via WhatsApp/social apps
  ///
  /// In pt, this message translates to:
  /// **'Indicar'**
  String get friendsInviteShareButton;

  /// Share text for inviting a friend with the invite code
  ///
  /// In pt, this message translates to:
  /// **'Bora treinar a mente comigo? Baixe o MENTAL e use meu código de convite: {code}'**
  String friendsInviteShareMessage(String code);

  /// Countdown timer label in Palavras Relâmpago mode
  ///
  /// In pt, this message translates to:
  /// **'{seconds}s'**
  String relampagoSecondsRemainingLabel(int seconds);

  /// Soft feedback shown when the countdown runs out without an answer
  ///
  /// In pt, this message translates to:
  /// **'Quase lá! Tenta de novo'**
  String get relampagoTimedOutFeedback;

  /// Shown when a fast correct answer earns a speed bonus
  ///
  /// In pt, this message translates to:
  /// **'+{xp} XP de bônus de velocidade! ⚡'**
  String relampagoSpeedBonusMessage(int xp);

  /// Button/toggle label to start Palavras in lightning (multiple choice with timer) mode
  ///
  /// In pt, this message translates to:
  /// **'⚡ Relâmpago'**
  String get relampagoModeLabel;

  /// Generic back button label
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get backButton;

  /// Home app bar icon tooltip for the battles screen
  ///
  /// In pt, this message translates to:
  /// **'Batalhas'**
  String get battlesTooltip;

  /// Battles screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Batalhas'**
  String get battlesScreenTitle;

  /// Button on a friend row to challenge them to a battle
  ///
  /// In pt, this message translates to:
  /// **'Desafiar'**
  String get battleChallengeButton;

  /// Battle creation dialog title
  ///
  /// In pt, this message translates to:
  /// **'Desafiar {nickname}'**
  String battleDialogTitle(String nickname);

  /// Territory picker label in battle creation dialog
  ///
  /// In pt, this message translates to:
  /// **'Território'**
  String get battleDialogTerritoryLabel;

  /// Difficulty picker label in battle creation dialog
  ///
  /// In pt, this message translates to:
  /// **'Nível de dificuldade'**
  String get battleDialogDifficultyLabel;

  /// Send button in battle creation dialog
  ///
  /// In pt, this message translates to:
  /// **'Enviar desafio'**
  String get battleDialogSendButton;

  /// Shown when the daily battle send limit is reached
  ///
  /// In pt, this message translates to:
  /// **'Você já enviou o máximo de desafios hoje. Volte amanhã!'**
  String get battleDailyLimitReachedMessage;

  /// Empty state for the battles list
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma batalha ainda. Desafie um amigo na tela de Amigos!'**
  String get battlesEmptyMessage;

  /// Battle row status when it's the current user's turn to answer
  ///
  /// In pt, this message translates to:
  /// **'Sua vez de responder'**
  String get battleStatusPendingWaitingMe;

  /// Battle row status when waiting for the opponent to answer
  ///
  /// In pt, this message translates to:
  /// **'Aguardando {nickname} responder'**
  String battleStatusPendingWaitingOpponent(String nickname);

  /// Battle row status when the current user won
  ///
  /// In pt, this message translates to:
  /// **'Você venceu! +{xp} XP'**
  String battleStatusWon(int xp);

  /// Battle row status when the current user lost
  ///
  /// In pt, this message translates to:
  /// **'{nickname} levou essa'**
  String battleStatusLost(String nickname);

  /// Battle row status on a tie
  ///
  /// In pt, this message translates to:
  /// **'Empate — os dois erraram'**
  String get battleStatusTie;

  /// Button to answer a pending battle challenge
  ///
  /// In pt, this message translates to:
  /// **'Responder'**
  String get battleAnswerButton;

  /// Celebration message when the user becomes the territory detentor among friends
  ///
  /// In pt, this message translates to:
  /// **'Você assumiu {territory} entre seus amigos! 🏰'**
  String territoryDetentorGainedMessage(String territory);

  /// Caption under a territory button showing the current detentor among friends
  ///
  /// In pt, this message translates to:
  /// **'Detentor: {nickname}'**
  String territoryDetentorLabel(String nickname);

  /// Caption under a territory button when the current user is the detentor
  ///
  /// In pt, this message translates to:
  /// **'Você é o detentor'**
  String get territoryDetentorIsMeLabel;

  /// Share text for territory detentor achievement
  ///
  /// In pt, this message translates to:
  /// **'Assumi {territory} entre meus amigos no MENTAL! 🏰'**
  String shareTerritoryDetentorMessage(String territory);

  /// Home app bar icon tooltip for the profile screen
  ///
  /// In pt, this message translates to:
  /// **'Perfil'**
  String get profileTooltip;

  /// Profile screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Meu Perfil'**
  String get profileScreenTitle;

  /// Profile photo section title
  ///
  /// In pt, this message translates to:
  /// **'Foto de perfil'**
  String get profilePhotoSectionTitle;

  /// Button to pick a new profile photo
  ///
  /// In pt, this message translates to:
  /// **'Escolher foto'**
  String get profilePhotoChangeButton;

  /// Shown while the uploaded photo awaits moderation
  ///
  /// In pt, this message translates to:
  /// **'Sua foto está em análise — só fica visível pra outros usuários depois de aprovada.'**
  String get profilePhotoPendingLabel;

  /// Shown when the uploaded photo was rejected by moderation
  ///
  /// In pt, this message translates to:
  /// **'Sua foto foi rejeitada na moderação. Envie outra.'**
  String get profilePhotoRejectedLabel;

  /// Generic error message when photo upload fails
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível enviar a foto. Tente novamente.'**
  String get profilePhotoUploadError;

  /// Real name field label
  ///
  /// In pt, this message translates to:
  /// **'Nome real'**
  String get profileRealNameLabel;

  /// Helper text explaining real name is now public
  ///
  /// In pt, this message translates to:
  /// **'Aparece publicamente ao lado da sua foto de perfil, em Ranking, Amigos e Batalhas.'**
  String get profileRealNameHelperText;

  /// Location section title
  ///
  /// In pt, this message translates to:
  /// **'Localização (opcional)'**
  String get profileLocationSectionTitle;

  /// State field label
  ///
  /// In pt, this message translates to:
  /// **'Estado'**
  String get profileLocationStateLabel;

  /// Country field label
  ///
  /// In pt, this message translates to:
  /// **'País'**
  String get profileLocationCountryLabel;

  /// Toggle to make location public
  ///
  /// In pt, this message translates to:
  /// **'Mostrar meu estado/país no perfil'**
  String get profileLocationPublicLabel;

  /// Save profile button
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get profileSaveButton;

  /// Snackbar shown after saving the profile
  ///
  /// In pt, this message translates to:
  /// **'Perfil salvo!'**
  String get profileSavedMessage;

  /// Login screen title (brand wordmark)
  ///
  /// In pt, this message translates to:
  /// **'MENTAL'**
  String get loginTitle;

  /// Brand slogan, BRAND.md §2 — always near the name on first contact
  ///
  /// In pt, this message translates to:
  /// **'Mental é quem conquista com a mente.'**
  String get loginSlogan;

  /// Email field label
  ///
  /// In pt, this message translates to:
  /// **'E-mail'**
  String get loginEmailLabel;

  /// Password field label
  ///
  /// In pt, this message translates to:
  /// **'Senha'**
  String get loginPasswordLabel;

  /// Sign in button
  ///
  /// In pt, this message translates to:
  /// **'Entrar'**
  String get loginSignInButton;

  /// Sign up button
  ///
  /// In pt, this message translates to:
  /// **'Criar conta'**
  String get loginSignUpButton;

  /// Link to switch to sign-up mode
  ///
  /// In pt, this message translates to:
  /// **'Ainda não tem conta? Criar uma'**
  String get loginToggleToSignUp;

  /// Link to switch to sign-in mode
  ///
  /// In pt, this message translates to:
  /// **'Já tem conta? Entrar'**
  String get loginToggleToSignIn;

  /// Shown after sign-up when email confirmation is required
  ///
  /// In pt, this message translates to:
  /// **'Conta criada! Confira seu e-mail para confirmar antes de entrar.'**
  String get loginCheckEmailMessage;

  /// Validation error when email or password is empty
  ///
  /// In pt, this message translates to:
  /// **'Preencha e-mail e senha.'**
  String get loginMissingFieldsError;

  /// Sign out button in settings screen
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get settingsSignOutButton;

  /// Delete account button in settings screen
  ///
  /// In pt, this message translates to:
  /// **'Excluir minha conta'**
  String get settingsDeleteAccountButton;

  /// Title of the account deletion confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Excluir sua conta?'**
  String get settingsDeleteAccountConfirmTitle;

  /// Body of the account deletion confirmation dialog
  ///
  /// In pt, this message translates to:
  /// **'Isso apaga permanentemente seu perfil, progresso, amigos e foto de perfil. Não é possível desfazer.'**
  String get settingsDeleteAccountConfirmMessage;

  /// Confirm button inside the account deletion dialog
  ///
  /// In pt, this message translates to:
  /// **'Excluir permanentemente'**
  String get settingsDeleteAccountConfirmButton;

  /// Cancel button inside the account deletion dialog
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get settingsDeleteAccountCancelButton;

  /// Shown when account deletion is not available in this environment (ACCOUNT_DELETION_UNAVAILABLE)
  ///
  /// In pt, this message translates to:
  /// **'Exclusão de conta indisponível no momento. Tente novamente mais tarde ou entre em contato pelo e-mail de suporte.'**
  String get settingsDeleteAccountUnavailableError;

  /// Google OAuth sign-in button
  ///
  /// In pt, this message translates to:
  /// **'Continuar com Google'**
  String get loginGoogleButton;

  /// Facebook OAuth sign-in button
  ///
  /// In pt, this message translates to:
  /// **'Continuar com Facebook'**
  String get loginFacebookButton;

  /// Divider text between OAuth buttons and email/password form
  ///
  /// In pt, this message translates to:
  /// **'ou'**
  String get loginOrDivider;

  /// Mandatory onboarding screen title
  ///
  /// In pt, this message translates to:
  /// **'Antes de começar'**
  String get onboardingTitle;

  /// Mandatory onboarding screen subtitle
  ///
  /// In pt, this message translates to:
  /// **'Só algumas informações básicas — leva menos de um minuto.'**
  String get onboardingSubtitle;

  /// Mandatory onboarding name field label
  ///
  /// In pt, this message translates to:
  /// **'Nome'**
  String get onboardingNameLabel;

  /// Mandatory onboarding country field label
  ///
  /// In pt, this message translates to:
  /// **'País'**
  String get onboardingCountryLabel;

  /// Mandatory onboarding city field label
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get onboardingCityLabel;

  /// Mandatory onboarding gender section title
  ///
  /// In pt, this message translates to:
  /// **'Gênero'**
  String get onboardingGenderTitle;

  /// Onboarding gender section title, revised 28/08/2026 to be optional
  ///
  /// In pt, this message translates to:
  /// **'Gênero (opcional)'**
  String get onboardingGenderOptionalTitle;

  /// Mandatory onboarding photo section title, added 28/08/2026
  ///
  /// In pt, this message translates to:
  /// **'Foto de perfil'**
  String get onboardingPhotoTitle;

  /// Button label once a photo has already been picked during onboarding
  ///
  /// In pt, this message translates to:
  /// **'Trocar foto'**
  String get onboardingPhotoChosenLabel;

  /// Gender option
  ///
  /// In pt, this message translates to:
  /// **'Masculino'**
  String get onboardingGenderMasculino;

  /// Gender option
  ///
  /// In pt, this message translates to:
  /// **'Feminino'**
  String get onboardingGenderFeminino;

  /// Gender option
  ///
  /// In pt, this message translates to:
  /// **'Não-binário'**
  String get onboardingGenderNaoBinario;

  /// Gender option
  ///
  /// In pt, this message translates to:
  /// **'Prefiro não informar'**
  String get onboardingGenderPrefiroNaoInformar;

  /// Mandatory onboarding age range section title
  ///
  /// In pt, this message translates to:
  /// **'Faixa etária'**
  String get onboardingAgeRangeTitle;

  /// Mandatory onboarding submit button
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get onboardingContinueButton;

  /// Menu item to open the general feedback screen
  ///
  /// In pt, this message translates to:
  /// **'Feedback'**
  String get feedbackMenuTooltip;

  /// General feedback screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'Feedback'**
  String get feedbackScreenTitle;

  /// General feedback screen intro text
  ///
  /// In pt, this message translates to:
  /// **'Conta pra gente o que você acha do MENTAL — sugestão, elogio ou algo que travou. Sua opinião ajuda a melhorar o app.'**
  String get feedbackScreenIntro;

  /// General feedback comment field hint
  ///
  /// In pt, this message translates to:
  /// **'Escreva aqui...'**
  String get feedbackCommentHint;

  /// General feedback submit button
  ///
  /// In pt, this message translates to:
  /// **'Enviar'**
  String get feedbackSendButton;

  /// Confirmation message after sending general feedback
  ///
  /// In pt, this message translates to:
  /// **'Feedback enviado! Obrigado por ajudar a melhorar o MENTAL. 🙌'**
  String get feedbackSentMessage;

  /// Bottom navigation label for the Home destination
  ///
  /// In pt, this message translates to:
  /// **'Início'**
  String get homeNavLabel;

  /// Bottom navigation label for the overflow menu (Friends/Battles/Profile/Settings/Feedback)
  ///
  /// In pt, this message translates to:
  /// **'Mais'**
  String get moreNavLabel;

  /// MentalCoins quick action / badge label
  ///
  /// In pt, this message translates to:
  /// **'MentalCoins'**
  String get mentalCoinsTooltip;

  /// MentalCoins screen app bar title
  ///
  /// In pt, this message translates to:
  /// **'MentalCoins'**
  String get mentalCoinsScreenTitle;

  /// Note about when the current weekly cycle closes and restarts
  ///
  /// In pt, this message translates to:
  /// **'Ciclo iniciado em {start} · fecha em {end}'**
  String mentalCoinsCycleNote(String end, String start);

  /// Section title explaining how to earn MentalCoins this week
  ///
  /// In pt, this message translates to:
  /// **'Como ganhar essa semana'**
  String get mentalCoinsHowToEarnTitle;

  /// Daily XP ranking reward track label
  ///
  /// In pt, this message translates to:
  /// **'Top 3 de XP do dia'**
  String get mentalCoinsXpDailyLabel;

  /// Daily XP ranking reward values
  ///
  /// In pt, this message translates to:
  /// **'1º: 10 · 2º: 5 · 3º: 3'**
  String get mentalCoinsXpDailyValue;

  /// Weekly steps champion reward track label
  ///
  /// In pt, this message translates to:
  /// **'Campeão da semana em passos'**
  String get mentalCoinsStepsWeekLabel;

  /// Weekly steps champion reward value
  ///
  /// In pt, this message translates to:
  /// **'+20 MentalCoins'**
  String get mentalCoinsStepsWeekValue;

  /// Daily steps record reward track label
  ///
  /// In pt, this message translates to:
  /// **'Recordista do dia em passos'**
  String get mentalCoinsStepsDayLabel;

  /// Daily steps record reward value
  ///
  /// In pt, this message translates to:
  /// **'+10 MentalCoins'**
  String get mentalCoinsStepsDayValue;

  /// Hall of fame section title
  ///
  /// In pt, this message translates to:
  /// **'Hall da Fama da semana'**
  String get mentalCoinsHallOfFameTitle;

  /// Empty state for hall of fame when no cycle has closed yet
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma semana fechada ainda — os vencedores aparecem aqui a partir do primeiro fechamento de ciclo.'**
  String get mentalCoinsHallOfFameEmpty;

  /// Redemption catalog section title
  ///
  /// In pt, this message translates to:
  /// **'Resgatar'**
  String get mentalCoinsRedeemTitle;

  /// Label shown on an already-redeemed catalog item
  ///
  /// In pt, this message translates to:
  /// **'Resgatado'**
  String get mentalCoinsRedeemedLabel;

  /// Redeem button on a catalog item
  ///
  /// In pt, this message translates to:
  /// **'Resgatar'**
  String get mentalCoinsRedeemButton;

  /// Snackbar shown after a successful redemption
  ///
  /// In pt, this message translates to:
  /// **'Item resgatado!'**
  String get mentalCoinsRedeemSuccessMessage;

  /// Error shown when balance is not enough to redeem an item
  ///
  /// In pt, this message translates to:
  /// **'Saldo insuficiente para resgatar este item.'**
  String get mentalCoinsInsufficientBalanceError;

  /// Section title for the public feedback wall
  ///
  /// In pt, this message translates to:
  /// **'Comentários da comunidade'**
  String get feedbackMyHistoryTitle;

  /// Label shown above an admin's reply to a feedback
  ///
  /// In pt, this message translates to:
  /// **'Resposta da equipe'**
  String get feedbackAdminReplyLabel;

  /// Badge shown on the current user's own feedback entry in the public wall
  ///
  /// In pt, this message translates to:
  /// **'Você'**
  String get feedbackMineLabel;

  /// Empty state for the public feedback wall
  ///
  /// In pt, this message translates to:
  /// **'Nenhum feedback ainda. Seja o primeiro a comentar!'**
  String get adminFeedbackEmptyMessage;

  /// Button to reply to a feedback
  ///
  /// In pt, this message translates to:
  /// **'Responder'**
  String get adminFeedbackReplyButton;

  /// Button to edit an existing reply
  ///
  /// In pt, this message translates to:
  /// **'Editar resposta'**
  String get adminFeedbackEditReplyButton;

  /// Reply dialog title
  ///
  /// In pt, this message translates to:
  /// **'Responder feedback'**
  String get adminFeedbackReplyDialogTitle;

  /// Reply dialog text field hint
  ///
  /// In pt, this message translates to:
  /// **'Escreva sua resposta...'**
  String get adminFeedbackReplyHint;

  /// Reply dialog send button
  ///
  /// In pt, this message translates to:
  /// **'Enviar resposta'**
  String get adminFeedbackReplySendButton;

  /// Daily goal chip: light tier (5000 steps)
  ///
  /// In pt, this message translates to:
  /// **'5k'**
  String get movementGoalChipLight;

  /// Daily goal chip: standard tier (10000 steps)
  ///
  /// In pt, this message translates to:
  /// **'10k'**
  String get movementGoalChipStandard;

  /// Daily goal chip: intense tier (15000 steps)
  ///
  /// In pt, this message translates to:
  /// **'15k'**
  String get movementGoalChipIntense;

  /// Sub-label under the light goal chip
  ///
  /// In pt, this message translates to:
  /// **'leve'**
  String get movementGoalChipLightLabel;

  /// Sub-label under the standard goal chip
  ///
  /// In pt, this message translates to:
  /// **'padrão'**
  String get movementGoalChipStandardLabel;

  /// Sub-label under the intense goal chip
  ///
  /// In pt, this message translates to:
  /// **'intenso'**
  String get movementGoalChipIntenseLabel;

  /// Daily goal selector section title
  ///
  /// In pt, this message translates to:
  /// **'Sua meta diária'**
  String get movementGoalSelectorTitle;

  /// Daily goal selector section subtitle
  ///
  /// In pt, this message translates to:
  /// **'define seu ritmo de XP'**
  String get movementGoalSelectorSubtitle;

  /// Steps-today stat label in the hero block
  ///
  /// In pt, this message translates to:
  /// **'passos hoje'**
  String get movementStepsTodayLabel;

  /// XP-today stat label in the hero block
  ///
  /// In pt, this message translates to:
  /// **'XP conquistado'**
  String get movementXpTodayLabel;

  /// Explicit steps-to-XP conversion rule shown in the hero block
  ///
  /// In pt, this message translates to:
  /// **'A cada 100 passos = +2 XP'**
  String get movementConversionRuleText;

  /// Live badge on the progress ring
  ///
  /// In pt, this message translates to:
  /// **'AO VIVO'**
  String get movementLiveLabel;

  /// Peak label for the intraday chart summary
  ///
  /// In pt, this message translates to:
  /// **'pico'**
  String get movementPeakLabel;

  /// Valley label for the intraday chart summary
  ///
  /// In pt, this message translates to:
  /// **'vale'**
  String get movementValleyLabel;

  /// Confirm button that applies the selected/custom daily goal and starts tracking against it
  ///
  /// In pt, this message translates to:
  /// **'Ir'**
  String get movementGoalGoButton;

  /// Short placeholder shown inside the editable custom-goal chip before the user types a value
  ///
  /// In pt, this message translates to:
  /// **'livre'**
  String get movementCustomGoalHint;

  /// Sub-label under the editable custom-goal chip (the 4th, editable slot in the daily goal selector)
  ///
  /// In pt, this message translates to:
  /// **'sua meta'**
  String get movementGoalChipCustomLabel;

  /// Sub-label shown on a goal chip when its step threshold has been reached today, indicating a tap collects instead of changing the goal
  ///
  /// In pt, this message translates to:
  /// **'toque p/ coletar'**
  String get movementGoalChipCollectHint;

  /// Explanation shown above the camera/gallery choice, before the system camera permission prompt appears
  ///
  /// In pt, this message translates to:
  /// **'Sua foto de perfil é obrigatória e passa por moderação antes de aparecer para outros jogadores. Escolha como enviar:'**
  String get photoSourceExplanation;

  /// Bottom sheet option to take a new photo with the camera
  ///
  /// In pt, this message translates to:
  /// **'Tirar foto'**
  String get photoSourceCameraOption;

  /// Bottom sheet option to pick an existing photo from the gallery
  ///
  /// In pt, this message translates to:
  /// **'Escolher da galeria'**
  String get photoSourceGalleryOption;

  /// Title of the native photo crop editor screen
  ///
  /// In pt, this message translates to:
  /// **'Ajustar foto'**
  String get photoCropToolbarTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
