import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_service.dart' show TtsSpeed;

/// Leitor manual de enunciados dos Mundos (exceto Idiomas) — MENTAL_LEITOR_
/// PERGUNTAS_FEEDBACK_SONORO_V1.1.md, aprovado por Rhoney em 25/09/2026.
/// Motor NATIVO/local do Android (flutter_tts), diferente do TtsService de
/// Idiomas (flutter_edge_tts, online). Só leitura manual do enunciado, sem
/// autoplay; falha de áudio nunca bloqueia a resposta, o avanço ou a saída.

/// Interface do motor, pra a UI e o texto poderem ser testados sem plugin nativo.
abstract class PromptSpeaker {
  ValueListenable<bool> get speaking;
  ValueListenable<bool> get failed;
  Future<void> speak(String text, {required TtsSpeed speed});
  Future<void> stop();
}

/// Trata números, fórmulas, siglas e pontuação pra fala (só o que é seguro trocar).
String prepareForSpeech(String prompt) {
  var t = prompt.replaceAll('\r', '');
  // Lacunas ("___") viram uma pausa falada clara.
  t = t.replaceAll(RegExp(r'_{2,}'), ' lacuna ');
  t = t
      .replaceAll('×', ' vezes ')
      .replaceAll('÷', ' dividido por ')
      .replaceAll('√', ' raiz quadrada de ')
      .replaceAll('%', ' por cento')
      .replaceAll('≠', ' diferente de ')
      .replaceAll('≤', ' menor ou igual a ')
      .replaceAll('≥', ' maior ou igual a ');
  // Operadores entre números ("2 + 3", "5 - 1", "4 = 4") — só quando cercados por dígitos.
  t = t.replaceAllMapped(RegExp(r'(\d)\s*\+\s*(?=\d)'), (m) => '${m[1]} mais ');
  t = t.replaceAllMapped(RegExp(r'(\d)\s*=\s*(?=\d)'), (m) => '${m[1]} igual a ');
  t = t.replaceAllMapped(RegExp(r'(\d)\s+-\s+(?=\d)'), (m) => '${m[1]} menos ');
  // Quebras de parágrafo viram pausa; espaços repetidos somem.
  t = t.replaceAllMapped(RegExp(r'([.!?:;])[ \t]*\n{2,}'), (m) => '${m[1]} ');
  t = t.replaceAll(RegExp(r'\n{2,}'), '. ').replaceAll('\n', ' ');
  return t.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
}

class NativePromptSpeaker implements PromptSpeaker {
  NativePromptSpeaker._();
  static final NativePromptSpeaker instance = NativePromptSpeaker._();

  final FlutterTts _tts = FlutterTts();
  final ValueNotifier<bool> _speaking = ValueNotifier(false);
  final ValueNotifier<bool> _failed = ValueNotifier(false);
  bool _ready = false;
  List<String> _voiceNames = const [];
  int _spoken = 0;

  @override
  ValueListenable<bool> get speaking => _speaking;
  @override
  ValueListenable<bool> get failed => _failed;

  // Taxa nativa do Android: 0.5 é a velocidade normal do plugin; as três
  // velocidades seguem a mesma proporção de Idiomas (1.0x / 1.3x / 1.6x).
  static double rateFor(TtsSpeed speed) => switch (speed) {
        TtsSpeed.normal => 0.5,
        TtsSpeed.fast => 0.65,
        TtsSpeed.veryFast => 0.8,
      };

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _tts.setLanguage('pt-BR');
    await _tts.setPitch(1.0);
    _tts.setCompletionHandler(() => _speaking.value = false);
    _tts.setCancelHandler(() => _speaking.value = false);
    _tts.setErrorHandler((_) {
      _speaking.value = false;
      _failed.value = true;
    });
    // Vozes pt-BR locais instaladas (o app não deixa o jogador escolher voz).
    try {
      final voices = await _tts.getVoices as List?;
      _voiceNames = [
        for (final v in voices ?? const [])
          if (v is Map &&
              (v['locale']?.toString().toLowerCase().replaceAll('_', '-') ?? '') == 'pt-br' &&
              v['network_required']?.toString() != '1' &&
              v['name'] != null)
            v['name'].toString()
      ]..sort();
    } catch (_) {
      _voiceNames = const [];
    }
    _ready = true;
  }

  @override
  Future<void> speak(String text, {required TtsSpeed speed}) async {
    try {
      _failed.value = false;
      await _ensureReady();
      final prepared = prepareForSpeech(text);
      if (prepared.isEmpty) return;
      await _tts.stop();
      await _tts.setSpeechRate(rateFor(speed));
      // Alterna entre as vozes locais disponíveis a cada leitura; com uma só
      // (ou nenhuma detectável), usa a melhor disponível — inteligibilidade
      // vem antes de variedade.
      if (_voiceNames.length >= 2) {
        final name = _voiceNames[_spoken % _voiceNames.length];
        await _tts.setVoice({'name': name, 'locale': 'pt-BR'});
      }
      _spoken++;
      _speaking.value = true;
      await _tts.speak(prepared);
    } catch (_) {
      _speaking.value = false;
      _failed.value = true;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking.value = false;
  }
}
