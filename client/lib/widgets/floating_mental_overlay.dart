import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../coach_helpers.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/floating_mental_controller.dart';
import '../theme/app_theme.dart';
import 'mental_character.dart';

/// MENTAL_AGENTE_FLUTUANTE_V1.md + MENTAL_AGENTE_FLUTUANTE_DIAGNOSTICO_
/// TECNICO_V1.md — personagem flutuante, montado uma única vez no
/// `builder:` do MaterialApp (main.dart), por cima de qualquer tela.
///
/// Atualização de 08/10/2026 (pedido de Rhoney: "My_Mental_AI deve ser
/// removido e o agente flutuante assume seu lugar com todas suas
/// características") — o painel não mostra mais dicas estáticas: ele
/// chama GET /coach (mesma análise por regras, custo zero, que alimentava
/// a extinta CoachScreen/MyMentalAiWorldCard — backend/app/coach.py
/// continua intocado) e mostra o resumo + cartões de verdade, calculados
/// a partir do progresso real do usuário.
const double kFloatingMentalSize = 64;

class FloatingMentalOverlay extends StatefulWidget {
  const FloatingMentalOverlay({super.key});

  @override
  State<FloatingMentalOverlay> createState() => _FloatingMentalOverlayState();
}

// Achado real testando no aparelho (08/10/2026, 3 rodadas): combinar
// onTap/onLongPress/onPanUpdate no mesmo GestureDetector (1ª rodada) e
// depois onPanDown/onPanEnd/onPanCancel do PRÓPRIO GestureDetector (2ª
// rodada, pensando ter corrigido via onPanCancel) continuaram sem
// responder a toque real no aparelho, mesmo com teste automatizado
// (tester.tap, movimento zero sintético) passando — a lógica de arena
// de gestos do GestureDetector por trás de onPan* tem nuances de
// threshold que não reproduzem fácil fora do dispositivo real. Troca
// pra `Listener`: eventos de ponteiro CRUS (down/move/up/cancel), sem
// nenhum reconhecedor/arena no meio — zero ambiguidade.
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
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          _dragAccumulated = Offset.zero;
          _dragStartedAt = DateTime.now();
          _scheduleIdleTimer();
        },
        onPointerMove: (event) {
          _dragAccumulated += event.delta;
          final next = Offset(clamped.dx + event.delta.dx, clamped.dy + event.delta.dy);
          _controller.updatePosition(Offset(
            next.dx.clamp(0, mediaSize.width - kFloatingMentalSize),
            next.dy.clamp(0, mediaSize.height - kFloatingMentalSize),
          ));
        },
        onPointerUp: (_) => _handlePanFinished(context, l10n, enabled),
        onPointerCancel: (_) => _handlePanFinished(context, l10n, enabled),
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

  void _handlePanFinished(BuildContext context, AppLocalizations l10n, bool enabled) {
    final startedAt = _dragStartedAt;
    final movedEnough = _dragAccumulated.distance > _kTapSlop;
    _dragStartedAt = null;
    if (movedEnough || startedAt == null) return; // arrasto de verdade, já aplicado ao vivo no onPanUpdate.

    final heldFor = DateTime.now().difference(startedAt);
    if (!enabled) {
      // Desligado: só duplo toque reativa — dois toques rápidos (mesmo
      // critério de "não moveu") dentro de 350ms.
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
  }

  void _openPanel(BuildContext context, AppLocalizations l10n) {
    final client = FloatingMentalController.instance.currentClient;
    if (client == null) return; // painel exige conta (sem fluxo guest aqui — ver §3 do diagnóstico).
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FloatingMentalPanel(client: client),
    );
  }
}

class _FloatingMentalPanel extends StatefulWidget {
  const _FloatingMentalPanel({required this.client});

  final ApiClient client;

  @override
  State<_FloatingMentalPanel> createState() => _FloatingMentalPanelState();
}

class _FloatingMentalPanelState extends State<_FloatingMentalPanel> {
  Map<String, dynamic>? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final data = await widget.client.getCoach();
      if (mounted) setState(() => _data = data);
    } on ApiException {
      if (mounted && _data == null) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _data;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return SafeArea(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Row(
                children: [
                  const MentalCharacter(expression: MentalCharacterExpression.felizNeutro, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Text(l10n.floatingMentalPanelTitle, style: Theme.of(context).textTheme.titleLarge)),
                ],
              ),
              const SizedBox(height: 4),
              Text(l10n.coachSubtitle, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              if (data == null && !_failed)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_failed)
                Column(children: [
                  Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.muted),
                  const SizedBox(height: 8),
                  Text(l10n.coachLoadError, textAlign: TextAlign.center),
                  TextButton(onPressed: _load, child: Text(l10n.feedbackReloadButton)),
                ])
              else ...[
                _SummaryRow(summary: data!['summary'] as Map<String, dynamic>),
                const SizedBox(height: 16),
                for (final c in (data['cards'] as List).cast<Map<String, dynamic>>())
                  _CoachCard(card: c, client: widget.client, onReturned: _load),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accuracy = ((summary['accuracy'] as num) * 100).round();
    final rank = summary['weekly_rank'];
    Widget chip(IconData icon, String label) => Chip(
          avatar: Icon(icon, size: 16, color: AppColors.gold),
          label: Text(label, style: const TextStyle(fontSize: 12)),
        );
    return Wrap(
      key: const Key('coach_summary'),
      spacing: 8,
      runSpacing: 4,
      children: [
        chip(Icons.check_circle_outline_rounded, l10n.coachSummaryAnswers(summary['total_answers'] as int)),
        if ((summary['total_answers'] as int) > 0) chip(Icons.percent_rounded, l10n.coachSummaryAccuracy(accuracy)),
        chip(Icons.bolt_rounded, l10n.coachSummaryWeekXp(summary['weekly_xp'] as int)),
        if (rank != null) chip(Icons.leaderboard_rounded, l10n.coachSummaryRank(rank as int)),
      ],
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.card, required this.client, required this.onReturned});

  final Map<String, dynamic> card;
  final ApiClient client;
  final VoidCallback onReturned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final territoryId = card['territory_id'] as String?;
    final action = card['action'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        key: Key('coach_card_${card['id']}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(coachIcon(card['id'] as String), color: AppColors.gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(coachText(l10n, card['title'] as String, territoryId),
                      style: Theme.of(context).textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(coachText(l10n, card['body'] as String, territoryId), style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  key: Key('coach_action_${card['id']}'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () async {
                    // Sem pop antes: o destino abre POR CIMA do painel (que
                    // é um modal bottom sheet), mesmo padrão já usado pela
                    // extinta CoachScreen (tela cheia, nunca fechava
                    // sozinha) — evita usar um context de widget prestes a
                    // ser desmontado.
                    await openCoachAction(context, client, action);
                    onReturned();
                  },
                  child: Text(l10n.coachGoButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
