import 'package:share_plus/share_plus.dart';

/// Compartilhamento de conquistas e convite (pedido de Rhoney,
/// 2026-08-22). Usa o Intent nativo do SO (ACTION_SEND via share_plus,
/// ZERO_COST confirmado — sem serviço externo, sem custo, mesmo rigor
/// da skill zero-cost-api) — nunca gera imagem nem depende de rede.
///
/// Mensagens de conquista nunca incluem dado pessoal (nickname, XP
/// exato de outro jogador, etc.) — só o feito em si (território, nível,
/// badge, meta) — seguro pra compartilhar mesmo em perfil
/// child_safe_mode, mesmo raciocínio de não expor identificador além do
/// que já é público no ranking.
class ShareService {
  ShareService._();

  static Future<void> share(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
    } catch (_) {
      // Compartilhar é reforço opcional, nunca requisito — falha (ex.:
      // nenhum app de compartilhamento disponível) não pode quebrar o
      // app, mesmo princípio de FeedbackService/PushService.
    }
  }
}
