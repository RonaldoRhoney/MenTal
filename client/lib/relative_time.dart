import 'l10n/generated/app_localizations.dart';

/// "há 2 dias", "há 5 min"… a partir de um instante UTC vindo do servidor
/// (ISO com ou sem "Z" — o backend manda naive UTC). Mesmas strings do
/// Feed de atividade (feedTime*).
String formatRelativeTime(AppLocalizations l10n, String isoUtc,
    {DateTime? now}) {
  final created = DateTime.parse(isoUtc.endsWith('Z') ? isoUtc : '${isoUtc}Z');
  final diff = (now ?? DateTime.now().toUtc()).difference(created);
  if (diff.inMinutes < 1) return l10n.feedTimeJustNow;
  if (diff.inHours < 1) return l10n.feedTimeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.feedTimeHoursAgo(diff.inHours);
  return l10n.feedTimeDaysAgo(diff.inDays);
}
