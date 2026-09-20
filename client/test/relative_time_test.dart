import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/relative_time.dart';

void main() {
  testWidgets('formatRelativeTime trata o horário do servidor como UTC',
      (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (context) {
        l10n = AppLocalizations.of(context)!;
        return const SizedBox();
      }),
    ));
    final now = DateTime.utc(2026, 9, 20, 12, 0);
    expect(formatRelativeTime(l10n, '2026-09-20T11:59:30', now: now),
        l10n.feedTimeJustNow);
    expect(formatRelativeTime(l10n, '2026-09-20T11:30:00', now: now),
        l10n.feedTimeMinutesAgo(30));
    expect(formatRelativeTime(l10n, '2026-09-20T09:00:00Z', now: now),
        l10n.feedTimeHoursAgo(3));
    expect(formatRelativeTime(l10n, '2026-09-18T12:00:00', now: now),
        l10n.feedTimeDaysAgo(2));
  });
}
