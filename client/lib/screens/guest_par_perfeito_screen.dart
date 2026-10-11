import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart' show ApiException;
import '../api/guest_api_client.dart';
import '../idioma_voices.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../services/guest_challenge_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import 'partial_result_screen.dart';

/// Pedido de Rhoney (10/10/2026): os 3 primeiros desafios sem login do
/// Mundo dos Idiomas passam a ser Par Perfeito (Inglês básico), não o
/// quiz de múltipla escolha. Motor visual (colunas, linhas, shake,
/// paleta) replicado de screens/par_perfeito_screen.dart — a tela
/// autenticada não é reutilizável diretamente porque ApiClient exige
/// token no construtor (ver comentário em guest_api_client.dart) — mas
/// a rodada aqui é SEMPRE o território/rodada fixos do guest
/// (GUEST_PAR_PERFEITO_ROUND_SIZE pares, nunca os 5 do jogo
/// autenticado) e nunca credita XP real aqui: só guarda round_token +
/// item_ids formados sem erro (GuestChallengeService), migrados de
/// verdade por POST /guest/migrate-progress depois do cadastro.
class GuestParPerfeitoScreen extends StatefulWidget {
  const GuestParPerfeitoScreen({super.key, required this.baseUrl});

  final String baseUrl;

  @override
  State<GuestParPerfeitoScreen> createState() => _GuestParPerfeitoScreenState();
}

List<Color> get _kMatchPalette => [AppColors.gold, AppColors.teal, AppColors.purple];

class _GuestParPerfeitoScreenState extends State<GuestParPerfeitoScreen> {
  late final GuestApiClient _guestClient = GuestApiClient(baseUrl: widget.baseUrl);

  List<Map<String, dynamic>>? _items;
  String? _roundToken;
  List<Map<String, dynamic>> _leftCards = [];
  List<Map<String, dynamic>> _rightCards = [];
  String? _selectedLeftId;
  final Set<String> _matchedIds = {};
  final Set<String> _firstTryCorrectIds = {};
  final Set<String> _wrongAttemptIds = {};
  final Map<String, Color> _matchedColor = {};
  bool _loading = true;
  String? _error;
  bool _roundFinished = false;

  final _stackKey = GlobalKey();
  final Map<String, GlobalKey> _leftPositionKeys = {};
  final Map<String, GlobalKey> _rightPositionKeys = {};
  final Map<String, GlobalKey<_ShakeCardState>> _leftShakeKeys = {};
  final Map<String, GlobalKey<_ShakeCardState>> _rightShakeKeys = {};
  final List<_LineSegment> _lines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _matchedIds.clear();
      _firstTryCorrectIds.clear();
      _wrongAttemptIds.clear();
      _lines.clear();
      _selectedLeftId = null;
      _roundFinished = false;
    });
    try {
      final round = await _guestClient.nextParPerfeitoRound();
      final items = (round['items'] as List).cast<Map<String, dynamic>>();
      final roundToken = round['round_token'] as String;
      final left = items
          .map((i) => {'id': i['id'] as String, 'text': i['word_en'] as String})
          .toList()
        ..shuffle();
      final right = items
          .map((i) => {'id': i['id'] as String, 'text': i['meaning_pt'] as String})
          .toList()
        ..shuffle();
      _leftPositionKeys.clear();
      _rightPositionKeys.clear();
      _leftShakeKeys.clear();
      _rightShakeKeys.clear();
      for (final item in items) {
        final id = item['id'] as String;
        _leftPositionKeys[id] = GlobalKey();
        _rightPositionKeys[id] = GlobalKey();
        _leftShakeKeys[id] = GlobalKey<_ShakeCardState>();
        _rightShakeKeys[id] = GlobalKey<_ShakeCardState>();
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _roundToken = roundToken;
        _leftCards = left;
        _rightCards = right;
        _loading = false;
      });
      for (final item in items) {
        TtsService.instance.preload(item['word_en'] as String, voice: voiceForParPerfeitoAccent(ParPerfeitoAccent.us));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _onTapLeft(String id) {
    if (_matchedIds.contains(id)) return;
    setState(() => _selectedLeftId = _selectedLeftId == id ? null : id);
  }

  void _onTapRight(String id) {
    if (_matchedIds.contains(id)) return;
    final selected = _selectedLeftId;
    if (selected == null) return;

    if (selected == id) {
      if (!_wrongAttemptIds.contains(id)) _firstTryCorrectIds.add(id);
      final palette = _kMatchPalette;
      final color = palette[_matchedIds.length % palette.length];
      setState(() {
        _matchedIds.add(id);
        _matchedColor[id] = color;
        _selectedLeftId = null;
      });
      FeedbackService.instance.play(FeedbackSound.correct);
      final wordEn = _items!.firstWhere((i) => i['id'] == id)['word_en'] as String;
      TtsService.instance.speak(wordEn, voice: voiceForParPerfeitoAccent(ParPerfeitoAccent.us));
      WidgetsBinding.instance.addPostFrameCallback((_) => _drawLineFor(id, color));
      if (_matchedIds.length == _items!.length) {
        Future.delayed(const Duration(milliseconds: 700), _finishRound);
      }
    } else {
      _wrongAttemptIds.add(selected);
      _wrongAttemptIds.add(id);
      _leftShakeKeys[selected]?.currentState?.shake();
      _rightShakeKeys[id]?.currentState?.shake();
      FeedbackService.instance.play(FeedbackSound.incorrect);
      setState(() => _selectedLeftId = null);
    }
  }

  void _drawLineFor(String id, Color color) {
    final stackBox = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    final leftBox = _leftPositionKeys[id]?.currentContext?.findRenderObject() as RenderBox?;
    final rightBox = _rightPositionKeys[id]?.currentContext?.findRenderObject() as RenderBox?;
    if (stackBox == null || leftBox == null || rightBox == null) return;
    final start = stackBox.globalToLocal(leftBox.localToGlobal(leftBox.size.centerRight(Offset.zero)));
    final end = stackBox.globalToLocal(rightBox.localToGlobal(rightBox.size.centerLeft(Offset.zero)));
    if (!mounted) return;
    setState(() => _lines.add(_LineSegment(start, end, color)));
  }

  Future<void> _finishRound() async {
    if (!mounted) return;
    await GuestChallengeService.setParPerfeitoProgress(GuestParPerfeitoProgress(
      roundToken: _roundToken!,
      firstTryCorrectItemIds: _firstTryCorrectIds.toList(),
    ));
    if (!mounted) return;
    setState(() => _roundFinished = true);
  }

  void _continue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const PartialResultScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.guestParPerfeitoTitle)),
      body: SafeArea(child: _buildBody(context, l10n)),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: Text(l10n.tryAgainButton)),
            ],
          ),
        ),
      );
    }
    if (_roundFinished) return _buildRoundSummary(context, l10n);

    final total = _items!.length;
    final done = _matchedIds.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.parPerfeitoInstruction,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        tween: Tween(begin: 0, end: total == 0 ? 0 : done / total),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 8,
                          backgroundColor: AppColors.bg2,
                          color: AppColors.gold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$done/$total',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            key: _stackKey,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Center(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildColumn(_leftCards, isLeft: true)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildColumn(_rightCards, isLeft: false)),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(child: CustomPaint(painter: _LinesPainter(_lines))),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColumn(List<Map<String, dynamic>> cards, {required bool isLeft}) {
    final children = <Widget>[];
    for (var index = 0; index < cards.length; index++) {
      if (index > 0) children.add(const SizedBox(height: 14));
      children.add(_buildCard(cards[index], index, isLeft: isLeft));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }

  Widget _buildCard(Map<String, dynamic> card, int index, {required bool isLeft}) {
    final id = card['id'] as String;
    final matched = _matchedIds.contains(id);
    final selected = isLeft && _selectedLeftId == id;
    final shakeKey = isLeft ? _leftShakeKeys[id] : _rightShakeKeys[id];
    final positionKey = isLeft ? _leftPositionKeys[id] : _rightPositionKeys[id];
    final matchColor = _matchedColor[id];

    return _StaggeredEntrance(
      index: index,
      child: _ShakeCard(
        key: shakeKey,
        child: AnimatedScale(
          scale: matched ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Material(
            key: positionKey,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: matched ? null : () => isLeft ? _onTapLeft(id) : _onTapRight(id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                constraints: const BoxConstraints(minHeight: 72),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: matched
                      ? matchColor?.withValues(alpha: 0.16)
                      : selected
                          ? AppColors.gold.withValues(alpha: 0.16)
                          : AppColors.bg2,
                  border: Border.all(
                    color: matched
                        ? matchColor ?? AppColors.teal
                        : selected
                            ? AppColors.gold
                            : AppColors.muted.withValues(alpha: 0.28),
                    width: selected || matched ? 2 : 1,
                  ),
                  boxShadow: [
                    if (matched)
                      BoxShadow(color: (matchColor ?? AppColors.teal).withValues(alpha: 0.35), blurRadius: 14, spreadRadius: 1)
                    else if (selected)
                      BoxShadow(color: AppColors.gold.withValues(alpha: 0.25), blurRadius: 10)
                    else
                      BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        card['text'] as String,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: matched || selected ? FontWeight.w600 : FontWeight.normal,
                              color: matched ? matchColor : null,
                            ),
                      ),
                    ),
                    if (matched) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.check_circle_rounded, size: 18, color: matchColor),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundSummary(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.parPerfeitoRoundSummary(_items!.length),
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            FilledButton(onPressed: _continue, child: Text(l10n.guestAnswerContinue)),
          ],
        ),
      ),
    );
  }
}

class _LineSegment {
  const _LineSegment(this.start, this.end, this.color);
  final Offset start;
  final Offset end;
  final Color color;
}

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.lines);
  final List<_LineSegment> lines;

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      final glowPaint = Paint()
        ..color = line.color.withValues(alpha: 0.45)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
      canvas.drawLine(line.start, line.end, glowPaint);
      final corePaint = Paint()
        ..color = line.color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(line.start, line.end, corePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter oldDelegate) => oldDelegate.lines.length != lines.length;
}

class _ShakeCard extends StatefulWidget {
  const _ShakeCard({super.key, required this.child});
  final Widget child;

  @override
  State<_ShakeCard> createState() => _ShakeCardState();
}

class _ShakeCardState extends State<_ShakeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  late final Animation<double> _offset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: -5.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: 1),
  ]).animate(_controller);

  void shake() {
    if (MediaQuery.of(context).disableAnimations) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (context, child) => Transform.translate(offset: Offset(_offset.value, 0), child: child),
      child: widget.child,
    );
  }
}

class _StaggeredEntrance extends StatefulWidget {
  const _StaggeredEntrance({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredEntrance> createState() => _StaggeredEntranceState();
}

class _StaggeredEntranceState extends State<_StaggeredEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final Animation<double> _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 1.0;
      return;
    }
    Future.delayed(Duration(milliseconds: 40 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return FadeTransition(opacity: _opacity, child: SlideTransition(position: _slide, child: widget.child));
  }
}
