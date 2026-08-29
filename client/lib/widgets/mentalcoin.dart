import 'package:flutter/material.dart';

/// Moeda MentalCoins (U.I/MENTALCOINS_V1.md §5) — design circular
/// dourado com acabamento metálico simulado via múltiplas camadas de
/// gradiente radial + "M" em relevo. Reprodução em Flutter puro (sem
/// asset de imagem) do protótipo mental-mentalcoins.html: borda externa,
/// anel interno e highlight superior aproximam a sensação de moeda
/// física sem exigir um asset binário versionado à parte.
class MentalCoin extends StatelessWidget {
  const MentalCoin({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _MentalCoinPainter()),
    );
  }
}

class _MentalCoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;

    // Borda externa serrilhada — remete a moeda física/cripto.
    const notches = 24;
    final rimPath = Path();
    for (var i = 0; i < notches; i++) {
      final angle = (i / notches) * 6.28318530718;
      final nextAngle = ((i + 0.5) / notches) * 6.28318530718;
      final outer = radius;
      final inner = radius * 0.94;
      final p1 = center + Offset.fromDirection(angle, outer);
      final p2 = center + Offset.fromDirection(nextAngle, inner);
      if (i == 0) {
        rimPath.moveTo(p1.dx, p1.dy);
      } else {
        rimPath.lineTo(p1.dx, p1.dy);
      }
      rimPath.lineTo(p2.dx, p2.dy);
    }
    rimPath.close();
    canvas.drawPath(
      rimPath,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFFFDE8A), Color(0xFFFFB238), Color(0xFF7A4212)], stops: [0.0, 0.6, 1.0])
            .createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    // Disco interno.
    canvas.drawCircle(
      center,
      radius * 0.86,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0xFFFFDE8A), Color(0xFFFFB238)], center: Alignment(-0.3, -0.3))
            .createShader(Rect.fromCircle(center: center, radius: radius * 0.86)),
    );

    // Anel interno sutil.
    canvas.drawCircle(
      center,
      radius * 0.68,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.02
        ..color = const Color(0xFF7A4212).withValues(alpha: 0.35),
    );

    // "M" em relevo.
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'M',
        style: TextStyle(
          fontSize: radius * 1.15,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF7A4212),
          shadows: [Shadow(color: Colors.white.withValues(alpha: 0.5), offset: const Offset(0, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2 + radius * 0.03));

    // Highlight superior — reforça sensação de objeto metálico 3D.
    canvas.drawOval(
      Rect.fromCenter(center: center + Offset(-radius * 0.25, -radius * 0.4), width: radius * 0.7, height: radius * 0.35),
      Paint()..color = Colors.white.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
