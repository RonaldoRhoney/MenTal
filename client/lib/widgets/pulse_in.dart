import 'package:flutter/material.dart';

/// Microanimação de entrada — MICROINTERACTIONS.md §3. Um único disparo
/// (escala + fade) ao ser montado na árvore, nunca um loop contínuo (não
/// pode virar ruído visual constante). Usado para o "acerto comum" (sutil,
/// [intensity] baixo) e para "sequência mantida" (moderado, [intensity]
/// mais alto) — dois níveis de calibração com o mesmo widget, evitando
/// duas implementações quase idênticas.
///
/// Respeita "reduzir movimento" do sistema (§4, não-negociável): quando
/// ativado, renderiza [child] direto, sem nenhuma animação — o texto/cor
/// já implementado continua sendo a fonte primária de informação.
class PulseIn extends StatefulWidget {
  const PulseIn({super.key, required this.child, this.intensity = 0.15});

  final Widget child;

  /// 0.0 a 1.0 — quanto maior, mais perceptível o pulso (usado para
  /// diferenciar "sutil" de "moderado" na tabela de MICROINTERACTIONS.md §3).
  final double intensity;

  @override
  State<PulseIn> createState() => _PulseInState();
}

class _PulseInState extends State<PulseIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = Tween<double>(begin: 1 - widget.intensity, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery.of() só pode ser chamado com segurança a partir daqui,
    // nunca em initState() — achado real ao rodar os testes de widget
    // (assertion "dependOnInheritedWidgetOfExactType called before
    // initState() completed").
    if (_started) return;
    _started = true;
    if (!MediaQuery.of(context).disableAnimations) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
