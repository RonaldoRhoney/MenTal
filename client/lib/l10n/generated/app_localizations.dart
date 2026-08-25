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
  /// **'Novo desafio — {territory}'**
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

  /// Steps detected locally but not yet submitted to the backend
  ///
  /// In pt, this message translates to:
  /// **'{steps} passos detectados agora, ainda não coletados'**
  String movementDetectedStepsLabel(int steps);

  /// Button to submit detected steps to the backend
  ///
  /// In pt, this message translates to:
  /// **'Coletar passos'**
  String get movementCollectButton;

  /// Shown when there are no new steps to collect
  ///
  /// In pt, this message translates to:
  /// **'Nenhum passo novo pra coletar agora.'**
  String get movementNoStepsToCollect;

  /// Previous cycle still within the grace window, pending final collection
  ///
  /// In pt, this message translates to:
  /// **'Você ainda tem um ciclo anterior com {steps} passos pra coletar!'**
  String movementPendingReportLabel(int steps);

  /// Button to do the final collection of the previous cycle
  ///
  /// In pt, this message translates to:
  /// **'Coletar ciclo anterior'**
  String get movementCollectPreviousButton;

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

  /// Empty state for the friends list
  ///
  /// In pt, this message translates to:
  /// **'Você ainda não tem amigos adicionados. Compartilhe seu código ou cole o código de alguém.'**
  String get friendsEmptyMessage;

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

  /// Avatar picker section title
  ///
  /// In pt, this message translates to:
  /// **'Avatar'**
  String get profileAvatarSectionTitle;

  /// Real name field label
  ///
  /// In pt, this message translates to:
  /// **'Nome real (opcional)'**
  String get profileRealNameLabel;

  /// Helper text explaining real name is never public
  ///
  /// In pt, this message translates to:
  /// **'Nunca aparece publicamente — só uso interno, ex.: suporte. Seu apelido já te identifica no jogo.'**
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
