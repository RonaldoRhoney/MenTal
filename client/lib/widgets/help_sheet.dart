import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card explicativo "Como funciona", acessível a qualquer momento (ícone
/// de ajuda no AppBar) dentro de uma tela — diferente do onboarding de
/// 6 telas (que só aparece uma vez após o splash), este é reaberto
/// livremente pelo usuário sempre que tiver dúvida sobre a mecânica da
/// tela em que está. Pedido de Rhoney (30/08/2026) para Amigos e
/// Batalhas, mas construído genérico o bastante pra outras telas usarem.
class HelpStep {
  const HelpStep({required this.icon, required this.title, required this.description});

  final IconData icon;
  final String title;
  final String description;
}

Future<void> showHelpSheet(
  BuildContext context, {
  required String title,
  required List<HelpStep> steps,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.bg2,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              title,
              style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 18).copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            for (final step in steps) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10)),
                    child: Icon(step.icon, color: AppColors.gold, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(step.title, style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.w700, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(step.description, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
          ],
        ),
      ),
    ),
  );
}
