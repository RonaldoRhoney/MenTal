import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'mentalcoin.dart';

/// Celebração de marco de XP/MentalCoins (pedido de Rhoney): toda vez
/// que o total de XP do jogador cruza um múltiplo de 100 OU o saldo de
/// MentalCoins cruza um múltiplo de 50, uma leva de moedas sobe pela
/// tela — mesmo padrão de BalloonsOverlay (widget irmão em
/// balloons_overlay.dart), só trocando a forma que sobe e encurtando a
/// duração/trajeto (aqui é reforço de marco numérico, não a celebração
/// forte reservada a território/badge/nível). A TRANSIÇÃO exata (cruzou
/// agora, não "já é múltiplo") é sempre calculada pelo backend
/// (services.crossed_coin_milestone) — este widget só reage ao sinal
/// que já veio pronto, nunca decide sozinho quando celebrar.
class CoinsRiseController extends ChangeNotifier {
  void play() => notifyListeners();
}

class CoinsRiseOverlay extends StatefulWidget {
  const CoinsRiseOverlay(
      {super.key, required this.controller, required this.child});

  final CoinsRiseController controller;
  final Widget child;

  @override
  State<CoinsRiseOverlay> createState() => _CoinsRiseOverlayState();
}

class _CoinsRiseOverlayState extends State<CoinsRiseOverlay> {
  final List<Key> _coinKeys = [];
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
      _coinKeys.addAll(List.generate(8, (_) => UniqueKey()));
    });
  }

  void _remove(Key key) {
    if (!mounted) return;
    setState(() => _coinKeys.remove(key));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        ..._coinKeys.map(
          (key) => _RisingCoin(
            key: key,
            left: _random.nextDouble(),
            delayMs: _random.nextInt(300),
            onDone: _remove,
          ),
        ),
      ],
    );
  }
}

class _RisingCoin extends StatefulWidget {
  const _RisingCoin({
    required Key key,
    required this.left,
    required this.delayMs,
    required this.onDone,
  }) : super(key: key);

  /// Fração horizontal (0.0-1.0) de onde a moeda sobe.
  final double left;
  final int delayMs;
  final void Function(Key key) onDone;

  @override
  State<_RisingCoin> createState() => _RisingCoinState();
}

class _RisingCoinState extends State<_RisingCoin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600));
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone(widget.key!);
    });
    // Timer cancelável, não Future.delayed solto — mesmo achado real já
    // documentado em BalloonsOverlay (timer pendente travava o teardown
    // quando a moeda era removida antes do atraso terminar).
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
    // Começa na metade inferior da tela (não do fundo absoluto como o
    // balão) — a moeda sobe uma distância mais curta, reforço rápido de
    // "ganhou algo", não uma celebração longa de tela inteira.
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final bottom = size.height * 0.35 + t * (size.height * 0.55);
        final sway = sin(t * 3 * pi) * 10;
        final opacity =
            t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
        return Positioned(
          left: (widget.left * size.width - 14 + sway)
              .clamp(0.0, max(0.0, size.width - 28)),
          bottom: bottom,
          child: IgnorePointer(child: Opacity(opacity: opacity, child: child)),
        );
      },
      child: const MentalCoin(size: 28),
    );
  }
}
