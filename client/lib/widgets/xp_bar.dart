import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Barra de XP — DESIGN_SYSTEM.md §4: "sempre visível no topo da Home,
/// gradiente gold→teal, nunca cor sólida neutra (progresso deve parecer
/// vivo)". Progresso dentro do nível atual — decisão de implementação:
/// usa 100 XP/nível espelhando `backend/app/config.py::XP_PER_LEVEL`
/// (só para o visual; o nível em si sempre vem pronto do backend).
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
        Text('Nível $level', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: Stack(
              children: [
                Container(color: AppColors.bg2),
                FractionallySizedBox(
                  widthFactor: fraction,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.gold, AppColors.teal]),
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
