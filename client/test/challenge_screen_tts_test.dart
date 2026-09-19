import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/challenge_screen.dart';

/// MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md §2 — prova que o botão de áudio
/// (TTS) + seletor de velocidade aparecem SÓ nos territórios de idioma
/// falado (idioma_voices.dart), nunca em territórios sem voz associada.
/// Não toca o áudio de verdade aqui (dispararia uma chamada de rede real
/// pro Edge TTS via flutter_edge_tts, que não usa platform channel e
/// rodaria de verdade num widget test) — a síntese real já foi validada
/// à parte, fora da suíte de testes (en-US/es-ES/fr-FR, MP3 válido).
class _IdiomasFakeApiClient extends ApiClient {
  _IdiomasFakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-ingles-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': "Como se escreve 'casa' em inglês?",
      'options': ['House', 'Horse', 'Hoase', 'Hose'],
      'hints_available': 2,
    };
  }
}

class _IdiomasRelampagoFakeApiClient extends ApiClient {
  _IdiomasRelampagoFakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-ingles-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': "Como se escreve 'casa' em inglês?",
      'options': ['House', 'Horse', 'Hoase', 'Hose'],
      'hints_available': 2,
      'time_limit_seconds': 10,
    };
  }

  @override
  Future<Map<String, dynamic>> submitAnswer(String challengeId, String attemptId, String submittedAnswer, {int? responseTimeMs, bool timedOut = false}) async {
    return {
      'is_correct': submittedAnswer == 'House',
      'correct_answer': 'House',
      'explanation': 'x',
      'xp_awarded': 3,
      'xp_base': 3,
      'hints_used': 0,
      'streak': {'current_streak': 1, 'freeze_available': true},
    };
  }
}

class _OuvidoAfiadoFakeApiClient extends ApiClient {
  _OuvidoAfiadoFakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-ouvido-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Que som é este?',
      'options': ['Latido', 'Rosnado', 'Grunhido', 'Miado'],
      'hints_available': 2,
    };
  }
}

Future<void> _pump(WidgetTester tester, ApiClient client, String territoryId, {bool relampago = false}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChallengeScreen(client: client, territoryId: territoryId, territoryLabel: 'Inglês Básico', relampago: relampago),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('território de idioma falado mostra botão de áudio por opção + seletor de velocidade', (tester) async {
    await _pump(tester, _IdiomasFakeApiClient(), 'ingles_basico');

    expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(4));
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Rápido'), findsOneWidget);
    expect(find.text('Acelerado'), findsOneWidget);
  });

  testWidgets('território sem idioma falado não mostra botão de áudio nem seletor de velocidade', (tester) async {
    await _pump(tester, _OuvidoAfiadoFakeApiClient(), 'ouvido_afiado');

    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.text('Rápido'), findsNothing);
  });

  testWidgets('Relâmpago em território de idioma falado também mostra botão de áudio por opção (pedido de Rhoney, 19/09/2026)', (tester) async {
    await _pump(tester, _IdiomasRelampagoFakeApiClient(), 'ingles_basico', relampago: true);

    expect(find.byIcon(Icons.volume_up_rounded), findsNWidgets(4));

    // Responder no Relâmpago continua funcionando normalmente mesmo com
    // o áudio wireado na mesma ação (nunca espera o áudio terminar nem
    // lança exceção).
    await tester.tap(find.text('House'));
    await tester.pumpAndSettle();
  });

  testWidgets('trocar a velocidade não afeta o resto da tela (Confirmar resposta continua funcionando)', (tester) async {
    await _pump(tester, _IdiomasFakeApiClient(), 'ingles_basico');

    await tester.tap(find.text('Rápido'));
    await tester.pump();

    await tester.tap(find.widgetWithText(RadioListTile<String>, 'House'));
    await tester.pump();
    expect(find.widgetWithText(FilledButton, 'Confirmar resposta'), findsOneWidget);
  });
}
