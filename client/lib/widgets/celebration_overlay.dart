import 'dart:async';
import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'balloons_overlay.dart';

const List<Color> kCelebrationColors = [AppColors.gold, AppColors.teal, AppColors.bone, AppColors.error];

/// Celebração forte — território conquistado, badge desbloqueado, level
/// up (MICROINTERACTIONS.md §3, "mesma família visual" para os três).
/// Combina confete caindo do topo + dois "fogos" (explosão radial, como
/// pedido: algo que remeta a comemoração de verdade) + balões subindo —
/// além do texto, nunca no lugar dele (acessibilidade).
///
/// Agrupa os controllers num único objeto para quem dispara a celebração
/// (ChallengeScreen) não precisar coordenar 4 animações na mão — chama só
/// [celebrate]. A decisão de NÃO chamar [celebrate] quando "reduzir
/// movimento" está ativo é de quem instancia isto (mesmo padrão já usado
/// no restante do app), não deste arquivo.
class CelebrationController {
  CelebrationController()
      : confettiFall = ConfettiController(duration: const Duration(milliseconds: 1000)),
        fireworkA = ConfettiController(duration: const Duration(milliseconds: 700)),
        fireworkB = ConfettiController(duration: const Duration(milliseconds: 700)),
        balloons = BalloonsController();

  final ConfettiController confettiFall;
  final ConfettiController fireworkA;
  final ConfettiController fireworkB;
  final BalloonsController balloons;
  Timer? _fireworkBTimer;

  void celebrate() {
    confettiFall.play();
    fireworkA.play();
    balloons.play();
    // Segundo "fogo" com um pequeno atraso — duas explosões em pontos
    // diferentes da tela parecem mais uma queima de fogos de verdade do
    // que uma explosão só.
    _fireworkBTimer?.cancel();
    _fireworkBTimer = Timer(const Duration(milliseconds: 250), fireworkB.play);
  }

  void dispose() {
    _fireworkBTimer?.cancel();
    confettiFall.dispose();
    fireworkA.dispose();
    fireworkB.dispose();
    balloons.dispose();
  }
}

class CelebrationOverlay extends StatelessWidget {
  const CelebrationOverlay({super.key, required this.controller, required this.child});

  final CelebrationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BalloonsOverlay(
      controller: controller.balloons,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          child,
          IgnorePointer(
            child: ConfettiWidget(
              confettiController: controller.confettiFall,
              blastDirection: pi / 2,
              maxBlastForce: 12,
              minBlastForce: 6,
              numberOfParticles: 24,
              gravity: 0.3,
              shouldLoop: false,
              colors: kCelebrationColors,
            ),
          ),
          Align(
            alignment: const Alignment(-0.5, -0.3),
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: controller.fireworkA,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 18,
                maxBlastForce: 18,
                minBlastForce: 8,
                gravity: 0.15,
                shouldLoop: false,
                colors: kCelebrationColors,
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0.5, -0.15),
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: controller.fireworkB,
                blastDirectionality: BlastDirectionality.explosive,
                numberOfParticles: 18,
                maxBlastForce: 18,
                minBlastForce: 8,
                gravity: 0.15,
                shouldLoop: false,
                colors: kCelebrationColors,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
