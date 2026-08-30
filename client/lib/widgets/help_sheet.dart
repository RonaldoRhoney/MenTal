import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Card explicativo "Como funciona", acessível a qualquer momento (ícone
/// de ajuda no AppBar) dentro de uma tela — diferente do onboarding de
/// 6 telas (que só aparece uma vez após o splash), este é reaberto
/// livremente pelo usuário sempre que tiver dúvida sobre a mecânica da
/// tela em que está. Pedido de Rhoney (30/08/2026) para Amigos e
/// Batalhas, mas construído genérico o bastante pra outras telas usarem.
///
/// Redesenhado (30/08/2026, pedido de Rhoney) como uma trilha numerada
/// (círculo com o número do passo + linha conectando ao próximo) em vez
/// de ícones soltos — o formato "passo a passo" fica visualmente óbvio,
/// não só implícito na ordem da lista.
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
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.82),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.muted.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                title,
                style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 19).copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      _HelpStepRow(
                        stepNumber: i + 1,
                        step: steps[i],
                        isLast: i == steps.length - 1,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HelpStepRow extends StatelessWidget {
  const _HelpStepRow({required this.stepNumber, required this.step, required this.isLast});

  final int stepNumber;
  final HelpStep step;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trilha: número do passo num círculo + linha conectando ao
          // próximo (some no último) — deixa a sequência óbvia de
          // relance, sem precisar ler o texto pra entender que é um
          // passo a passo.
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '$stepNumber',
                  style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 13).copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(step.icon, color: AppColors.teal, size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(step.description, style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
