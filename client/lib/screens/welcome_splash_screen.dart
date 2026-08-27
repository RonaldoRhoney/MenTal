import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Splash de boas-vindas exibido uma vez por sessão, logo depois do login
/// (e da confirmação de maioridade, se for a primeira vez) — diferente do
/// SplashScreen inicial (que roda ANTES de qualquer decisão de destino).
/// Reconstrói o símbolo do ícone do app (nó central + sinapses douradas/
/// teal, mesmas coordenadas de assets/icon/mental_icon.svg) como um
/// CustomPainter animado, no mesmo espírito de _GoogleGlyphPainter em
/// login_screen.dart — vetorial, sem depender de imagem rasterizada.
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
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();
    Future.delayed(const Duration(milliseconds: 2700), () {
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
            final wordmarkT = Curves.easeOut.transform(_stage(t, 0.5, 0.75));
            final sloganT = Curves.easeOut.transform(_stage(t, 0.7, 0.95));
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 148,
                  height: 148,
                  child: CustomPaint(painter: _SynapseSplashPainter(progress: t)),
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

class _SynapseSplashPainter extends CustomPainter {
  _SynapseSplashPainter({required this.progress});

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
    final center = p(50, 47);

    // Estágio 1 — nó central "nasce" com um leve exagero elástico
    // (Curves.elasticOut), dando o toque de energia/vida que pediu.
    final centerScale = Curves.elasticOut.transform(_stage(0.0, 0.4).clamp(0.0, 1.0));
    if (centerScale <= 0) return;

    // Estágio 2 — as 3 sinapses "crescem" do centro pros nós externos.
    final lineT = Curves.easeOut.transform(_stage(0.3, 0.68));
    final outerPoints = [p(33, 33), p(69, 37), p(63, 62)];
    final outerColors = [_gold, _gold, _teal];
    for (var i = 0; i < outerPoints.length; i++) {
      final end = Offset.lerp(center, outerPoints[i], lineT)!;
      canvas.drawLine(
        center,
        end,
        Paint()
          ..color = outerColors[i]
          ..strokeWidth = 2.4 * scale
          ..strokeCap = StrokeCap.round,
      );
    }

    // Estágio 3 — nós externos "acendem" com um pequeno bounce.
    final nodeT = Curves.easeOutBack.transform(_stage(0.6, 0.9).clamp(0.0, 1.0));
    if (nodeT > 0) {
      for (var i = 0; i < outerPoints.length; i++) {
        canvas.drawCircle(outerPoints[i], 4.5 * scale * nodeT, Paint()..color = outerColors[i]);
      }
    }

    // Nó central por cima de tudo, com o halo suave já usado no ícone.
    canvas.drawCircle(
      center,
      10 * scale * centerScale,
      Paint()
        ..color = _gold.withValues(alpha: 0.3 * centerScale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale,
    );
    canvas.drawCircle(center, 6.5 * scale * centerScale, Paint()..color = _gold);
  }

  @override
  bool shouldRepaint(covariant _SynapseSplashPainter oldDelegate) => oldDelegate.progress != progress;
}
