import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import '../widgets/celebration_overlay.dart';

/// V3.3 §6 (Jogos de Palavras — Fase 1: Caça-palavras). Diferente de
/// ChallengeScreen (pergunta + múltipla escolha), aqui a grade inteira
/// já vem resolvida do backend — não existe "resposta escondida" pra
/// proteger, é a própria natureza do jogo. Autoridade de XP/tempo
/// continua 100% no backend: o client só informa QUAIS palavras foram
/// encontradas, nunca calcula XP nem confia em duração própria.
class WordSearchScreen extends StatefulWidget {
  const WordSearchScreen({super.key, required this.client, required this.territoryId, required this.territoryLabel});

  final ApiClient client;
  final String territoryId;
  final String territoryLabel;

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _CellPos {
  const _CellPos(this.row, this.col);
  final int row, col;

  @override
  bool operator ==(Object other) => other is _CellPos && other.row == row && other.col == col;
  @override
  int get hashCode => row * 1000 + col;
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  bool _loading = true;
  String? _error;
  bool _notFound = false;

  String? _resultId;
  List<String> _grid = [];
  int _gridSize = 0;
  List<String> _words = [];
  String _theme = '';

  final Set<String> _foundWords = {};
  List<_CellPos> _currentSelection = [];
  final Set<_CellPos> _foundCells = {};
  _CellPos? _dragStart;
  (int, int)? _dragDirection;

  bool _completed = false;
  bool _submitting = false;
  int? _xpAwarded;
  int? _speedBonusXp;

  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  late final CelebrationController _celebration;

  @override
  void initState() {
    super.initState();
    _celebration = CelebrationController();
    _load();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _celebration.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _notFound = false;
    });
    try {
      final result = await widget.client.nextWordPuzzle(widget.territoryId);
      if (!mounted) return;
      setState(() {
        _resultId = result['result_id'] as String;
        _grid = (result['grid'] as List).cast<String>();
        _gridSize = result['grid_size'] as int;
        _words = (result['words'] as List).cast<String>();
        _theme = result['theme'] as String;
        _foundWords.clear();
        _foundCells.clear();
        _completed = false;
        _xpAwarded = null;
        _speedBonusXp = null;
      });
      _startedAt = DateTime.now();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.statusCode == 404) {
          _notFound = true;
        } else {
          _error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _letterAt(_CellPos pos) => _grid[pos.row][pos.col];

  _CellPos? _cellFromLocalPosition(Offset local, double cellSize) {
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (row < 0 || row >= _gridSize || col < 0 || col >= _gridSize) return null;
    return _CellPos(row, col);
  }

  void _onPanStart(Offset local, double cellSize) {
    if (_completed) return;
    final cell = _cellFromLocalPosition(local, cellSize);
    if (cell == null) return;
    setState(() {
      _dragStart = cell;
      _dragDirection = null;
      _currentSelection = [cell];
    });
  }

  void _onPanUpdate(Offset local, double cellSize) {
    final start = _dragStart;
    if (start == null || _completed) return;
    final target = _cellFromLocalPosition(local, cellSize);
    if (target == null) return;

    final dRow = target.row - start.row;
    final dCol = target.col - start.col;
    if (dRow == 0 && dCol == 0) {
      setState(() => _currentSelection = [start]);
      return;
    }

    var direction = _dragDirection;
    // Trava a direção assim que o primeiro movimento significativo
    // acontece — jogo de caça-palavras é sempre em linha reta
    // (horizontal/vertical/diagonal), nunca em zigue-zague.
    direction ??= (dRow.sign, dCol.sign);
    if (_dragDirection == null) setState(() => _dragDirection = direction);

    final (dirRow, dirCol) = direction;
    final length = dirRow != 0 ? (dRow * dirRow) + 1 : (dCol * dirCol) + 1;
    final clampedLength = length.clamp(1, _gridSize);

    final selection = <_CellPos>[];
    for (var i = 0; i < clampedLength; i++) {
      final r = start.row + dirRow * i;
      final c = start.col + dirCol * i;
      if (r < 0 || r >= _gridSize || c < 0 || c >= _gridSize) break;
      selection.add(_CellPos(r, c));
    }
    setState(() => _currentSelection = selection);
  }

  void _onPanEnd() {
    if (_currentSelection.length >= 2) {
      final forward = _currentSelection.map(_letterAt).join();
      final backward = forward.split('').reversed.join();
      final match = _words.firstWhere(
        (w) => !_foundWords.contains(w) && (w == forward || w == backward),
        orElse: () => '',
      );
      if (match.isNotEmpty) {
        FeedbackService.instance.play(FeedbackSound.correct);
        setState(() {
          _foundWords.add(match);
          _foundCells.addAll(_currentSelection);
        });
      }
    }
    setState(() {
      _currentSelection = [];
      _dragStart = null;
      _dragDirection = null;
    });
    if (_foundWords.length == _words.length) _submit();
  }

  Future<void> _submit() async {
    final resultId = _resultId;
    if (resultId == null || _submitting) return;
    setState(() => _submitting = true);
    _ticker?.cancel();
    try {
      final result = await widget.client.completeWordPuzzle(resultId: resultId, foundWords: _foundWords.toList());
      if (!mounted) return;
      final xpAwarded = result['xp_awarded'] as int;
      setState(() {
        _completed = true;
        _xpAwarded = xpAwarded;
        _speedBonusXp = result['speed_bonus_xp'] as int;
      });
      if (xpAwarded > 0) {
        FeedbackService.instance.play(FeedbackSound.celebration);
        if (mounted && !MediaQuery.of(context).disableAnimations) {
          _celebration.celebrate();
        }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.territoryLabel)),
      body: SafeArea(
        child: CelebrationOverlay(
          controller: _celebration,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBody(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_notFound) {
      return Center(
        child: Text(l10n.wordSearchEmptyMessage, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
      );
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: AppColors.error)));
    }

    if (_completed) {
      return _buildCompletedView(l10n);
    }

    final minutes = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_theme, style: Theme.of(context).textTheme.titleMedium),
            Text('$minutes:$seconds', style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellSize = constraints.maxWidth / _gridSize;
              return GestureDetector(
                onPanStart: (details) => _onPanStart(details.localPosition, cellSize),
                onPanUpdate: (details) => _onPanUpdate(details.localPosition, cellSize),
                onPanEnd: (_) => _onPanEnd(),
                child: Container(
                  decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(12)),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _gridSize),
                    itemCount: _gridSize * _gridSize,
                    itemBuilder: (context, index) {
                      final pos = _CellPos(index ~/ _gridSize, index % _gridSize);
                      final isFound = _foundCells.contains(pos);
                      final isSelected = _currentSelection.contains(pos);
                      return Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isFound
                              ? AppColors.victory.withValues(alpha: 0.35)
                              : isSelected
                                  ? AppColors.gold.withValues(alpha: 0.35)
                                  : null,
                        ),
                        child: Text(
                          _letterAt(pos),
                          style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 14).copyWith(fontWeight: FontWeight.w700),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final word in _words)
                  Chip(
                    label: Text(
                      word,
                      style: TextStyle(
                        decoration: _foundWords.contains(word) ? TextDecoration.lineThrough : null,
                        color: _foundWords.contains(word) ? AppColors.muted : AppColors.bone,
                      ),
                    ),
                    backgroundColor: _foundWords.contains(word) ? AppColors.bg : AppColors.bg2,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedView(AppLocalizations l10n) {
    final xp = _xpAwarded ?? 0;
    final speedBonus = _speedBonusXp ?? 0;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.wordSearchCompletedMessage, style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(l10n.wordSearchXpAwardedMessage(xp), style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 18)),
          if (speedBonus > 0) ...[
            const SizedBox(height: 8),
            Text(l10n.wordSearchSpeedBonusMessage(speedBonus), style: TextStyle(color: AppColors.teal)),
          ],
          const SizedBox(height: 24),
          FilledButton(onPressed: _load, child: Text(l10n.nextChallengeButton)),
        ],
      ),
    );
  }
}
