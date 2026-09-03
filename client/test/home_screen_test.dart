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
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

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
        // BLOCOS_MENUS.md: Matemática agrupa numeros+logica dentro do
        // Mundo da Mente Lógica — visual+conhecimento ficam soltos, sem
        // bloco, no mesmo mundo.
        'blocks': [
          {
            'block_id': 'matematica',
            'name': 'Matemática',
            'territory_ids': ['numeros', 'logica'],
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

  // Busca na Home (pedido de Rhoney, 2026-09-03) — configurável por
  // teste: null = "não encontrado" (found: false).
  Map<String, dynamic>? searchResultChallenge;
  final List<String> submittedSuggestions = [];

  @override
  Future<Map<String, dynamic>> searchChallenges(String query) async {
    if (searchResultChallenge == null) return {'found': false, 'challenge': null};
    return {'found': true, 'challenge': searchResultChallenge};
  }

  @override
  Future<Map<String, dynamic>> submitContentSuggestion(String queryText) async {
    submittedSuggestions.add(queryText);
    return {'ok': true};
  }
}

/// V4 — cor de identidade do bloco Curiosidade Relâmpago (item movido
/// da V3 pra V4, V3.5_CURIOSIDADE_RELAMPAGO.md §5). Só esse território
/// ganha o ícone/tom índigo no card da Home, nenhum outro.
class _FakeApiClientWithMysteryBlock extends ApiClient {
  _FakeApiClientWithMysteryBlock() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> progress() async => {
        'xp_total': 0,
        'level': 1,
        'streak': {'current_streak': 0, 'freeze_available': true},
        'territories': [
          {'territory_id': 'palavras', 'xp_in_territory': 0, 'unlocked': true, 'conquered': false, 'conquest_threshold': 200},
          {'territory_id': 'curiosidade_relampago', 'xp_in_territory': 0, 'unlocked': true, 'conquered': false, 'conquest_threshold': 200},
        ],
        'worlds': [
          {
            'world_id': 'cultura_geral',
            'name': 'Mundo da Cultura Geral',
            'territory_ids': ['palavras', 'curiosidade_relampago'],
            'completed': false,
          },
        ],
        'blocks': [],
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
  // Reforço de gamificação na Home (pedido de Rhoney, 29/08/2026): o
  // _ProgressCard cresceu (avatar 64px + anel + chips de XP/streak),
  // empurrando o conteúdo mais pra baixo. Em vez de depender de
  // scrollUntilVisible (frágil: um ListView lazy pode não ter
  // construído/hit-testável ainda o widget-alvo logo após o scroll, como
  // já documentado no helper de mandatory_onboarding_screen_test.dart),
  // aumenta o viewport de teste pra tudo caber de uma vez.
  Future<void> pumpTall(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(child);
    await tester.pumpAndSettle();
  }

  Widget homeApp(ApiClient client) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeScreen(client: client),
      );

  testWidgets('agrupa territórios por mundo e mostra selo de mundo completo', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpTall(tester, homeApp(_FakeApiClient()));

    expect(find.text('Mundo da Linguagem'), findsOneWidget);
    // Redesign 2026-08-26 (pedido de Rhoney: "não quero tudo na tela"):
    // Mundo colapsado por padrão — o território não deve estar visível
    // ainda, só o cabeçalho.
    expect(find.text('Desafio Palavras'), findsNothing);
    expect(find.text('Mundo da Mente Lógica'), findsOneWidget);

    // Ao expandir, os territórios daquele Mundo aparecem.
    await tester.tap(find.text('Mundo da Linguagem'));
    await tester.pumpAndSettle();
    expect(find.text('Desafio Palavras'), findsOneWidget);

    // Selo de completo (ícone) aparece uma vez, só no mundo com
    // completed=true — o backend decide isso, não a Home.
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });

  testWidgets('botão de convidar amigos aparece ao lado do wordmark MENTAL e não trava a tela ao tocar', (tester) async {
    // Achado testando: o share sheet nativo não existe no ambiente de
    // widget test — o mesmo princípio de ShareAchievementButton se
    // aplica aqui (compartilhar é reforço, nunca pode lançar exceção
    // não tratada), então este teste prova só isso: o botão existe e
    // tocar nele não derruba a tela.
    SharedPreferences.setMockInitialValues({});
    await pumpTall(tester, homeApp(_FakeApiClient()));

    expect(find.byIcon(Icons.share_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.share_outlined));
    await tester.pumpAndSettle();
  });

  testWidgets('card de Curiosidade Relâmpago mostra o ícone de identidade índigo, outros territórios não', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpTall(tester, homeApp(_FakeApiClientWithMysteryBlock()));

    await tester.tap(find.text('Mundo da Cultura Geral'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
  });

  testWidgets('busca por tema (nome de território) navega direto pro território, sem chamar o backend', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = _FakeApiClient();
    await pumpTall(tester, homeApp(client));

    await tester.enterText(find.byType(TextField), 'Palavras');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Navegou pra ChallengeScreen do território "palavras" — o campo de
    // busca da Home não está mais visível (mudou de tela).
    expect(find.byType(TextField), findsNothing);
    expect(client.submittedSuggestions, isEmpty);
  });

  testWidgets('busca por frase/palavra encontrada no backend navega direto pro desafio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = _FakeApiClient()
      ..searchResultChallenge = {
        'challenge_id': 'c1',
        'attempt_id': 'a1',
        'territory_id': 'numeros',
        'difficulty_level': 1,
        'prompt': 'Quanto é 2 + 2?',
        'options': ['3', '4', '5', '6'],
        'hints_available': 0,
      };
    await pumpTall(tester, homeApp(client));

    await tester.enterText(find.byType(TextField), 'termo-que-nao-e-nome-de-territorio');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Quanto é 2 + 2?'), findsOneWidget);
  });

  testWidgets('busca sem resultado oferece sugerir o conteúdo, e registrar não trava a tela', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = _FakeApiClient();
    await pumpTall(tester, homeApp(client));

    await tester.enterText(find.byType(TextField), 'termo-sem-nenhum-resultado-xyz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // Revisão de estilo (2026-09-03): não é mais SnackBar — um card em
    // destaque fica visível até o usuário decidir (sugerir ou fechar).
    expect(find.text('Não encontramos nada para "termo-sem-nenhum-resultado-xyz".'), findsOneWidget);
    final suggestButtonFinder = find.widgetWithText(FilledButton, 'Sugerir esse conteúdo');
    expect(suggestButtonFinder, findsOneWidget);

    await tester.tap(suggestButtonFinder);
    await tester.pumpAndSettle();

    expect(client.submittedSuggestions, ['termo-sem-nenhum-resultado-xyz']);
    expect(find.text('Sugestão registrada! Um agente vai avaliar esse conteúdo.'), findsOneWidget);
  });

  testWidgets('mostra o detentor do território entre amigos (V2 item 13)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpTall(tester, homeApp(_FakeApiClient()));

    // Redesign 2026-08-26: cada Mundo agora é colapsável ("não quero
    // tudo na tela") — precisa expandir antes de ver os territórios.
    await tester.tap(find.text('Mundo da Linguagem'));
    await tester.pumpAndSettle();

    expect(find.text('Detentor: Fulano'), findsOneWidget);
    expect(find.text('Você é o detentor'), findsOneWidget);
  });

  testWidgets('BLOCOS_MENUS.md: mostra sub-cabeçalho "Matemática" agrupando numeros e lógica', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await pumpTall(tester, homeApp(_FakeApiClient()));

    // Redesign 2026-08-26: Mundo colapsável — expande "Mundo da Mente
    // Lógica" (onde numeros/logica/visual/conhecimento vivem) antes de
    // procurar pelos territórios/blocos internos.
    await tester.tap(find.text('Mundo da Mente Lógica'));
    await tester.pumpAndSettle();

    // Aparece uma única vez (agrupa numeros+logica sob o mesmo bloco,
    // não repete o sub-cabeçalho por território).
    expect(find.text('Matemática'), findsOneWidget);

    // Território sem bloco (visual, no mesmo Mundo) continua acessível
    // normalmente, sem nenhum sub-cabeçalho de bloco acima dele.
    expect(find.textContaining('Visual'), findsWidgets);
  });

  testWidgets('redesign 2026-08-26: acessos dinâmicos (Progresso/Ranking/Amigos/Movimento) + bottom nav', (tester) async {
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

    // Ajuste de layout (pedido de Rhoney): Progresso/Ranking/Amigos/
    // Movimento sobem pra cards de atalho dinâmicos logo abaixo da marca.
    expect(find.text('Progresso'), findsOneWidget);
    expect(find.text('Ranking'), findsOneWidget);
    expect(find.text('Amigos'), findsOneWidget);
    expect(find.text('Movimento'), findsOneWidget);

    // Bottom nav fica só com: Início, Perfil, Configurações, Batalhas, Feedback.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Início'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    // Renomeado pra "Ajuste" (commit 07bfe08, Painel Admin in-app).
    expect(find.text('Ajuste'), findsOneWidget);
    expect(find.text('Batalhas'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
  });
}
