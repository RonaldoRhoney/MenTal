import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Splash de boas-vindas exibido uma vez por sessão, logo depois do login
/// (e da confirmação de maioridade, se for a primeira vez) — diferente do
/// SplashScreen inicial (que roda ANTES de qualquer decisão de destino).
/// Desenha um "M" completo (29/08/2026, pedido de Rhoney: "deve desenhar
/// um M completo, com as sinapses cognitivas para dar mais relevância ao
/// nome Mental") — as 4 hastes do M nascem como sinapses (nós + linhas
/// douradas/teal) que se acendem em sequência, elegante e suave, em vez
/// do símbolo abstrato de rede que havia antes. Vetorial via
/// CustomPainter, mesmo espírito de _GoogleGlyphPainter em
/// login_screen.dart — sem depender de imagem rasterizada.
class WelcomeSplashScreen extends StatefulWidget {
  const WelcomeSplashScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<WelcomeSplashScreen> createState() => _WelcomeSplashScreenState();
}

class _WelcomeSplashScreenState extends State<WelcomeSplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Achado real (2026-08-26, teste no dispositivo, 2 rodadas): a
    // formação do símbolo (nó central → sinapses → nós externos)
    // continuava rápida demais mesmo depois do primeiro ajuste —
    // esticada de novo, agora com bem mais peso pra essa etapa
    // especificamente (não só pro texto), dando tempo real de VER cada
    // linha se desenhando.
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 4800))..forward();
    Future.delayed(const Duration(milliseconds: 5800), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _stage(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // Sequência mais espaçada (achado real, 2026-08-26): símbolo
            // termina de se formar, uma pequena pausa, só então o
            // wordmark sobe, e o slogan chega por último — em vez de
            // tudo se sobrepondo no mesmo intervalo curto.
            final wordmarkT = Curves.easeOut.transform(_stage(t, 0.72, 0.86));
            final sloganT = Curves.easeOut.transform(_stage(t, 0.88, 1.0));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 148,
                  height: 148,
                  child: CustomPaint(painter: _MSynapsePainter(progress: t)),
                ),
                const SizedBox(height: 24),
                Opacity(
                  opacity: wordmarkT,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - wordmarkT)),
                    child: Text(l10n.loginTitle, style: Theme.of(context).textTheme.displaySmall),
                  ),
                ),
                const SizedBox(height: 8),
                Opacity(
                  opacity: sloganT,
                  child: Text(
                    l10n.loginSlogan,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Desenha o "M" de Mental como uma cadeia de 5 nós (sinapses) ligados
/// por 4 hastes, na silhueta clássica da letra: vertical esquerda,
/// diagonal descendo até o vale central, diagonal subindo até o pico
/// direito, vertical direita. Cada haste nasce do nó anterior — a
/// mesma linguagem de "sinapse acendendo" do símbolo antigo, só que
/// agora formando uma letra reconhecível em vez de uma rede abstrata.
class _MSynapsePainter extends CustomPainter {
  _MSynapsePainter({required this.progress});

  final double progress;

  static const _gold = Color(0xFFE2BE6E);
  static const _teal = Color(0xFF3FA796);

  double _stage(double start, double end) {
    if (progress <= start) return 0;
    if (progress >= end) return 1;
    return (progress - start) / (end - start);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    Offset p(double x, double y) => Offset(x * scale, y * scale);

    // Vértices do M, na ordem em que a letra é "escrita": base
    // esquerda → topo esquerdo → vale central → topo direito → base
    // direita.
    final nodes = [p(28, 70), p(28, 30), p(50, 52), p(72, 30), p(72, 70)];
    final segmentColors = [_gold, _teal, _teal, _gold];
    final nodeColors = [_gold, _teal, _gold, _teal, _gold];

    // Nó inicial nasce com um leve exagero elástico, dando o toque de
    // energia/vida — só depois disso a primeira haste começa a crescer.
    final firstNodeScale = Curves.elasticOut.transform(_stage(0.0, 0.1).clamp(0.0, 1.0));
    if (firstNodeScale <= 0) return;
    canvas.drawCircle(nodes[0], 4.5 * scale * firstNodeScale, Paint()..color = nodeColors[0]);

    // As 4 hastes crescem em sequência, cada uma só começa quando a
    // anterior termina — a letra "se escreve" com suavidade, um traço
    // de cada vez, em vez de tudo aparecer junto.
    const segmentSpan = 0.10;
    const segmentGap = 0.02;
    for (var i = 0; i < 4; i++) {
      final start = 0.08 + i * (segmentSpan + segmentGap);
      final end = start + segmentSpan;
      final t = Curves.easeInOut.transform(_stage(start, end));
      if (t <= 0) continue;
      final segEnd = Offset.lerp(nodes[i], nodes[i + 1], t)!;
      canvas.drawLine(
        nodes[i],
        segEnd,
        Paint()
          ..color = segmentColors[i]
          ..strokeWidth = 2.6 * scale
          ..strokeCap = StrokeCap.round,
      );
      // Nó seguinte acende com um pequeno bounce assim que a haste chega nele.
      final nodeT = Curves.easeOutBack.transform(_stage(end - 0.03, end + 0.02).clamp(0.0, 1.0));
      if (nodeT > 0) {
        canvas.drawCircle(nodes[i + 1], 4.5 * scale * nodeT, Paint()..color = nodeColors[i + 1]);
      }
    }

    // Halo suave respirando por trás do nó central (o vale do M) —
    // mesma assinatura visual do ícone do app, dá o acabamento elegante
    // sem competir com a leitura da letra.
    final haloT = _stage(0.5, 0.7);
    if (haloT > 0) {
      canvas.drawCircle(
        nodes[2],
        9 * scale * haloT,
        Paint()
          ..color = _gold.withValues(alpha: 0.25 * haloT)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MSynapsePainter oldDelegate) => oldDelegate.progress != progress;
}
