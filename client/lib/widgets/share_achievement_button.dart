import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';

/// Botão pequeno de "Compartilhar" reaproveitado em toda celebração de
/// conquista (território, mundo, nível, badge, meta de passos) — pedido
/// de Rhoney, 2026-08-22. Mesmo texto/mensagem já pronto é passado por
/// quem chama; este widget só cuida da apresentação consistente.
///
/// Desde 2026-08-22, compartilhar rende XP (POST /social/share-reward,
/// teto de 1x/dia no backend — client nunca decide o valor nem confia
/// em si mesmo pra evitar farm, só dispara a chamada). Falha de rede ou
/// já ter recompensa hoje são tratadas em silêncio: XP não é o motivo
/// principal do botão existir, é reforço.
class ShareAchievementButton extends StatelessWidget {
  const ShareAchievementButton({super.key, required this.message, required this.client});

  final String message;
  final ApiClient client;

  Future<void> _handleShare(BuildContext context) async {
    final shared = await ShareService.share(message);
    if (!shared) return;

    try {
      final result = await client.rewardShare();
      final xpAwarded = result['xp_awarded'] as int? ?? 0;
      if (xpAwarded > 0 && context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shareXpRewardedMessage(xpAwarded))),
        );
      }
    } catch (_) {
      // Reforço opcional — falha ao pedir a recompensa não pode
      // interromper o fluxo de compartilhamento já concluído.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _handleShare(context),
        icon: Icon(Icons.share_outlined, size: 16, color: AppColors.teal),
        label: Text(l10n.shareButtonLabel, style: TextStyle(color: AppColors.teal)),
      ),
    );
  }
}
