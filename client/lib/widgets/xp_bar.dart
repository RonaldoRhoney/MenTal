import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra de XP — DESIGN_SYSTEM.md §4: "sempre visível no topo da Home,
/// gradiente gold→teal, nunca cor sólida neutra (progresso deve parecer
/// vivo)". Progresso dentro do nível atual — decisão de implementação:
/// usa 100 XP/nível espelhando `backend/app/config.py::XP_PER_LEVEL`
/// (só para o visual; o nível em si sempre vem pronto do backend).
///
/// Reforço de gamificação (pedido de Rhoney, 29/08/2026): barra mais alta
/// e animada (cresce da esquerda pra direita a cada carregamento, em vez
/// de aparecer já preenchida) + gradiente de 3 cores (verde-vitória →
/// roxo → dourado) pra reforçar a sensação de progresso/conquista. Nível
/// virou um badge circular ao lado do texto, não só texto solto.
class XpBar extends StatelessWidget {
  const XpBar({super.key, required this.xpTotal, required this.level});

  final int xpTotal;
  final int level;

  static const _xpPerLevel = 100;

  @override
  Widget build(BuildContext context) {
    final xpIntoLevel = xpTotal % _xpPerLevel;
    final fraction = (xpIntoLevel / _xpPerLevel).clamp(0.0, 1.0);

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
          '$xpIntoLevel / $_xpPerLevel XP',
          style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}
