import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/word_constellation_screen.dart';
import 'package:mental/services/tts_service.dart';

/// MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md — Fase 2. Prova que os dois
/// tipos de rodada (`pieces`/`meaning`) renderizam e respondem
/// corretamente, sem depender de rede real de TTS (o botão de áudio
/// nunca é tocado no teste — mesma cautela já usada nos testes de
/// challenge_screen_tts_test.dart).
class _PiecesFakeApiClient extends ApiClient {
  _PiecesFakeApiClient()
      : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> wordConstellationRound(
          String challengeId) async =>
      {
        'challenge_id': challengeId,
        'territory_id': 'ingles_basico',
        'kind': 'pieces',
        'prompt_text': 'The house is big',
        'tiles': ['is', 'The', 'big', 'house', 'cat'],
        'options': null,
      };

  @override
  Future<Map<String, dynamic>> completeWordConstellation(
    String challengeId, {
    List<String>? submittedOrder,
    String? submittedMeaning,
  }) async {
    final correct = submittedOrder?.join(' ') == 'The house is big';
    return {'correct': correct, 'xp_awarded': correct ? 5 : 0};
  }
}

class _MeaningFakeApiClient extends ApiClient {
  _MeaningFakeApiClient()
      : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> wordConstellationRound(
          String challengeId) async =>
      {
        'challenge_id': challengeId,
        'territory_id': 'ingles_basico',
        'kind': 'meaning',
        // Áudio nas opções (20/09/2026): enunciado em português, opções
        // são palavras do idioma estudado, cada uma com som.
        'prompt_text': 'casa',
        'tiles': null,
        'options': ['House', 'Cat', 'Dog'],
      };

  @override
  Future<Map<String, dynamic>> completeWordConstellation(
    String challengeId, {
    List<String>? submittedOrder,
    String? submittedMeaning,
  }) async {
    final correct = submittedMeaning == 'House';
    return {'correct': correct, 'xp_awarded': correct ? 5 : 0};
  }
}

class _MeaningWithImageFakeApiClient extends _MeaningFakeApiClient {
  @override
  Future<Map<String, dynamic>> wordConstellationRound(
          String challengeId) async =>
      {
        ...await super.wordConstellationRound(challengeId),
        'vocab_media_url': 'https://example.invalid/house.webp',
        'vocab_media_source_name': 'Twemoji (jdecked) — CC-BY 4.0',
      };
}

Future<void> _pump(WidgetTester tester, ApiClient client,
    {int? difficultyLevel}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: WordConstellationScreen(
        client: client,
        challengeId: 'fake-id',
        territoryId: 'ingles_basico',
        difficultyLevel: difficultyLevel,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  // Tocar numa opção agora fala a palavra antes de responder — no teste
  // não há player de áudio real (mesma cautela de challenge_screen_tts_test).
  setUpAll(() => TtsService.disabled = true);

  testWidgets(
      'imagem de vocabulário vem com o crédito da licença (CC-BY exige atribuição)',
      (tester) async {
    await _pump(tester, _MeaningWithImageFakeApiClient());
    expect(find.byKey(const Key('vocab_media_credit')), findsOneWidget);
    expect(find.textContaining('CC-BY 4.0'), findsOneWidget);
  });

  testWidgets('sem imagem, sem legenda de crédito', (tester) async {
    await _pump(tester, _MeaningFakeApiClient());
    expect(find.byKey(const Key('vocab_media_credit')), findsNothing);
  });

  testWidgets(
      'rodada "pieces": cada peça tem o próprio botão de áudio (pedido de Rhoney, 19/09/2026)',
      (tester) async {
    await _pump(tester, _PiecesFakeApiClient());

    // Sem botão de som no topo (20/09/2026): só as 5 peças disponíveis
    // (is/The/big/house/cat), nenhuma ainda escolhida — 5 alto-falantes.
    expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(5));

    await tester.tap(find.text('The'));
    await tester.pump();
    // Peça movida pra área de montagem continua com o próprio áudio —
    // still 5 (4 disponíveis + 1 escolhida).
    expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(5));
  });

  testWidgets(
      'rodada "pieces": peça na área de montagem tem um "x" explícito pra remover (pedido de Rhoney, 19/09/2026)',
      (tester) async {
    await _pump(tester, _PiecesFakeApiClient());

    expect(find.byIcon(Icons.close_rounded), findsNothing);

    await tester.tap(find.text('The'));
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    // Voltou pra área de disponíveis.
    expect(find.text('The'), findsOneWidget);
  });

  testWidgets(
      'rodada "meaning": o som está nas opções (palavras), nunca no topo (pedido de Rhoney, 20/09/2026)',
      (tester) async {
    await _pump(tester, _MeaningFakeApiClient());

    // 3 opções, 3 alto-falantes; o topo (significado em português) e as
    // velocidades Normal/Rápido/Acelerado não existem mais.
    expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(3));
    expect(find.text('Normal'), findsNothing);
    expect(find.text('casa'), findsOneWidget);
  });

  testWidgets('rodada "pieces": montar na ordem certa mostra acerto + XP',
      (tester) async {
    await _pump(tester, _PiecesFakeApiClient());

    expect(find.text('The house is big'), findsOneWidget);
    await tester.tap(find.text('The'));
    await tester.pump();
    await tester.tap(find.text('house'));
    await tester.pump();
    await tester.tap(find.text('is'));
    await tester.pump();
    await tester.tap(find.text('big'));
    await tester.pump();

    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    expect(find.text('Isso mesmo!'), findsOneWidget);
    expect(find.text('+5 XP'), findsOneWidget);
  });

  testWidgets('rodada "pieces": ordem errada permite tentar de novo, sem XP',
      (tester) async {
    await _pump(tester, _PiecesFakeApiClient());

    await tester.tap(find.text('big'));
    await tester.pump();
    await tester.tap(find.text('The'));
    await tester.pump();

    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    expect(find.text('Quase — tente de novo.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pump();
    expect(find.text('Verificar'), findsOneWidget);
  });

  testWidgets(
      'difficultyLevel < 3 (basico/intermediario): instrução em português aparece (MUNDO_IDIOMAS_IMERSAO_PROGRESSIVA_V1.md)',
      (tester) async {
    await _pump(tester, _PiecesFakeApiClient(), difficultyLevel: 2);
    expect(find.text('Toque para ouvir e monte a resposta'), findsOneWidget);
  });

  testWidgets(
      'difficultyLevel 3 (avancado/Difícil): instrução em português some — imersão total',
      (tester) async {
    await _pump(tester, _PiecesFakeApiClient(), difficultyLevel: 3);
    expect(find.text('Toque para ouvir e monte a resposta'), findsNothing);
  });

  testWidgets(
      'rodada "meaning": tocar na opção certa já responde e mostra acerto (sem botão Verificar)',
      (tester) async {
    await _pump(tester, _MeaningFakeApiClient());

    expect(find.text('casa'), findsOneWidget);
    expect(find.text('House'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
    // Pedido de Rhoney (19/09/2026): na rodada "meaning" tocar na opção
    // já responde — nunca existe um botão "Verificar" separado aqui.
    expect(find.text('Verificar'), findsNothing);

    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();

    expect(find.text('Isso mesmo!'), findsOneWidget);
  });

  testWidgets(
      'rodada "meaning": tocar na opção errada já responde e mostra erro',
      (tester) async {
    await _pump(tester, _MeaningFakeApiClient());

    await tester.tap(find.text('Cat'));
    await tester.pumpAndSettle();

    expect(find.text('Quase — tente de novo.'), findsOneWidget);
  });
}
