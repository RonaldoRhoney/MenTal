import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../idioma_voices.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pulse_in.dart';

/// MUNDO_IDIOMAS_CONSTELACAO_PALAVRAS_V1.md — Fase 2 (tela). Etapa
/// complementar que aparece automaticamente ao final de todo Desafio do
/// Mundo dos Idiomas (ver challenge_screen.dart::_loadNextChallenge).
/// Tema visual de constelação/galáxia (§5 do documento) — nunca
/// elementos copiados de outro app (sem mascote). Duas variações
/// (`kind`), decididas pelo SERVIDOR, nunca aqui: "pieces" (reconstrução
/// por peças) ou "meaning" (reconhecimento de significado).
class WordConstellationScreen extends StatefulWidget {
  const WordConstellationScreen({super.key, required this.client, required this.challengeId, required this.territoryId});

  final ApiClient client;
  final String challengeId;
  final String territoryId;

  @override
  State<WordConstellationScreen> createState() => _WordConstellationScreenState();
}

class _WordConstellationScreenState extends State<WordConstellationScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _round;

  final List<String> _availableTiles = [];
  final List<String> _selectedTiles = [];
  String? _selectedMeaning;

  bool _submitting = false;
  bool? _correct;
  int _xpAwarded = 0;

  TtsSpeed _ttsSpeed = TtsSpeed.normal;
  bool _ttsSpeaking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final round = await widget.client.wordConstellationRound(widget.challengeId);
      if (!mounted) return;
      setState(() {
        _round = round;
        if (round['kind'] == 'pieces') {
          _availableTiles
            ..clear()
            ..addAll((round['tiles'] as List).cast<String>());
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? get _voice => voiceForTerritory(widget.territoryId);

  Future<void> _speak() async {
    final round = _round;
    final voice = _voice;
    if (round == null || voice == null || _ttsSpeaking) return;
    setState(() => _ttsSpeaking = true);
    await TtsService.instance.speak(round['prompt_text'] as String, voice: voice, speed: _ttsSpeed);
    if (mounted) setState(() => _ttsSpeaking = false);
  }

  void _addTile(String tile) {
    setState(() {
      _availableTiles.remove(tile);
      _selectedTiles.add(tile);
    });
  }

  void _removeTile(int index) {
    setState(() {
      _availableTiles.add(_selectedTiles.removeAt(index));
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final result = await widget.client.completeWordConstellation(
        widget.challengeId,
        submittedOrder: _round!['kind'] == 'pieces' ? _selectedTiles : null,
        submittedMeaning: _round!['kind'] == 'meaning' ? _selectedMeaning : null,
      );
      if (!mounted) return;
      setState(() {
        _correct = result['correct'] as bool;
        _xpAwarded = result['xp_awarded'] as int;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _retry() {
    setState(() {
      _correct = null;
      _xpAwarded = 0;
      if (_round!['kind'] == 'pieces') {
        _availableTiles
          ..clear()
          ..addAll((_round!['tiles'] as List).cast<String>());
        _selectedTiles.clear();
      } else {
        _selectedMeaning = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        title: Text(l10n.wordConstellationScreenTitle),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _StarFieldBackground()),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildBody(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text(_error!, style: TextStyle(color: AppColors.error)));
    }
    final round = _round;
    if (round == null) return const SizedBox.shrink();

    if (_correct != null) return _buildFeedback(l10n);

    final kind = round['kind'] as String;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.wordConstellationInstructionLabel, style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 16),
        Center(
          child: _DuolingoSpeakerButtonLarge(
            speaking: _ttsSpeaking,
            onTap: _voice == null ? null : _speak,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(round['prompt_text'] as String, style: Theme.of(context).textTheme.headlineSmall),
        ),
        const SizedBox(height: 12),
        Center(child: _SpeedChips(speed: _ttsSpeed, onChanged: (s) => setState(() => _ttsSpeed = s))),
        const SizedBox(height: 24),
        Expanded(
          child: kind == 'pieces' ? _buildPiecesUi(l10n) : _buildMeaningUi(l10n),
        ),
        FilledButton(
          onPressed: _canSubmit() && !_submitting ? _submit : null,
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.wordConstellationCheckButton),
        ),
      ],
    );
  }

  bool _canSubmit() {
    final round = _round;
    if (round == null) return false;
    if (round['kind'] == 'pieces') return _selectedTiles.isNotEmpty;
    return _selectedMeaning != null;
  }

  Widget _buildPiecesUi(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Área de montagem — cada peça escolhida é uma "estrela" que se
        // conecta às vizinhas por uma linha fina (§5: "conectando-se
        // visualmente conforme o usuário acerta a ordem").
        Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.bg2,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final indexed in _selectedTiles.asMap().entries)
                _ConstellationTile(
                  label: indexed.value,
                  filled: true,
                  onTap: () => _removeTile(indexed.key),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (final tile in _availableTiles)
              _ConstellationTile(label: tile, filled: false, onTap: () => _addTile(tile)),
          ],
        ),
      ],
    );
  }

  Widget _buildMeaningUi(AppLocalizations l10n) {
    final options = (_round!['options'] as List).cast<String>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final option in options) ...[
          _ConstellationTile(
            label: option,
            filled: _selectedMeaning == option,
            expand: true,
            onTap: () => setState(() => _selectedMeaning = option),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildFeedback(AppLocalizations l10n) {
    final correct = _correct!;
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          correct ? Icons.auto_awesome_rounded : Icons.nightlight_round,
          color: correct ? AppColors.gold : AppColors.muted,
          size: 56,
        ),
        const SizedBox(height: 16),
        Text(
          correct ? l10n.wordConstellationCorrectMessage : l10n.wordConstellationIncorrectMessage,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (correct && _xpAwarded > 0) ...[
          const SizedBox(height: 12),
          Text(
            l10n.wordConstellationXpAwardedMessage(_xpAwarded),
            style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 16),
          ),
        ],
        const SizedBox(height: 32),
        if (correct)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.wordConstellationContinueButton),
          )
        else
          FilledButton(
            onPressed: _retry,
            child: Text(l10n.wordConstellationTryAgainButton),
          ),
      ],
    );
    return Center(child: correct ? PulseIn(child: content) : content);
  }
}

/// Peça/estrela tocável — usada tanto pra reconstrução por peças quanto
/// pra reconhecimento de significado (mesmo componente visual, §5:
/// "pastilhas com brilho sutil").
class _ConstellationTile extends StatelessWidget {
  const _ConstellationTile({required this.label, required this.filled, required this.onTap, this.expand = false});

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final color = filled ? AppColors.gold : AppColors.teal;
    final child = Material(
      color: filled ? color.withValues(alpha: 0.18) : AppColors.bg2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class _DuolingoSpeakerButtonLarge extends StatelessWidget {
  const _DuolingoSpeakerButtonLarge({required this.speaking, required this.onTap});

  final bool speaking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: speaking ? 0.5 : 1,
      child: Material(
        color: AppColors.teal,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.all(18),
            child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }
}

class _SpeedChips extends StatelessWidget {
  const _SpeedChips({required this.speed, required this.onChanged});

  final TtsSpeed speed;
  final ValueChanged<TtsSpeed> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget chip(TtsSpeed value, String label) {
      final selected = speed == value;
      return ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onChanged(value),
        selectedColor: AppColors.teal.withValues(alpha: 0.25),
        labelStyle: TextStyle(color: selected ? AppColors.teal : AppColors.muted, fontSize: 12),
        side: BorderSide(color: selected ? AppColors.teal : AppColors.muted.withValues(alpha: 0.3)),
      );
    }

    return Wrap(
      spacing: 8,
      alignment: WrapAlignment.center,
      children: [
        chip(TtsSpeed.normal, l10n.ttsSpeedNormalLabel),
        chip(TtsSpeed.fast, l10n.ttsSpeedFastLabel),
        chip(TtsSpeed.veryFast, l10n.ttsSpeedVeryFastLabel),
      ],
    );
  }
}

/// Fundo decorativo de estrelas estáticas — mesmo espírito de
/// trajectory_map_screen.dart::_ConstellationBackgroundPainter, versão
/// simplificada (sem caminho de conexão, aqui é só ambientação).
class _StarFieldBackground extends StatelessWidget {
  const _StarFieldBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarFieldPainter());
  }
}

class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.4);
    final random = math.Random(11);
    for (var i = 0; i < 40; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawCircle(Offset(dx, dy), 0.6 + random.nextDouble() * 0.8, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) => false;
}
