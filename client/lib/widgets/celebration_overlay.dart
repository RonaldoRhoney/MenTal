import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Celebração forte — território conquistado, badge desbloqueado, level
/// up (MICROINTERACTIONS.md §3, "mesma família visual" para os três).
/// [controller] é disparado (`.play()`) por quem detecta o evento — este
/// widget só desenha a partícula por cima do conteúdo normal da tela.
///
/// A checagem de "reduzir movimento" (§4) acontece em quem chama
/// `.play()`, não aqui — quando ativado, o disparo simplesmente nunca
/// acontece, então o confete nunca aparece.
class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({super.key, required this.controller, required this.child});

  final ConfettiController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        child,
        IgnorePointer(
          child: ConfettiWidget(
            confettiController: controller,
            blastDirection: pi / 2,
            maxBlastForce: 12,
            minBlastForce: 6,
            numberOfParticles: 24,
            gravity: 0.3,
            shouldLoop: false,
            colors: const [AppColors.gold, AppColors.teal, AppColors.bone, AppColors.error],
          ),
        ),
      ],
    );
  }
}
