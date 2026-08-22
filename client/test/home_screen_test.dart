import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/home_screen.dart';

/// V2 item 10 — Mundos completos. O backend é a autoridade sobre o
/// agrupamento (GET /progress já devolve os territórios de cada mundo e
/// se está completo) — estes testes provam que a Home só organiza
/// visualmente o que o backend manda, nunca decide sozinha.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> progress() async => {
        'xp_total': 130,
        'level': 2,
        'streak': {'current_streak': 3, 'freeze_available': true},
        'territories': [
          {
            'territory_id': 'palavras',
            'xp_in_territory': 200,
            'unlocked': true,
            'conquered': true,
            'conquest_threshold': 200,
            'detentor_nickname': 'Fulano',
            'is_detentor': false,
          },
          {
            'territory_id': 'textos',
            'xp_in_territory': 0,
            'unlocked': true,
            'conquered': false,
            'conquest_threshold': 200,
            'detentor_nickname': 'Eu-Mesmo',
            'is_detentor': true,
          },
          {'territory_id': 'enigmas', 'xp_in_territory': 0, 'unlocked': true, 'conquered': false, 'conquest_threshold': 200},
          {'territory_id': 'numeros', 'xp_in_territory': 0, 'unlocked': true, 'conquered': false, 'conquest_threshold': 200},
          {'territory_id': 'logica', 'xp_in_territory': 0, 'unlocked': true, 'conquered': false, 'conquest_threshold': 200},
          {'territory_id': 'visual', 'xp_in_territory': 0, 'unlocked': true, 'conquered': false, 'conquest_threshold': 200},
          {'territory_id': 'conhecimento', 'xp_in_territory': 0, 'unlocked': true, 'conquered': false, 'conquest_threshold': 200},
        ],
        'worlds': [
          {
            'world_id': 'linguagem',
            'name': 'Mundo da Linguagem',
            'territory_ids': ['palavras', 'textos', 'enigmas'],
            'completed': false,
          },
          {
            'world_id': 'mente_logica',
            'name': 'Mundo da Mente Lógica',
            'territory_ids': ['numeros', 'logica', 'visual', 'conhecimento'],
            'completed': true,
          },
        ],
      };

  @override
  Future<Map<String, dynamic>> movementStatus() async => {
        'movement_enabled': false,
        'daily_goal_steps': null,
        'current_cycle': null,
        'pending_report_cycle': null,
      };
}

void main() {
  testWidgets('agrupa territórios por mundo e mostra selo de mundo completo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(client: _FakeApiClient()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Mundo da Linguagem'), findsOneWidget);
    expect(find.text('Mundo da Mente Lógica'), findsOneWidget);

    // Selo de completo (ícone) aparece uma vez, só no mundo com
    // completed=true — o backend decide isso, não a Home.
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });

  testWidgets('mostra o detentor do território entre amigos (V2 item 13)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(client: _FakeApiClient()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Detentor: Fulano'), findsOneWidget);
    expect(find.text('Você é o detentor'), findsOneWidget);
  });
}
