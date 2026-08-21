import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const List<Color> kBalloonColors = [AppColors.gold, AppColors.teal, AppColors.bone, AppColors.error];

/// Dispara uma leva de balões — chame [play] a partir de quem detectou o
/// evento raro (MICROINTERACTIONS.md §3). Não depende de BuildContext,
/// então pode viver junto com o resto do estado de celebração
/// (ConfettiController etc.) em ChallengeScreen.
class BalloonsController extends ChangeNotifier {
  void play() => notifyListeners();
}

/// Balões subindo da parte de baixo da tela até sumir no topo — celebração
/// "mais interativa" (fogos + balões) pedida para complementar o confete e
/// o texto em território conquistado / badge desbloqueado / level up.
/// Só é acionado quando [controller].play() é chamado por fora — quem
/// aciona já decide não chamar quando "reduzir movimento" está ativo
/// (mesmo padrão do ConfettiController em CelebrationOverlay).
class BalloonsOverlay extends StatefulWidget {
  const BalloonsOverlay({super.key, required this.controller, required this.child});

  final BalloonsController controller;
  final Widget child;

  @override
  State<BalloonsOverlay> createState() => _BalloonsOverlayState();
}

class _BalloonsOverlayState extends State<BalloonsOverlay> {
  final List<Key> _balloonKeys = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_spawn);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_spawn);
    super.dispose();
  }

  void _spawn() {
    setState(() {
      _balloonKeys.addAll(List.generate(7, (_) => UniqueKey()));
    });
  }

  void _remove(Key key) {
    if (!mounted) return;
    setState(() => _balloonKeys.remove(key));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._balloonKeys.map(
          (key) => _Balloon(
            key: key,
            color: kBalloonColors[_random.nextInt(kBalloonColors.length)],
            left: _random.nextDouble(),
            delayMs: _random.nextInt(400),
            onDone: _remove,
          ),
        ),
      ],
    );
  }
}

class _Balloon extends StatefulWidget {
  const _Balloon({
    required Key key,
    required this.color,
    required this.left,
    required this.delayMs,
    required this.onDone,
  }) : super(key: key);

  final Color color;

  /// Fração horizontal (0.0-1.0) de onde o balão sobe.
  final double left;
  final int delayMs;
  final void Function(Key key) onDone;

  @override
  State<_Balloon> createState() => _BalloonState();
}

class _BalloonState extends State<_Balloon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone(widget.key!);
    });
    // Timer cancelável em vez de Future.delayed solto — achado real nos
    // testes de widget: um balão removido antes do atraso terminar (ex.:
    // tela fechada cedo) deixava um timer pendente, travando o teardown
    // ("A Timer is still pending even after the widget tree was disposed").
    _startTimer = Timer(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Positioned precisa ser filho direto do Stack (via só widgets que não
    // têm RenderObject entre os dois, ex.: AnimatedBuilder) — achado real
    // testando: um IgnorePointer por fora do Positioned quebra essa regra
    // ("Incorrect use of ParentDataWidget"). IgnorePointer entra por
    // dentro, envolvendo só o conteúdo, nunca o próprio Positioned.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final bottom = -100 + t * (size.height + 200);
        final sway = sin(t * 3 * pi) * 14;
        final opacity = t < 0.85 ? 1.0 : (1 - (t - 0.85) / 0.15).clamp(0.0, 1.0);
        return Positioned(
          // max(0.0, ...) evita ArgumentError de clamp(min, max) com
          // min > max numa tela teoricamente menor que o balão (36px).
          left: (widget.left * size.width - 18 + sway).clamp(0.0, max(0.0, size.width - 36)),
          bottom: bottom,
          child: IgnorePointer(child: Opacity(opacity: opacity, child: child)),
        );
      },
      child: _BalloonShape(color: widget.color),
    );
  }
}

class _BalloonShape extends StatelessWidget {
  const _BalloonShape({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 46,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        ),
        Container(width: 2, height: 28, color: AppColors.muted),
      ],
    );
  }
}
