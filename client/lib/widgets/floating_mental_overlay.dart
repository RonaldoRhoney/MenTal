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

class _FloatingMentalOverlayState extends State<FloatingMentalOverlay> {
  final _controller = FloatingMentalController.instance;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
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
        onPanUpdate: (details) {
          final next = Offset(clamped.dx + details.delta.dx, clamped.dy + details.delta.dy);
          _controller.updatePosition(Offset(
            next.dx.clamp(0, mediaSize.width - kFloatingMentalSize),
            next.dy.clamp(0, mediaSize.height - kFloatingMentalSize),
          ));
        },
        // Tap e long-press só fazem sentido ligado; desligado, só o
        // duplo toque importa (sem `onTap` nesse estado — registrar tap
        // E doubleTap no mesmo GestureDetector obriga o Flutter a
        // esperar ~300ms pra desambiguar, atrasando TODO toque único).
        onTap: enabled ? () => _openPanel(context, l10n) : null,
        onLongPress: enabled ? () => _controller.setEnabled(false) : null,
        onDoubleTap: enabled ? null : () => _controller.setEnabled(true),
        child: Semantics(
          button: true,
          label: enabled ? l10n.floatingMentalSemanticsEnabled : l10n.floatingMentalSemanticsDisabled,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bg2,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: MentalCharacter(
                  expression: MentalCharacterExpression.apontando,
                  size: kFloatingMentalSize - 12,
                ),
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
