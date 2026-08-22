import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/challenge_screen.dart';

/// Regressão para BUGS_TEST_REPORT_01.md — Bug 1.
///
/// Causa raiz confirmada: o TextField do desafio sem múltipla escolha
/// atualizava `_selectedOption` sem `setState()`, então o botão
/// "Confirmar resposta" (que depende de `_selectedOption != null`)
/// continuava desabilitado na renderização até algum OUTRO evento (ex.:
/// pedir dica) forçar um rebuild. Este teste prova que digitar sozinho,
/// sem nenhuma outra interação, já habilita o botão.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-challenge-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': "Reordene as letras 'SALCA' para formar uma palavra.",
      'options': null,
      'hints_available': 2,
    };
  }
}

/// CONHECIMENTO_EXPANSAO_GERAL.md (aprovado 2026-08-22): em Conhecimento
/// o formato com tempo é OBRIGATÓRIO, então o servidor manda
/// time_limit_seconds mesmo com mode="normal" (nenhum botão dedicado
/// pede isso, diferente de Palavras Relâmpago). A tela precisa renderizar
/// o formato cronometrado a partir desse sinal do servidor, não de um
/// flag local — prova a generalização de widget.relampago para
/// _timeLimitMs != null em _buildChallenge.
class _ConhecimentoFakeApiClient extends ApiClient {
  _ConhecimentoFakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-challenge-id-conhecimento',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Qual é a capital do Brasil?',
      'options': ['Rio de Janeiro', 'São Paulo', 'Brasília', 'Salvador'],
      'hints_available': 0,
      'time_limit_seconds': 12,
      'prompt_image': '🏛️',
    };
  }
}

/// Simula um desafio do território "textos" (V2 item 3) — parágrafo-base
/// bem mais longo que qualquer enunciado dos territórios anteriores, com
/// múltipla escolha, para provar que a tela não estoura (RenderFlex
/// overflow) num viewport pequeno.
class _LongPromptFakeApiClient extends ApiClient {
  _LongPromptFakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-challenge-id-textos',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': List.filled(20, 'Um parágrafo bem longo para testar o scroll da tela de desafio.').join(' '),
      'options': ['Opção A', 'Opção B', 'Opção C', 'Opção D'],
      'hints_available': 2,
    };
  }
}

/// Simula um desafio do território "visual" (V2 item 4) — opções em
/// formato "forma_preenchimento_cor_índice", sem nenhuma imagem real.
class _VisualFakeApiClient extends ApiClient {
  _VisualFakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-challenge-id-visual',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Qual figura é diferente das outras?',
      'options': ['circle_filled_gold_1', 'circle_filled_gold_2', 'square_filled_gold_3', 'circle_filled_gold_4'],
      'hints_available': 2,
    };
  }

  @override
  Future<Map<String, dynamic>> submitAnswer(String challengeId, String attemptId, String submittedAnswer, {int? responseTimeMs, bool timedOut = false}) async {
    return {
      'is_correct': true,
      'correct_answer': 'square_filled_gold_3',
      'explanation': 'As outras três são círculos dourados preenchidos.',
      'xp_awarded': 10,
      'xp_base': 10,
      'hints_used': 0,
      'streak': {'current_streak': 1, 'freeze_available': true},
    };
  }
}

/// Simula um desafio simples cuja resposta carrega sinais de celebração
/// configuráveis (MICROINTERACTIONS.md) — o backend é a única autoridade
/// sobre esses sinais, então o client só precisa saber renderizá-los.
class _CelebrationFakeApiClient extends ApiClient {
  _CelebrationFakeApiClient({required this.answerPayload}) : super(baseUrl: 'http://fake', userId: 'fake-user');

  final Map<String, dynamic> answerPayload;

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-challenge-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Quanto é 2 + 2?',
      'options': ['3', '4', '5', '6'],
      'hints_available': 2,
    };
  }

  @override
  Future<Map<String, dynamic>> submitAnswer(String challengeId, String attemptId, String submittedAnswer, {int? responseTimeMs, bool timedOut = false}) async {
    return answerPayload;
  }
}

Map<String, dynamic> _baseAnswerPayload() => {
      'is_correct': true,
      'correct_answer': '4',
      'explanation': '2 + 2 = 4.',
      'xp_awarded': 10,
      'xp_base': 10,
      'hints_used': 0,
      'streak': {'current_streak': 1, 'freeze_available': true},
      'level_up': false,
      'new_level': null,
      'territory_just_conquered': false,
      'world_just_completed': false,
      'completed_world_name': null,
      'world_completion_bonus_xp': 0,
      'streak_just_extended': false,
      'newly_awarded_badges': <Map<String, dynamic>>[],
    };

Future<void> _pumpChallengeScreen(
  WidgetTester tester,
  ApiClient client, {
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      // MediaQueryData(disableAnimations: ...) sozinho zera "size" (usa o
      // construtor default) — quebrava o cálculo de posição dos balões,
      // que depende de um tamanho de tela real. fromView() preserva o
      // tamanho real do ambiente de teste, só sobrescrevendo o campo que
      // este teste de fato quer controlar.
      data: MediaQueryData.fromView(tester.view).copyWith(disableAnimations: disableAnimations),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChallengeScreen(client: client, territoryId: 'numeros', territoryLabel: 'Números'),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(RadioListTile<String>, '4'));
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Confirmar resposta'));
  // Não usar pumpAndSettle() aqui: com uma celebração forte ativa,
  // ConfettiWidget mantém partículas vivas por um tempo e o balão sobe por
  // 2.8s — pumpAndSettle() esperaria tudo isso "assentar" e estourava por
  // timeout (achado real rodando os testes). O texto do resultado (e dos
  // banners de celebração) já está presente no primeiro frame após o
  // Future de submitAnswer() resolver, independente da animação ainda
  // estar rodando — não precisamos esperar a celebração terminar pra
  // verificar o texto.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets(
    'botão "Confirmar resposta" habilita ao digitar, sem precisar de outra interação (regressão Bug 1)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _FakeApiClient(),
            territoryId: 'palavras',
            territoryLabel: 'Palavras',
          ),
        ),
      );
      await tester.pumpAndSettle();

      FilledButton confirmButton() =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar resposta'));

      expect(confirmButton().onPressed, isNull, reason: 'antes de digitar, deve estar desabilitado');

      await tester.enterText(find.byType(TextField), 'CASAL');
      await tester.pump();

      expect(
        confirmButton().onPressed,
        isNotNull,
        reason: 'ao digitar, o botão deve habilitar imediatamente — sem precisar de outra ação (ex.: pedir dica)',
      );
    },
  );

  testWidgets(
    'parágrafo-base longo (território "textos") não estoura a tela (regressão overflow)',
    (tester) async {
      // Viewport pequeno de propósito — telas de aparelho de entrada
      // (ex.: Moto G22) têm menos altura útil que o padrão de teste.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _LongPromptFakeApiClient(),
            territoryId: 'textos',
            territoryLabel: 'Textos',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        errors.where((e) => e.exception.toString().contains('RenderFlex overflowed')),
        isEmpty,
        reason: 'parágrafo-base longo não pode causar overflow — a área de conteúdo precisa ser rolável',
      );
    },
  );

  testWidgets(
    'território "visual" renderiza ícones selecionáveis, não texto (V2 item 4)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _VisualFakeApiClient(),
            territoryId: 'visual',
            territoryLabel: 'Visual',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 opções visuais, cada uma com o ícone correto — a string bruta
      // da opção (ex.: "circle_filled_gold_1") nunca deve aparecer como
      // texto na tela, só o ícone decodificado.
      expect(find.byIcon(Icons.circle), findsNWidgets(3));
      expect(find.byIcon(Icons.square), findsOneWidget);
      expect(find.text('circle_filled_gold_1'), findsNothing);

      FilledButton confirmButton() =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar resposta'));
      expect(confirmButton().onPressed, isNull, reason: 'antes de tocar numa figura, deve estar desabilitado');

      await tester.tap(find.byIcon(Icons.square));
      await tester.pump();

      expect(confirmButton().onPressed, isNotNull, reason: 'ao tocar numa figura, o botão deve habilitar');
    },
  );

  testWidgets(
    'resultado do território "visual" mostra descrição legível, não o id bruto da opção (regressão)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _VisualFakeApiClient(),
            territoryId: 'visual',
            territoryLabel: 'Visual',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.square));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar resposta'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('square_filled_gold_3'),
        findsNothing,
        reason: 'o id interno da opção nunca deve aparecer cru na tela de resultado',
      );
      expect(find.textContaining('quadrado dourado'), findsOneWidget);
    },
  );

  testWidgets(
    'Conhecimento renderiza o formato com tempo sem precisar de relampago:true (CONHECIMENTO_EXPANSAO_GERAL.md)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _ConhecimentoFakeApiClient(),
            territoryId: 'conhecimento',
            territoryLabel: 'Conhecimento',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Qual é a capital do Brasil?'), findsOneWidget);
      expect(find.text('Brasília'), findsOneWidget);
      expect(find.textContaining('12s'), findsOneWidget, reason: 'contagem regressiva do servidor deve aparecer mesmo sem relampago:true');
      // CONHECIMENTO_CONTEUDO_GERAL_E_IMAGEM.md §3 — prompt_image opcional
      // do servidor aparece junto com a pergunta, quando presente.
      expect(find.text('🏛️'), findsOneWidget);
      // Formato cronometrado usa OutlinedButton por opção, nunca o
      // TextField digitado nem o botão "Confirmar resposta" separado.
      expect(find.byType(TextField), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Confirmar resposta'), findsNothing);
    },
  );

  group('sinais de celebração (MICROINTERACTIONS.md)', () {
    testWidgets('level_up mostra "Nível X alcançado!"', (tester) async {
      final payload = _baseAnswerPayload()
        ..['level_up'] = true
        ..['new_level'] = 3;
      await _pumpChallengeScreen(tester, _CelebrationFakeApiClient(answerPayload: payload));

      expect(find.text('Nível 3 alcançado!'), findsOneWidget);
      // Celebração forte pedida: confete caindo + 2 "fogos" (explosão
      // radial) — 3 ConfettiWidget no total, não só 1.
      expect(find.byType(ConfettiWidget), findsNWidgets(3));
    });

    testWidgets('level_up mostra botão de compartilhar a conquista', (tester) async {
      final payload = _baseAnswerPayload()
        ..['level_up'] = true
        ..['new_level'] = 3;
      await _pumpChallengeScreen(tester, _CelebrationFakeApiClient(answerPayload: payload));

      expect(find.text('Compartilhar'), findsOneWidget);
      // Tocar não pode lançar exceção mesmo sem app de compartilhamento
      // disponível no ambiente de teste (ShareService.share nunca deixa
      // a falha escapar, mesmo princípio de FeedbackService/PushService).
      await tester.tap(find.text('Compartilhar'));
      await tester.pump();
    });

    testWidgets('territory_just_conquered mostra "Território conquistado!"', (tester) async {
      final payload = _baseAnswerPayload()..['territory_just_conquered'] = true;
      await _pumpChallengeScreen(tester, _CelebrationFakeApiClient(answerPayload: payload));

      expect(find.text('Território conquistado!'), findsOneWidget);
    });

    testWidgets('world_just_completed mostra "{mundo} completo! +{xp} XP de bônus"', (tester) async {
      final payload = _baseAnswerPayload()
        ..['world_just_completed'] = true
        ..['completed_world_name'] = 'Mundo da Linguagem'
        ..['world_completion_bonus_xp'] = 100;
      await _pumpChallengeScreen(tester, _CelebrationFakeApiClient(answerPayload: payload));

      expect(find.text('Mundo da Linguagem completo! +100 XP de bônus'), findsOneWidget);
    });

    testWidgets('newly_awarded_badges mostra "Nova conquista: {nome}!"', (tester) async {
      final payload = _baseAnswerPayload()
        ..['newly_awarded_badges'] = [
          {'code': 'first_conquest', 'name': 'Primeira Conquista', 'description': '...', 'earned': true, 'earned_at': '2026-01-01'},
        ];
      await _pumpChallengeScreen(tester, _CelebrationFakeApiClient(answerPayload: payload));

      expect(find.text('Nova conquista: Primeira Conquista!'), findsOneWidget);
    });

    testWidgets('streak_just_extended mostra "Sequência de X dias mantida!"', (tester) async {
      final payload = _baseAnswerPayload()
        ..['streak_just_extended'] = true
        ..['streak'] = {'current_streak': 5, 'freeze_available': true};
      await _pumpChallengeScreen(tester, _CelebrationFakeApiClient(answerPayload: payload));

      expect(find.text('Sequência de 5 dias mantida!'), findsOneWidget);
    });

    testWidgets('nenhum sinal ativo não mostra nenhum banner de celebração', (tester) async {
      await _pumpChallengeScreen(tester, _CelebrationFakeApiClient(answerPayload: _baseAnswerPayload()));

      expect(find.textContaining('alcançado!'), findsNothing);
      expect(find.textContaining('conquistado!'), findsNothing);
      expect(find.textContaining('Nova conquista'), findsNothing);
      expect(find.textContaining('mantida!'), findsNothing);
    });

    testWidgets('"reduzir movimento" ativado não quebra a tela de celebração forte', (tester) async {
      // Regressão: MediaQuery.of() dentro de PulseIn.initState() lançava
      // "dependOnInheritedWidgetOfExactType called before initState()
      // completed" — corrigido movendo a leitura para didChangeDependencies.
      final payload = _baseAnswerPayload()
        ..['level_up'] = true
        ..['new_level'] = 2;
      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      await _pumpChallengeScreen(
        tester,
        _CelebrationFakeApiClient(answerPayload: payload),
        disableAnimations: true,
      );

      expect(errors, isEmpty, reason: '"reduzir movimento" não pode causar exceção ao celebrar um evento forte');
      expect(find.text('Nível 2 alcançado!'), findsOneWidget);
    });
  });
}
