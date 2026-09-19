import 'package:audioplayers/audioplayers.dart';
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

  /// `voice` é o nome curto da voz neural do Edge (ex.:
  /// "en-US-AriaNeural") — a estrutura é genérica por design (§2.3 do
  /// documento): quem chama decide idioma/voz, nada fica fixo aqui.
  /// Retorna `false` em qualquer falha (rede, síntese, playback) — quem
  /// chama decide como comunicar isso ao usuário, este serviço nunca
  /// lança exceção pro chamador.
  Future<bool> speak(String text, {required String voice, TtsSpeed speed = TtsSpeed.normal}) async {
    if (_speaking || text.trim().isEmpty) return false;
    _speaking = true;
    final tts = FlutterEdgeTts(voice: voice);
    try {
      final result = await tts.synthesize(text, prosody: EdgeTtsProsody(rate: speed.ssmlRate));
      await _player.stop();
      await _player.play(BytesSource(result.audioBytes));
      return true;
    } catch (_) {
      return false;
    } finally {
      await tts.close();
      _speaking = false;
    }
  }
}
