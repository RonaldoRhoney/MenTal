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

  /// Retorna true se o OS share sheet foi aberto sem erro. Usado pelo
  /// chamador (ShareAchievementButton) como sinal de "compartilhamento
  /// tentado" para então pedir a recompensa de XP ao backend — o app
  /// nunca confirma que o compartilhamento foi de fato concluído, só que
  /// o sheet abriu (mesma limitação documentada em services.
  /// award_share_reward no backend, coberta lá pelo teto diário).
  static Future<bool> share(String text) async {
    try {
      await SharePlus.instance.share(ShareParams(text: text));
      return true;
    } catch (_) {
      // Compartilhar é reforço opcional, nunca requisito — falha (ex.:
      // nenhum app de compartilhamento disponível) não pode quebrar o
      // app, mesmo princípio de FeedbackService/PushService.
      return false;
    }
  }
}
