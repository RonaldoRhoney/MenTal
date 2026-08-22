import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';

/// Botão pequeno de "Compartilhar" reaproveitado em toda celebração de
/// conquista (território, mundo, nível, badge, meta de passos) — pedido
/// de Rhoney, 2026-08-22. Mesmo texto/mensagem já pronto é passado por
/// quem chama; este widget só cuida da apresentação consistente.
class ShareAchievementButton extends StatelessWidget {
  const ShareAchievementButton({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => ShareService.share(message),
        icon: const Icon(Icons.share_outlined, size: 16, color: AppColors.teal),
        label: Text(l10n.shareButtonLabel, style: const TextStyle(color: AppColors.teal)),
      ),
    );
  }
}
