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

  /// Neutral age gate question, FAMILY_SAFETY.md §3
  ///
  /// In pt, this message translates to:
  /// **'Antes de começar, qual é a sua idade?'**
  String get ageGateTitle;

  /// Age gate supporting text
  ///
  /// In pt, this message translates to:
  /// **'Isso ajuda a manter a experiência adequada para você.'**
  String get ageGateSubtitle;

  /// Age gate child option button
  ///
  /// In pt, this message translates to:
  /// **'Tenho menos de 18 anos'**
  String get ageGateChildOption;

  /// Age gate adult option button
  ///
  /// In pt, this message translates to:
  /// **'Tenho 18 anos ou mais'**
  String get ageGateAdultOption;

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
