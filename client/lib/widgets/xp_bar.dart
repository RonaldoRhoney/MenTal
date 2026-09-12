import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra de XP — DESIGN_SYSTEM.md §4: "sempre visível no topo da Home,
/// gradiente gold→teal, nunca cor sólida neutra (progresso deve parecer
/// vivo)". Progresso dentro do nível atual — `xpPerLevel` vem de
/// GET /progress (config.XP_PER_LEVEL no backend, fonte de verdade),
/// nunca duplicado aqui como constante local (achado de auditoria 3.1,
/// 11/09/2026).
///
/// Reforço de gamificação (pedido de Rhoney, 29/08/2026): barra mais alta
/// e animada (cresce da esquerda pra direita a cada carregamento, em vez
/// de aparecer já preenchida) + gradiente de 3 cores (verde-vitória →
/// roxo → dourado) pra reforçar a sensação de progresso/conquista. Nível
/// virou um badge circular ao lado do texto, não só texto solto.
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.xpTotal, required this.level, required this.xpPerLevel});

  final int xpTotal;
  final int level;
  // Achado de auditoria de qualidade 3.1 (11/09/2026): antes hardcoded
  // aqui e duplicado em home_screen.dart — o backend já é a fonte de
  // verdade (config.XP_PER_LEVEL) e já envia o valor em GET /progress,
  // então este widget passou a recebê-lo do chamador em vez de duplicar
  // a constante.
  final int xpPerLevel;

  @override
  Widget build(BuildContext context) {
    final xpIntoLevel = xpTotal % xpPerLevel;
    final fraction = (xpIntoLevel / xpPerLevel).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.purple, AppColors.gold]),
              ),
              child: Text(
                '$level',
                style: AppTheme.technicalStyle(color: AppColors.bg, fontSize: 14).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            Text('Nível $level', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 18,
            child: Stack(
              children: [
                Container(color: AppColors.bg2),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: fraction),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.victory, AppColors.purple, AppColors.gold],
                        ),
                        boxShadow: [
                          BoxShadow(color: AppColors.gold.withValues(alpha: 0.35), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$xpIntoLevel / $xpPerLevel XP',
          style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}
