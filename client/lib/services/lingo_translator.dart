import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

/// Tradução de FRASES do Mental Lingo (26/09/2026, aprovada por Rhoney — "aceitar perguntas
/// com frases", custo zero). Feita NO APARELHO com o Google ML Kit: gratuito, sem conta nem
/// cobrança, e o texto da frase não sai do celular (só o modelo de idioma, ~30 MB, é baixado
/// uma vez). Nunca é usada para palavras do vocabulário curado — só quando o servidor não
/// achou o termo e devolveu a intenção de traduzir.
///
/// Códigos de idioma do Lingo: 'pt', 'ingles', 'espanhol', 'frances'.
abstract class LingoTranslator {
  /// Idioma do texto: 'pt', 'ingles', 'espanhol', 'frances' ou null (não reconhecido/outro).
  Future<String?> detectLanguage(String text);

  /// Traduz [text] de [from] para [to]. Se o modelo de idioma ainda não estiver no aparelho,
  /// chama [onDownloading] e baixa (uma vez só). Lança [LingoTranslateException] se falhar.
  Future<String> translate(String text,
      {required String from, required String to, void Function()? onDownloading});
}

class LingoTranslateException implements Exception {
  LingoTranslateException(this.message);
  final String message;
  @override
  String toString() => message;
}

const Map<String, TranslateLanguage> _kMlKitLanguages = {
  'pt': TranslateLanguage.portuguese,
  'ingles': TranslateLanguage.english,
  'espanhol': TranslateLanguage.spanish,
  'frances': TranslateLanguage.french,
};

const Map<String, String> _kBcpToLingo = {
  'pt': 'pt',
  'en': 'ingles',
  'es': 'espanhol',
  'fr': 'frances',
};

class MlKitLingoTranslator implements LingoTranslator {
  MlKitLingoTranslator();
  static final MlKitLingoTranslator instance = MlKitLingoTranslator();

  final OnDeviceTranslatorModelManager _models = OnDeviceTranslatorModelManager();

  @override
  Future<String?> detectLanguage(String text) async {
    final identifier = LanguageIdentifier(confidenceThreshold: 0.5);
    try {
      final bcp = await identifier.identifyLanguage(text);
      return _kBcpToLingo[bcp];
    } catch (_) {
      return null;
    } finally {
      await identifier.close();
    }
  }

  Future<void> _ensureModel(TranslateLanguage language, void Function()? onDownloading) async {
    if (await _models.isModelDownloaded(language.bcpCode)) return;
    onDownloading?.call();
    final ok = await _models
        .downloadModel(language.bcpCode, isWifiRequired: false)
        .timeout(const Duration(minutes: 3), onTimeout: () => false);
    if (!ok) {
      throw LingoTranslateException('Não consegui baixar o idioma de tradução. Verifique a internet e tente de novo.');
    }
  }

  @override
  Future<String> translate(String text,
      {required String from, required String to, void Function()? onDownloading}) async {
    final source = _kMlKitLanguages[from];
    final target = _kMlKitLanguages[to];
    if (source == null || target == null) {
      throw LingoTranslateException('Esse idioma ainda não é suportado na tradução de frases.');
    }
    await _ensureModel(source, onDownloading);
    await _ensureModel(target, onDownloading);
    final translator = OnDeviceTranslator(sourceLanguage: source, targetLanguage: target);
    try {
      final out = (await translator.translateText(text)).trim();
      if (out.isEmpty) throw LingoTranslateException('Não consegui traduzir essa frase.');
      return out;
    } on LingoTranslateException {
      rethrow;
    } catch (_) {
      throw LingoTranslateException('Não consegui traduzir essa frase agora. Tente de novo.');
    } finally {
      await translator.close();
    }
  }
}
