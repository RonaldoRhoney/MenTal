import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/word_constellation_screen.dart';

/// MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md — Fase 2. Prova que os dois
/// tipos de rodada (`pieces`/`meaning`) renderizam e respondem
/// corretamente, sem depender de rede real de TTS (o botão de áudio
/// nunca é tocado no teste — mesma cautela já usada nos testes de
/// challenge_screen_tts_test.dart).
class _PiecesFakeApiClient extends ApiClient {
  _PiecesFakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> wordConstellationRound(String challengeId) async => {
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
  _MeaningFakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> wordConstellationRound(String challengeId) async => {
        'challenge_id': challengeId,
        'territory_id': 'ingles_basico',
        'kind': 'meaning',
        'prompt_text': 'House',
        'tiles': null,
        'options': ['casa', 'gato', 'cachorro'],
      };

  @override
  Future<Map<String, dynamic>> completeWordConstellation(
    String challengeId, {
    List<String>? submittedOrder,
    String? submittedMeaning,
  }) async {
    final correct = submittedMeaning == 'casa';
    return {'correct': correct, 'xp_awarded': correct ? 5 : 0};
  }
}

Future<void> _pump(WidgetTester tester, ApiClient client, {int? difficultyLevel}) async {
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
  testWidgets('rodada "pieces": cada peça tem o próprio botão de áudio (pedido de Rhoney, 19/09/2026)', (tester) async {
    await _pump(tester, _PiecesFakeApiClient());

    // 1 botão grande (frase inteira) + 5 peças disponíveis (is/The/big/
    // house/cat), nenhuma ainda escolhida — 6 ícones de alto-falante.
    expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(6));

    await tester.tap(find.text('The'));
    await tester.pump();
    // Peça movida pra área de montagem continua com o próprio áudio —
    // still 6 (1 grande + 4 disponíveis + 1 escolhida).
    expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(6));
  });

  testWidgets('rodada "meaning": opções (em português) NÃO têm botão de áudio próprio', (tester) async {
    await _pump(tester, _MeaningFakeApiClient());

    // Só o botão grande do topo — as 3 opções de significado nunca
    // ganham áudio individual (seria a voz errada, em português).
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('rodada "pieces": montar na ordem certa mostra acerto + XP', (tester) async {
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

  testWidgets('rodada "pieces": ordem errada permite tentar de novo, sem XP', (tester) async {
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

  testWidgets('difficultyLevel < 3 (basico/intermediario): instrução em português aparece (MUNDO_IDIOMAS_IMERSAO_PROGRESSIVA_V1.md)', (tester) async {
    await _pump(tester, _PiecesFakeApiClient(), difficultyLevel: 2);
    expect(find.text('Toque para ouvir e monte a resposta'), findsOneWidget);
  });

  testWidgets('difficultyLevel 3 (avancado/Difícil): instrução em português some — imersão total', (tester) async {
    await _pump(tester, _PiecesFakeApiClient(), difficultyLevel: 3);
    expect(find.text('Toque para ouvir e monte a resposta'), findsNothing);
  });

  testWidgets('rodada "meaning": escolher a opção certa mostra acerto', (tester) async {
    await _pump(tester, _MeaningFakeApiClient());

    expect(find.text('House'), findsOneWidget);
    expect(find.text('casa'), findsOneWidget);
    expect(find.text('gato'), findsOneWidget);

    await tester.tap(find.text('casa'));
    await tester.pump();
    await tester.tap(find.text('Verificar'));
    await tester.pumpAndSettle();

    expect(find.text('Isso mesmo!'), findsOneWidget);
  });
}
