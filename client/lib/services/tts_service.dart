import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_edge_tts/flutter_edge_tts.dart';

/// MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md (18/09/2026) — áudio fiel de
/// pronúncia para o Mundo dos Idiomas, via `flutter_edge_tts` (gratuito,
/// MIT, motor de síntese neural do Edge). Validado tecnicamente antes de
/// integrar (síntese real testada em en-US/es-ES/fr-FR, ~22KB de MP3
/// válido cada, sem erro/instabilidade na primeira rodada — nenhum
/// sinal de rate limiting encontrado até agora; se aparecer em uso real,
/// reportar a Rhoney pra avaliar `flutter_tts` nativo como contingência,
/// conforme o próprio documento já previu).
///
/// Reproduz sempre sob demanda (nunca automático — decisão do documento)
/// e reaproveita o `audioplayers` já usado pelo Ouvido Afiado
/// (challenge_screen.dart), em vez de introduzir um 2º player de áudio.
enum TtsSpeed { normal, fast, veryFast }

extension TtsSpeedSsmlRate on TtsSpeed {
  /// Valor de `rate` do SSML (EdgeTtsProsody) — "1.0" é velocidade
  /// normal de fala; os outros dois são acelerações relativas, não
  /// velocidades absolutas.
  String get ssmlRate => switch (this) {
        TtsSpeed.normal => '1.0',
        TtsSpeed.fast => '1.3',
        TtsSpeed.veryFast => '1.6',
      };
}

class TtsService {
  TtsService._();
  static final TtsService instance = TtsService._();

  final AudioPlayer _player = AudioPlayer();
  bool _speaking = false;
  bool get isSpeaking => _speaking;

  // Pedido de Rhoney (19/09/2026): "o áudio ... está com uma certa
  // demora, ajuste para que seja ao toque" — a demora é o round-trip de
  // síntese via rede a cada toque. Cache em memória (texto+voz+
  // velocidade → MP3 já sintetizado) elimina essa espera em qualquer
  // repetição (reabrir a mesma pergunta, tocar o mesmo botão de novo).
  // LRU simples por tamanho — nunca precisa sobreviver entre sessões.
  static const int _cacheMaxEntries = 80;
  final LinkedHashMap<String, Uint8List> _cache = LinkedHashMap();
  final Set<String> _preloading = {};

  String _cacheKey(String text, String voice, TtsSpeed speed) => '$voice|${speed.name}|$text';

  void _cacheStore(String key, Uint8List bytes) {
    _cache.remove(key);
    _cache[key] = bytes;
    while (_cache.length > _cacheMaxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<Uint8List?> _synthesize(String text, String voice, TtsSpeed speed) async {
    final tts = FlutterEdgeTts(voice: voice);
    try {
      final result = await tts.synthesize(text, prosody: EdgeTtsProsody(rate: speed.ssmlRate));
      return result.audioBytes;
    } catch (_) {
      return null;
    } finally {
      await tts.close();
    }
  }

  /// Sintetiza e guarda em cache em segundo plano, SEM tocar nada —
  /// nunca viola a regra de "áudio só sob clique explícito" (documento
  /// MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md). Chamar assim que a pergunta ou
  /// rodada carrega, pra quando o usuário realmente tocar o botão, o
  /// áudio já estar pronto (cache hit) em vez de esperar a rede.
  void preload(String text, {required String voice, TtsSpeed speed = TtsSpeed.normal}) {
    if (text.trim().isEmpty) return;
    final key = _cacheKey(text, voice, speed);
    if (_cache.containsKey(key) || _preloading.contains(key)) return;
    _preloading.add(key);
    unawaited(
      _synthesize(text, voice, speed).then((bytes) {
        if (bytes != null) _cacheStore(key, bytes);
        _preloading.remove(key);
      }),
    );
  }

  /// Só pra testes de widget: síntese real usaria rede de verdade.
  @visibleForTesting
  static bool disabled = false;

  /// Toca e só devolve quando o áudio TERMINOU (ou após `maxWait`, ou
  /// se a síntese/reprodução falhar) — pedido de Rhoney (19/09/2026):
  /// no Relâmpago a tela seguinte só aparece depois do som. Nunca
  /// trava: qualquer falha ou demora além do limite libera o fluxo.
  Future<bool> speakAndWait(
    String text, {
    required String voice,
    TtsSpeed speed = TtsSpeed.normal,
    Duration maxWait = const Duration(seconds: 6),
  }) async {
    if (disabled) return false;
    final completed = Completer<void>();
    StreamSubscription<void>? sub;
    try {
      sub = _player.onPlayerComplete.listen((_) {
        if (!completed.isCompleted) completed.complete();
      });
      final ok = await speak(text, voice: voice, speed: speed);
      if (ok) await completed.future.timeout(maxWait, onTimeout: () {});
      return ok;
    } catch (_) {
      return false;
    } finally {
      await sub?.cancel();
    }
  }

  /// `voice` é o nome curto da voz neural do Edge (ex.:
  /// "en-US-AriaNeural") — a estrutura é genérica por design (§2.3 do
  /// documento): quem chama decide idioma/voz, nada fica fixo aqui.
  /// Retorna `false` em qualquer falha (rede, síntese, playback) — quem
  /// chama decide como comunicar isso ao usuário, este serviço nunca
  /// lança exceção pro chamador.
  Future<bool> speak(String text, {required String voice, TtsSpeed speed = TtsSpeed.normal}) async {
    if (disabled || _speaking || text.trim().isEmpty) return false;
    _speaking = true;
    try {
      final key = _cacheKey(text, voice, speed);
      final cached = _cache[key];
      final bytes = cached ?? await _synthesize(text, voice, speed);
      if (bytes == null) return false;
      if (cached == null) _cacheStore(key, bytes);
      await _player.stop();
      await _player.play(BytesSource(bytes));
      return true;
    } catch (_) {
      return false;
    } finally {
      _speaking = false;
    }
  }
}
