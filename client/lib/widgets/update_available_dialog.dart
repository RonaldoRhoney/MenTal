import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md §2.4 — animação de entrada
/// suave (fade + leve escala), paleta dourado/teal já estabelecida, em
/// vez de um alerta de sistema genérico. `required` (atualização
/// obrigatória, ex.: correção crítica de segurança) esconde "Mais
/// tarde" e impede fechar tocando fora — mas o botão "Atualizar" nunca
/// deixa de estar visível/acessível (conformidade Google Play).
const String _kPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.rhoneyinc.mental';

Future<void> showUpdateAvailableDialog(BuildContext context, {required bool required}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: !required,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, _, __) => _UpdateAvailableDialogContent(required: required),
    transitionBuilder: (dialogContext, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(curved), child: child),
      );
    },
  );
}

class _UpdateAvailableDialogContent extends StatelessWidget {
  const _UpdateAvailableDialogContent({required this.required});

  final bool required;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !required,
      child: Dialog(
        backgroundColor: AppColors.bg2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.gold.withValues(alpha: 0.15)),
                child: Icon(Icons.auto_awesome_rounded, color: AppColors.gold, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                required ? l10n.updateRequiredTitle : l10n.updateAvailableTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                required ? l10n.updateRequiredMessage : l10n.updateAvailableMessage,
                style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
                  onPressed: () => launchUrl(Uri.parse(_kPlayStoreUrl), mode: LaunchMode.externalApplication),
                  child: Text(l10n.updateNowButton),
                ),
              ),
              if (!required) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.updateLaterButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
