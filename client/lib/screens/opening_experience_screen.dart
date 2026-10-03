import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/mental_character.dart';

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
        Opacity(
          opacity: iconProgress,
          child: Transform.scale(
            scale: 0.7 + 0.3 * Curves.easeOutBack.transform(iconProgress),
            // MENTAL_PERSONAGEM_MASCOTE_V1.md §3.1: o personagem substitui
            // o "M com sinapse" antigo aqui — "acenando" (boas-vindas) é a
            // expressão certa pro primeiro instante de abertura do app,
            // mesma tabela de expressões do documento (§4).
            child: const MentalCharacter(
              expression: MentalCharacterExpression.acenando,
              size: 132,
            ),
          ),
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

// _MentalMarkPainter ("M com sinapse" desenhado a mão, stroke-by-stroke)
// foi removido em 03/10/2026 — substituído pelo personagem Mental no
// splash (MENTAL_PERSONAGEM_MASCOTE_V1.md §3.1, decisão explícita de
// Rhoney). Histórico do desenho antigo continua no git caso precise de
// referência.
