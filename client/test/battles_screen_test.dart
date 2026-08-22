import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/battles_screen.dart';
import 'package:mental/theme/app_theme.dart';

/// V2 item 14 — Batalha assíncrona. O backend é a autoridade sobre
/// status/vencedor (GET /battles) — esta tela só exibe.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.battles}) : super(baseUrl: 'http://fake', userId: 'fake-user');

  final List<Map<String, dynamic>> battles;

  @override
  Future<Map<String, dynamic>> listBattles() async => {'battles': battles};
}

Future<void> _pumpBattlesScreen(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: BattlesScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra mensagem de lista vazia quando não há batalhas', (tester) async {
    await _pumpBattlesScreen(tester, _FakeApiClient(battles: []));
    expect(find.textContaining('Nenhuma batalha'), findsOneWidget);
  });

  testWidgets('mostra botão de responder quando é minha vez', (tester) async {
    await _pumpBattlesScreen(
      tester,
      _FakeApiClient(battles: [
        {
          'battle_id': 'b1',
          'opponent_nickname': 'Fulano',
          'territory_id': 'palavras',
          'difficulty_level': 2,
          'role': 'opponent',
          'status': 'pending',
          'i_answered': false,
          'opponent_answered': true,
          'winner': null,
          'win_bonus_xp': 0,
        },
      ]),
    );

    expect(find.text('Responder'), findsOneWidget);
    expect(find.textContaining('Sua vez de responder'), findsOneWidget);
  });

  testWidgets('mostra resultado de vitória sem botão de responder', (tester) async {
    await _pumpBattlesScreen(
      tester,
      _FakeApiClient(battles: [
        {
          'battle_id': 'b2',
          'opponent_nickname': 'Fulano',
          'territory_id': 'numeros',
          'difficulty_level': 3,
          'role': 'challenger',
          'status': 'resolved',
          'i_answered': true,
          'opponent_answered': true,
          'winner': 'me',
          'win_bonus_xp': 30,
        },
      ]),
    );

    expect(find.textContaining('Você venceu'), findsOneWidget);
    expect(find.text('Responder'), findsNothing);
  });
}
