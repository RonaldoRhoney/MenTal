import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/services/prompt_reader_service.dart';
import 'package:mental/services/tts_service.dart' show TtsSpeed;
import 'package:mental/widgets/prompt_reader_bar.dart';

/// MENTAL_LEITOR_PERGUNTAS_FEEDBACK_SONORO_V1.1.md (aprovado 25/09/2026): leitor
/// MANUAL do enunciado, sem autoplay, três velocidades persistidas, falha nunca
/// bloqueia, e fora de Idiomas/Libras.
class _FakeSpeaker implements PromptSpeaker {
  final ValueNotifier<bool> _speaking = ValueNotifier(false);
  final ValueNotifier<bool> _failed = ValueNotifier(false);
  final List<(String, TtsSpeed)> spoken = [];
  int stops = 0;

  @override
  ValueListenable<bool> get speaking => _speaking;
  @override
  ValueListenable<bool> get failed => _failed;

  @override
  Future<void> speak(String text, {required TtsSpeed speed}) async {
    spoken.add((text, speed));
    _speaking.value = true;
  }

  @override
  Future<void> stop() async {
    stops++;
    _speaking.value = false;
  }
}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  test('leitor só vale fora de Idiomas e Libras', () {
    expect(promptReaderAppliesTo('palavras'), isTrue);
    expect(promptReaderAppliesTo('linguagem_crase'), isTrue);
    expect(promptReaderAppliesTo('concursos_direito'), isTrue);
    expect(promptReaderAppliesTo('ingles_basico'), isFalse);
    expect(promptReaderAppliesTo('espanhol_avancado'), isFalse);
    expect(promptReaderAppliesTo('frances_intermediario'), isFalse);
    expect(promptReaderAppliesTo('libras'), isFalse);
  });

  test('prepareForSpeech trata lacunas, símbolos e quebras de parágrafo', () {
    expect(prepareForSpeech('Complete: Ele foi ___ casa.'), 'Complete: Ele foi lacuna casa.');
    expect(prepareForSpeech('Quanto é 2 + 3 = 5?'), 'Quanto é 2 mais 3 igual a 5?');
    expect(prepareForSpeech('Quanto é 10 - 4?'), 'Quanto é 10 menos 4?');
    expect(prepareForSpeech('Calcule 6 × 7 e 20% de 50'), 'Calcule 6 vezes 7 e 20 por cento de 50');
    expect(prepareForSpeech('Texto longo.\n\nQual a ideia central?'), 'Texto longo. Qual a ideia central?');
    expect(prepareForSpeech('Texto sem ponto\n\nQual a ideia?'), 'Texto sem ponto. Qual a ideia?');
    // hífen de palavra composta e sinal em palavra não viram "menos"/"mais".
    expect(prepareForSpeech('guarda-chuva e C++'), 'guarda-chuva e C++');
  });

  testWidgets('sem autoplay: só fala ao toque e só o texto do enunciado', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final speaker = _FakeSpeaker();
    await tester.pumpWidget(_app(PromptReaderBar(text: 'Qual é a capital do Brasil?', speaker: speaker)));
    await tester.pumpAndSettle();
    expect(speaker.spoken, isEmpty);

    await tester.tap(find.byKey(const Key('prompt_reader_button')));
    await tester.pump();
    expect(speaker.spoken, [('Qual é a capital do Brasil?', TtsSpeed.normal)]);

    // Com a fala em andamento o mesmo botão para a leitura.
    await tester.tap(find.byKey(const Key('prompt_reader_button')));
    await tester.pump();
    expect(speaker.stops, 1);
  });

  testWidgets('as três velocidades chegam ao motor e a escolha é persistida', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final speaker = _FakeSpeaker();
    await tester.pumpWidget(_app(PromptReaderBar(text: 'Pergunta', speaker: speaker)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('prompt_reader_speed_veryFast')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('prompt_reader_button')));
    await tester.pump();
    expect(speaker.spoken.last.$2, TtsSpeed.veryFast);
    expect((await SharedPreferences.getInstance()).getString('prompt_reader_speed'), 'veryFast');

    // Nova instância (outra pergunta/sessão) começa na velocidade salva.
    final speaker2 = _FakeSpeaker();
    await tester.pumpWidget(_app(PromptReaderBar(key: UniqueKey(), text: 'Outra', speaker: speaker2)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('prompt_reader_button')));
    await tester.pump();
    expect(speaker2.spoken.last.$2, TtsSpeed.veryFast);
  });

  testWidgets('falha de áudio mostra aviso e não trava nada', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final speaker = _FakeSpeaker();
    await tester.pumpWidget(_app(PromptReaderBar(text: 'Pergunta', speaker: speaker)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('prompt_reader_error')), findsNothing);
    speaker._failed.value = true;
    await tester.pump();
    expect(find.byKey(const Key('prompt_reader_error')), findsOneWidget);
    // o botão continua funcionando
    await tester.tap(find.byKey(const Key('prompt_reader_button')));
    await tester.pump();
    expect(speaker.spoken, isNotEmpty);
  });

  testWidgets('sair da tela/trocar de pergunta interrompe a fala', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final speaker = _FakeSpeaker();
    await tester.pumpWidget(_app(PromptReaderBar(text: 'Pergunta', speaker: speaker)));
    await tester.pumpAndSettle();
    await tester.pumpWidget(_app(const SizedBox()));
    expect(speaker.stops, 1);
  });
}
