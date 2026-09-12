import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// PROMPT_CLAUDE_CODE_SPLASH_REDESIGN_V2.md (12/09/2026, aprovado) —
/// substitui os DOIS splashes sequenciais anteriores (SplashScreen +
/// WelcomeSplashScreen, 2.2s + 5.8s = 8s de atraso artificial, 3,2× a
/// 6,7× acima da faixa-alvo de 1,2-2,5s do documento) por uma única
/// experiência de abertura. Roda uma vez por processo (cold start),
/// antes de qualquer decisão de Login/Age Gate/Home — main.dart decide
/// o destino real via [onDone], igual o SplashScreen antigo fazia.
///
/// Duração fixa de 2400ms (perto do teto da faixa-alvo de 1,2-2,5s) —
/// nunca estica além disso esperando rede/backend (Seção 14 do
/// documento: "não adicionar atraso artificial"); o tempo extra em
/// relação à v1 (1800ms) é todo investido em respiro entre os estágios
/// e curvas de entrada mais lentas (pedido de Rhoney, 12/09/2026:
/// "está muito rápida... devem surgir elegantemente, como se estivesse
/// elevando toda a experiência do App"), não em atraso vazio. Se o app
/// tiver "reduzir movimento" ativado no sistema (Seção 16), pula direto
/// pro estado final com uma transição mínima em vez de tocar a
/// animação inteira.
class OpeningExperienceScreen extends StatefulWidget {
  const OpeningExperienceScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OpeningExperienceScreen> createState() => _OpeningExperienceScreenState();
}

class _OpeningExperienceScreenState extends State<OpeningExperienceScreen>
    with SingleTickerProviderStateMixin {
  static const _fullDuration = Duration(milliseconds: 2400);
  static const _reducedMotionDuration = Duration(milliseconds: 350);

  late final AnimationController _controller;
  bool _reducedMotion = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _fullDuration);
    _controller.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Só decide reduced-motion aqui (não em initState): MediaQuery só
    // fica disponível depois que a árvore de widgets está montada. Só
    // dispara o forward() uma vez — didChangeDependencies pode rodar de
    // novo depois (ex.: mudança de tema/locale), e reiniciar a animação
    // nesse caso reabriria o splash no meio do uso do app.
    if (_started) return;
    _started = true;
    _reducedMotion = MediaQuery.of(context).disableAnimations;
    _controller.duration = _reducedMotion ? _reducedMotionDuration : _fullDuration;
    _controller.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      widget.onDone();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatus);
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            // Sem movimento reduzido: tudo já visível, sem timeline —
            // só a Scaffold aparecendo já é a transição.
            if (_reducedMotion) {
              return const _OpeningContent(iconProgress: 1, wordmarkT: 1, sloganT: 1);
            }
            // Estados 2-4 (Ativação/Conexão/Concentração): ícone se
            // forma nos primeiros 55% do tempo. Estados 5-6
            // (Identidade/Ativação final): wordmark e depois o slogan
            // oficial (Seção 0.1 — nunca a frase alternativa) entram
            // encadeados, cada um só depois que o anterior já tem
            // espaço próprio, nunca todos se sobrepondo de uma vez.
            final iconT = Curves.easeOutCubic.transform(_stage(t, 0.0, 0.55));
            final wordmarkT = Curves.easeOut.transform(_stage(t, 0.60, 0.78));
            final sloganT = Curves.easeOut.transform(_stage(t, 0.82, 0.96));
            return _OpeningContent(iconProgress: iconT, wordmarkT: wordmarkT, sloganT: sloganT);
          },
        ),
      ),
    );
  }
}

class _OpeningContent extends StatelessWidget {
  const _OpeningContent({required this.iconProgress, required this.wordmarkT, required this.sloganT});

  final double iconProgress;
  final double wordmarkT;
  final double sloganT;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: CustomPaint(painter: _MentalMarkPainter(progress: iconProgress)),
        ),
        const SizedBox(height: 22),
        Opacity(
          opacity: wordmarkT,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - wordmarkT)),
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
  }
}

/// Desenha o "M" de MENTAL como uma cadeia de 5 nós (sinapses) ligados
/// por 4 hastes, na silhueta da letra — mesmo conceito visual já
/// validado no WelcomeSplashScreen anterior (achado real de 2026-08-26:
/// "deve desenhar um M completo, com as sinapses cognitivas"), mas
/// agora:
/// (a) cores lidas de AppColors.gold/teal (reage a claro/escuro, Seção
///     0.2/17 do documento — antes eram Color(...) fixos, duplicando
///     o token em vez de reaproveitá-lo);
/// (b) timeline comprimida pra caber nos ~1000ms de orçamento desta
///     etapa (era uma animação de 4800ms sozinha).
///
/// Nota de limitação (Seção 26.11): o ícone real do launcher
/// (`ic_launcher_foreground.png`) é uma silhueta de cabeça com um
/// gráfico em zigue-zague + chevron, visualmente diferente deste "M"
/// literal — os dois hoje representam a marca de formas diferentes.
/// Convergir pixel-a-pixel pro desenho do launcher exigiria redesenhar
/// aquele ícone (fora do escopo deste redesign, que é só a experiência
/// de abertura) — registrado aqui como recomendação de acompanhamento,
/// não resolvido nesta entrega.
class _MentalMarkPainter extends CustomPainter {
  _MentalMarkPainter({required this.progress});

  final double progress;

  double _stage(double start, double end) {
    if (progress <= start) return 0;
    if (progress >= end) return 1;
    return (progress - start) / (end - start);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100;
    Offset p(double x, double y) => Offset(x * scale, y * scale);

    final gold = AppColors.gold;
    final teal = AppColors.teal;

    // Vértices do M, na ordem em que a letra é "escrita": base
    // esquerda → topo esquerdo → vale central → topo direito → base
    // direita.
    final nodes = [p(28, 70), p(28, 30), p(50, 52), p(72, 30), p(72, 70)];
    final segmentColors = [gold, teal, teal, gold];
    final nodeColors = [gold, teal, gold, teal, gold];

    final firstNodeScale = Curves.elasticOut.transform(_stage(0.0, 0.12).clamp(0.0, 1.0));
    if (firstNodeScale <= 0) return;
    canvas.drawCircle(nodes[0], 4.5 * scale * firstNodeScale, Paint()..color = nodeColors[0]);

    const segmentSpan = 0.16;
    const segmentGap = 0.03;
    for (var i = 0; i < 4; i++) {
      final start = 0.10 + i * (segmentSpan + segmentGap);
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
      final nodeT = Curves.easeOutBack.transform(_stage(end - 0.04, end + 0.03).clamp(0.0, 1.0));
      if (nodeT > 0) {
        canvas.drawCircle(nodes[i + 1], 4.5 * scale * nodeT, Paint()..color = nodeColors[i + 1]);
      }
    }

    // Halo suave respirando por trás do nó central (o vale do M) — o
    // pulso de "ativação final" (Estado 6), bem sutil, nunca competindo
    // com a leitura da letra.
    final haloT = _stage(0.78, 1.0);
    if (haloT > 0) {
      canvas.drawCircle(
        nodes[2],
        9 * scale * haloT,
        Paint()
          ..color = gold.withValues(alpha: 0.25 * haloT)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2 * scale,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MentalMarkPainter oldDelegate) => oldDelegate.progress != progress;
}
