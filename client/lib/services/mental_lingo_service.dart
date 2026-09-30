import 'package:flutter/foundation.dart';
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

  /// Só para testes: permite estender a classe com um reconhecedor falso.
  @visibleForTesting
  MentalLingoService.forTesting();

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

  /// Escuta uma única pergunta. MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md
  /// (ajuste de 28/09/2026, aprovado por Rhoney): a captura passa a ser
  /// por APERTAR-E-SEGURAR o botão do microfone, não mais por detecção
  /// de silêncio — em testes reais, o `pauseFor` curto processava a
  /// pergunta com base em só parte da fala, interpretando uma pausa
  /// natural (respirar, pensar) como fim da pergunta. `pauseFor` e
  /// `listenFor` agora ficam bem altos (a tela é quem decide quando a
  /// captura acaba, chamando `stop()` no momento em que o usuário solta
  /// o botão) — servem só como rede de segurança contra o pacote nunca
  /// concluir a sessão sozinho.
  /// `onPartialResult` (opcional) recebe a transcrição parcial enquanto o
  /// usuário ainda fala — usado só pra exibir "Ouvindo… <texto>" ao vivo
  /// durante o apertar-e-segurar; a pergunta em si sempre é decidida pelo
  /// resultado FINAL (`onFinalResult`), nunca por um trecho parcial.
  /// `silenceTimeout`: só usado no Modo 3 (detecção automática de fim de
  /// fala, MENTAL_LINGO_RELATORIO_TESTES_CAMPO_V1.md, decisão de Rhoney
  /// 29/09/2026) — quando informado, vira o `pauseFor` do reconhecedor: o
  /// pacote encerra sozinho após esse tanto de SILÊNCIO CONTÍNUO (não
  /// duração total da fala), disparando `onStatus('done')`. Nos modos 1
  /// (apertar-e-segurar) e 2 (toque duplo), fica `null` e usa o padrão de
  /// 3 minutos (a tela é quem decide quando parar, nunca o pacote).
  Future<void> listen({
    required void Function(String text) onFinalResult,
    void Function(String text)? onPartialResult,
    Duration? silenceTimeout,
  }) {
    return _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        if (result.finalResult) {
          onFinalResult(result.recognizedWords);
        } else {
          onPartialResult?.call(result.recognizedWords);
        }
      },
      listenOptions: stt.SpeechListenOptions(
        cancelOnError: true,
        partialResults: onPartialResult != null,
        listenMode: stt.ListenMode.dictation,
        localeId: 'pt_BR',
        listenFor: const Duration(minutes: 3),
        pauseFor: silenceTimeout ?? const Duration(minutes: 3),
      ),
    );
  }

  Future<void> cancel() => _speech.cancel();
  Future<void> stop() => _speech.stop();
}
