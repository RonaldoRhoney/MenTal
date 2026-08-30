import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Fundo com profundidade (gradiente radial roxo-escuro → preto), em vez
/// do preto quase sólido anterior — pedido de Rhoney (29/08/2026): "esse
/// fundo tod escuro está muito fora do escopo de um game". Reaproveita a
/// mesma paleta já proposta em U.I/MOVIMENTO_REDESIGN_V1.md §2 (fundo:
/// gradiente radial roxo-escuro `#241640` → `#0A0710`), generalizada pra
/// qualquer tela do app — não só a tela Movimento, onde o documento
/// original propôs isso primeiro.
class GameBackground extends StatelessWidget {
  const GameBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.7, -0.9),
          radius: 1.4,
          colors: [AppColors.bgGlow, AppColors.bg],
          stops: [0.0, 0.75],
        ),
      ),
      child: child,
    );
  }
}
