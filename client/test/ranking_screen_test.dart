import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/ranking_screen.dart';

/// RANKING_ENRIQUECIDO_V1.md — cada linha do Ranking mostra streak,
/// mundos completos, badges, MentalCoins e passos, além do que já
/// existia (posição, avatar, nome, XP). 1º lugar tem destaque visual.
class _RankingFakeApiClient extends ApiClient {
  _RankingFakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> ranking({String scope = 'global', String window = 'weekly'}) async {
    final entries = [
      {
        'rank': 1,
        'user_id': 'u1',
        'nickname': 'Rhoney',
        'avatar_id': null,
        'real_name': null,
        'photo_url': null,
        'xp': 6232,
        'level': 82,
        'current_streak': 11,
        'worlds_completed': 4,
        'worlds_total': 5,
        'badges_count': 9,
        'mentalcoins_balance': 40,
        'total_steps': 8400,
      },
      {
        'rank': 2,
        'user_id': 'u2',
        'nickname': 'Eduardo',
        'avatar_id': null,
        'real_name': null,
        'photo_url': null,
        'xp': 2620,
        'level': 51,
        'current_streak': 6,
        'worlds_completed': 2,
        'worlds_total': 5,
        'badges_count': 4,
        'mentalcoins_balance': 18,
        'total_steps': 5100,
      },
    ];
    return {
      'window': window,
      'entries': entries,
      'me': entries[0],
    };
  }
}

Future<void> _pumpRankingScreen(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: RankingScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('linha do 1º lugar mostra coroa e as 5 badges de conquista', (tester) async {
    await _pumpRankingScreen(tester, _RankingFakeApiClient());

    expect(find.text('👑'), findsOneWidget);
    expect(find.textContaining('Rhoney'), findsOneWidget);
    expect(find.text('🔥 11'), findsOneWidget);
    expect(find.text('🌍 4/5'), findsOneWidget);
    expect(find.text('🏆 9'), findsOneWidget);
    expect(find.text('40'), findsOneWidget);
    expect(find.text('👟 8.4k'), findsOneWidget);
  });

  testWidgets('dica de interação aparece no topo da lista', (tester) async {
    await _pumpRankingScreen(tester, _RankingFakeApiClient());

    expect(find.text('Toque em qualquer jogador para ver o desempenho completo'), findsOneWidget);
  });

  testWidgets('segunda linha (não sou eu) mostra chevron indicando que é tocável', (tester) async {
    await _pumpRankingScreen(tester, _RankingFakeApiClient());

    expect(find.textContaining('Eduardo'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
