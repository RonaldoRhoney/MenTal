import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MENTAL_ASO_GOOGLE_PLAY_ESPECIFICACAO_TECNICA_V1.1.md §17/§24 item 6
/// (aprovado por Rhoney, 04/10/2026) — pede avaliação do app usando a
/// API oficial do Android (In-App Review API) / iOS (SKStoreReview
/// Controller) via o pacote `in_app_review`, NUNCA abrindo a Play Store
/// direto. Quem decide se o diálogo nativo realmente aparece é a
/// própria API do Google, respeitando a cota dela (não é possível nem
/// desejável contornar isso) — este serviço só decide QUANDO vale a
/// pena chamar `requestReview()`, sempre em momento positivo.
///
/// Regras obrigatórias do documento, aplicadas aqui:
/// - Nunca filtra quem recebe o pedido (ex.: "você gosta do app?" antes
///   de encaminhar só quem responde bem) — todo usuário elegível no
///   momento positivo é convidado igualmente.
/// - Nunca dispara após erro, durante uma partida, ou na primeira
///   abertura — só no momento de celebração já existente (Mundo
///   conquistado).
/// - Cooldown de app (60 dias) além da cota interna do Google — evita
///   chamar a API repetidamente pro mesmo usuário que conquista vários
///   Mundos seguidos, mesmo sabendo que o Google já joga fora chamadas
///   em excesso.
class ReviewPromptService {
  ReviewPromptService._();

  static const _kLastRequestedAtKey = 'review_prompt_last_requested_at_v1';
  static const _kCooldown = Duration(days: 60);

  /// Chamar só em momento positivo já confirmado pelo chamador (ex.:
  /// depois da celebração de Mundo conquistado, nunca no meio dela).
  /// Falha silenciosa — pedir avaliação é reforço, nunca pode travar a
  /// tela nem ser percebido como erro pelo usuário.
  static Future<void> maybeRequestReview() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMillis = prefs.getInt(_kLastRequestedAtKey);
      final now = DateTime.now();
      if (lastMillis != null) {
        final last = DateTime.fromMillisecondsSinceEpoch(lastMillis);
        if (now.difference(last) < _kCooldown) return;
      }

      final inAppReview = InAppReview.instance;
      if (!await inAppReview.isAvailable()) return;

      await prefs.setInt(_kLastRequestedAtKey, now.millisecondsSinceEpoch);
      await inAppReview.requestReview();
    } catch (_) {}
  }
}
