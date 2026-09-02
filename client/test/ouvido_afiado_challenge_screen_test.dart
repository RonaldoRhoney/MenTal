import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/challenge_screen.dart';

/// V4 — Ouvido Afiado (V4/V4_NOVOS_TERRITORIOS.md §3). Prova que a tela
/// mostra o botão de tocar áudio + o crédito de atribuição da fonte, e
/// que uma falha de reprodução nunca trava o resto do desafio.
class _OuvidoAfiadoFakeApiClient extends ApiClient {
  _OuvidoAfiadoFakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-ouvido-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Som 1: Que som é este?',
      'options': ['Latido de cachorro', 'Rosnado de lobo', 'Grunhido de porco', 'Miado de gato'],
      'hints_available': 2,
      'audio_url': 'https://upload.wikimedia.org/wikipedia/commons/a/a2/Barking_of_a_dog.ogg',
      'audio_source_name': 'Amada44 — CC BY-SA 3.0 — Wikimedia Commons',
      'audio_source_url': 'https://commons.wikimedia.org/wiki/File:Barking_of_a_dog.ogg',
    };
  }

  @override
  Future<Map<String, dynamic>> submitAnswer(String challengeId, String attemptId, String submittedAnswer, {int? responseTimeMs, bool timedOut = false}) async {
    return {
      'is_correct': submittedAnswer == 'Latido de cachorro',
      'correct_answer': 'Latido de cachorro',
      'explanation': 'O latido curto e repetido é característico do cachorro.',
      'xp_awarded': 10,
      'xp_base': 10,
      'hints_used': 0,
      'streak': {'current_streak': 1, 'freeze_available': true},
    };
  }
}

Future<void> _pump(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChallengeScreen(client: client, territoryId: 'ouvido_afiado', territoryLabel: 'Ouvido Afiado'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra o botão de tocar áudio, o prompt e o crédito da fonte', (tester) async {
    await _pump(tester, _OuvidoAfiadoFakeApiClient());

    expect(find.widgetWithText(FilledButton, 'Tocar som'), findsOneWidget);
    expect(find.text('Som 1: Que som é este?'), findsOneWidget);
    expect(find.textContaining('Amada44'), findsOneWidget);
  });

  testWidgets('tocar o áudio (sem platform channel real no ambiente de teste) nunca trava a tela nem impede responder', (tester) async {
    // O ambiente de widget test não tem uma implementação real de
    // platform channel para audioplayers — o objetivo aqui não é
    // travar o comportamento exato do plugin nessa condição (pode
    // silenciar, lançar ou nunca resolver, dependendo da versão), e
    // sim provar que _playChallengeAudio nunca deixa uma exceção
    // escapar pra cima e travar o resto da tela (mesmo princípio de
    // FeedbackService: som é reforço/conteúdo, nunca motivo de crash).
    final errors = <FlutterErrorDetails>[];
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) => errors.add(details);
    addTearDown(() => FlutterError.onError = originalOnError);

    await _pump(tester, _OuvidoAfiadoFakeApiClient());

    await tester.tap(find.widgetWithText(FilledButton, 'Tocar som'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(errors, isEmpty, reason: 'uma falha de reprodução de áudio nunca pode escapar como exceção não tratada');

    // Continua sendo possível responder normalmente mesmo com o áudio
    // indisponível — a falha de mídia nunca bloqueia o resto do desafio.
    await tester.tap(find.widgetWithText(RadioListTile<String>, 'Latido de cachorro'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar resposta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('característico do cachorro'), findsOneWidget);
  });
}
