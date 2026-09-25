import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// MENTAL LINGO — reconhecimento de fala (MUNDO/Mundo_dos_Idiomas/
/// Mental_Lingo/MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md, aprovado por
/// Rhoney, 23/09/2026 — escopo V1 100% custo zero). Envolve o pacote
/// `speech_to_text`, que por baixo usa o SpeechRecognizer NATIVO do
/// Android — gratuito, roda no aparelho, sem nenhuma chamada de nuvem
/// paga (prioridade "gratuito primeiro" do documento, §Opções de
/// Speech-to-Text). O áudio bruto nunca sai do aparelho nem chega ao
/// backend — só o TEXTO já transcrito (ver api_client.askMentalLingo).
class MentalLingoService {
  MentalLingoService._();
  static final MentalLingoService instance = MentalLingoService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;

  bool get isListening => _speech.isListening;

  /// Inicializa o reconhecedor (pede a permissão de microfone na
  /// PRIMEIRA vez, de forma contextual — nunca no onboarding genérico,
  /// mesmo princípio já usado pra ACTIVITY_RECOGNITION/CAMERA).
  /// Idempotente: chamadas seguintes reaproveitam a mesma instância.
  /// `onStatus` recebe "listening" | "notListening" | "done" — é o
  /// sinal usado pela tela pra saber quando a escuta acabou (por
  /// timeout de silêncio, `stop` ou `cancel`), sem precisar de um Timer
  /// manual duplicando o timeout que o próprio pacote já controla via
  /// `pauseFor` em `listen()`.
  Future<bool> init({
    required void Function(String message) onError,
    required void Function(String status) onStatus,
  }) async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (error) => onError(error.errorMsg),
        onStatus: onStatus,
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  /// Escuta uma única pergunta. `pauseFor` é o TIMEOUT OBRIGATÓRIO de
  /// silêncio exigido pela especificação (§Arquitetura a avaliar,
  /// adição v1.1: "evitar que a captura de voz fique presa
  /// indefinidamente") — o pacote transiciona sozinho pro status
  /// `notListening` quando ninguém fala por esse tempo.
  Future<void> listen({required void Function(String text) onFinalResult}) {
    return _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) onFinalResult(result.recognizedWords);
      },
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: false,
        listenMode: stt.ListenMode.confirmation,
        localeId: 'pt_BR',
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> cancel() => _speech.cancel();
  Future<void> stop() => _speech.stop();
}
