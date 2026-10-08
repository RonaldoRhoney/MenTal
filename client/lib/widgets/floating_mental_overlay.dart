import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../main.dart' show rootNavigatorKey;
import '../screens/coach_screen.dart';
import '../services/floating_mental_controller.dart';
import '../theme/app_theme.dart';
import 'mental_character.dart';

/// MENTAL_AGENTE_FLUTUANTE_V1.md + MENTAL_AGENTE_FLUTUANTE_DIAGNOSTICO_
/// TECNICO_V1.md — personagem flutuante, montado uma única vez no
/// `builder:` do MaterialApp (main.dart), por cima de qualquer tela.
/// Conteúdo do painel de orientação é só texto estático nesta primeira
/// fase (§5 do diagnóstico: categorias dinâmicas tipo "continuar de onde
/// parou" ficam pra uma iteração futura, exigiriam threading de dado de
/// progresso até aqui de fora da árvore normal de telas).
const double kFloatingMentalSize = 64;

class FloatingMentalOverlay extends StatefulWidget {
  const FloatingMentalOverlay({super.key});

  @override
  State<FloatingMentalOverlay> createState() => _FloatingMentalOverlayState();
}

// Achado real testando no aparelho (08/10/2026, Rhoney: "toquei e não
// abre o painel") — combinar `onTap`/`onLongPress` com `onPanUpdate` no
// MESMO GestureDetector faz o reconhecedor de arrasto vencer a arena de
// gestos com o mínimo tremor do dedo (inevitável em qualquer toque
// humano), fazendo o toque nunca disparar. Detecção manual: acompanha
// deslocamento total e duração do toque pra decidir, no `onPanEnd`, se
// foi um toque (abre o painel), uma pressão longa sem mover (desliga)
// ou um arrasto de verdade (já tratado ao vivo pelo onPanUpdate).
const double _kTapSlop = 12;
const Duration _kLongPressDuration = Duration(milliseconds: 500);

class _FloatingMentalOverlayState extends State<FloatingMentalOverlay> with SingleTickerProviderStateMixin {
  final _controller = FloatingMentalController.instance;
  Offset _dragAccumulated = Offset.zero;
  DateTime? _dragStartedAt;
  DateTime? _lastTapAt;

  // MENTAL_AGENTE_FLUTUANTE_V1.md, atualização de 08/10/2026 (pedido de
  // Rhoney): a cada 5s sem toque/arrasto, um pulinho curto convida à
  // interação — atualiza a regra original do documento ("no máximo um
  // sinal discreto, uma vez por sessão"); nunca abre o painel sozinho,
  // só chama atenção visualmente. Qualquer interação (onPanDown abaixo)
  // reinicia a contagem de 5s.
  late final AnimationController _bounceController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  late final Animation<double> _bounceOffset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -16.0).chain(CurveTween(curve: Curves.easeOut)), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -16.0, end: 0.0).chain(CurveTween(curve: Curves.bounceOut)), weight: 1),
  ]).animate(_bounceController);
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
    _scheduleIdleTimer();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _idleTimer?.cancel();
    _bounceController.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  void _scheduleIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer.periodic(const Duration(seconds: 5), (_) => _playIdleBounce());
  }

  void _playIdleBounce() {
    if (!mounted || !_controller.visible) return;
    if (MediaQuery.of(context).disableAnimations) return;
    _bounceController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.visible) return const SizedBox.shrink();

    final mediaSize = MediaQuery.of(context).size;
    final defaultPosition = Offset(
      mediaSize.width - kFloatingMentalSize - 16,
      mediaSize.height - kFloatingMentalSize - 140,
    );
    final position = _controller.position ?? defaultPosition;
    // Clampa a cada rebuild (não só ao arrastar) — cobre rotação de tela
    // e troca de dispositivo (restaurar posição salva num aparelho menor).
    final clamped = Offset(
      position.dx.clamp(0, mediaSize.width - kFloatingMentalSize),
      position.dy.clamp(0, mediaSize.height - kFloatingMentalSize),
    );

    final l10n = AppLocalizations.of(context)!;
    final enabled = _controller.enabled;

    return Positioned(
      left: clamped.dx,
      top: clamped.dy,
      child: GestureDetector(
        onPanDown: (_) {
          _dragAccumulated = Offset.zero;
          _dragStartedAt = DateTime.now();
          _scheduleIdleTimer();
        },
        onPanUpdate: (details) {
          _dragAccumulated += details.delta;
          final next = Offset(clamped.dx + details.delta.dx, clamped.dy + details.delta.dy);
          _controller.updatePosition(Offset(
            next.dx.clamp(0, mediaSize.width - kFloatingMentalSize),
            next.dy.clamp(0, mediaSize.height - kFloatingMentalSize),
          ));
        },
        onPanEnd: (_) {
          final startedAt = _dragStartedAt;
          final movedEnough = _dragAccumulated.distance > _kTapSlop;
          _dragStartedAt = null;
          if (movedEnough || startedAt == null) return; // arrasto de verdade, já aplicado acima.

          final heldFor = DateTime.now().difference(startedAt);
          if (!enabled) {
            // Desligado: só duplo toque reativa — dois toques rápidos
            // (mesmo critério de "não moveu") dentro de 350ms.
            final now = DateTime.now();
            final last = _lastTapAt;
            _lastTapAt = now;
            if (last != null && now.difference(last) < const Duration(milliseconds: 350)) {
              _lastTapAt = null;
              _controller.setEnabled(true);
            }
            return;
          }
          if (heldFor >= _kLongPressDuration) {
            _controller.setEnabled(false);
          } else {
            _openPanel(context, l10n);
          }
        },
        child: Semantics(
          button: true,
          label: enabled ? l10n.floatingMentalSemanticsEnabled : l10n.floatingMentalSemanticsDisabled,
          // Ação semântica própria (leitor de tela ativa por gesto
          // diferente do toque físico) — independente da detecção
          // manual de toque/arrasto acima, que é só pro dedo na tela.
          onTap: enabled ? () => _openPanel(context, l10n) : () => _controller.setEnabled(true),
          child: AnimatedBuilder(
            animation: _bounceOffset,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _bounceOffset.value),
              child: child,
            ),
            child: Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: const MentalCharacter(
                expression: MentalCharacterExpression.apontando,
                size: kFloatingMentalSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPanel(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => _FloatingMentalPanel(l10n: l10n),
    );
  }
}

class _FloatingMentalPanel extends StatelessWidget {
  const _FloatingMentalPanel({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final tips = [
      (l10n.floatingMentalTipStartTitle, l10n.floatingMentalTipStartBody),
      (l10n.floatingMentalTipModesTitle, l10n.floatingMentalTipModesBody),
      (l10n.floatingMentalTipStreakTitle, l10n.floatingMentalTipStreakBody),
      (l10n.floatingMentalTipRewardsTitle, l10n.floatingMentalTipRewardsBody),
      (l10n.floatingMentalTipMapTitle, l10n.floatingMentalTipMapBody),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const MentalCharacter(expression: MentalCharacterExpression.felizNeutro, size: 40),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.floatingMentalPanelTitle, style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 16),
            for (final (title, body) in tips) ...[
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.gold)),
              const SizedBox(height: 2),
              Text(body, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 14),
            ],
            if (FloatingMentalController.instance.currentClient case final client?)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    rootNavigatorKey.currentState?.push(
                      MaterialPageRoute(builder: (_) => CoachScreen(client: client)),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: Text(l10n.floatingMentalSeeMoreTips),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
