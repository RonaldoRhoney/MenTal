import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../idioma_voices.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
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
  const WordConstellationScreen({
    super.key,
    required this.client,
    required this.challengeId,
    required this.territoryId,
    this.difficultyLevel,
  });

  final ApiClient client;
  final String challengeId;
  final String territoryId;
  // MUNDO_IDIOMAS_IMERSAO_PROGRESSIVA_V1.md §5: a partir do nível
  // Difícil (avancado, difficulty_level 3) o texto de instrução em
  // português some — o Desafio de origem já foi 100% no idioma-alvo,
  // e esta etapa não pode "regredir" para português. null (não
  // propagado) equivale a Fácil, mantém a instrução.
  final int? difficultyLevel;

  bool get _immersaoTotal => (difficultyLevel ?? 0) >= 3;

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
      _preloadTts(round);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Achado real em dispositivo (19/09/2026): nem todo prompt de
      // Idiomas bate 100% com os 2 templates fixos assumidos na
      // extração de significado (extract_portuguese_meaning) — quando
      // isso acontece, a etapa é só PULADA (fecha sozinha), nunca vira
      // um beco sem saída pro jogador. Constelação é reforço, nunca
      // pode travar o fluxo principal do Desafio.
      if (e.code == 'MEANING_NOT_EXTRACTABLE') {
        Navigator.of(context).pop();
        return;
      }
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? get _voice => voiceForTerritory(widget.territoryId);

  // Pedido de Rhoney (19/09/2026): "o áudio ... está com uma certa
  // demora, ajuste para que seja ao toque" — pré-sintetiza (sem tocar)
  // assim que a rodada carrega, pra que o toque real no botão já
  // encontre o áudio em cache (TtsService.preload).
  void _preloadTts(Map<String, dynamic> round) {
    final voice = _voice;
    if (voice == null) return;
    TtsService.instance.preload(round['prompt_text'] as String, voice: voice, speed: _ttsSpeed);
    if (round['kind'] == 'pieces') {
      for (final tile in (round['tiles'] as List).cast<String>()) {
        TtsService.instance.preload(tile, voice: voice, speed: _ttsSpeed);
      }
    }
  }

  Future<void> _speak() async {
    final round = _round;
    final voice = _voice;
    if (round == null || voice == null || _ttsSpeaking) return;
    setState(() => _ttsSpeaking = true);
    await TtsService.instance.speak(round['prompt_text'] as String, voice: voice, speed: _ttsSpeed);
    if (mounted) setState(() => _ttsSpeaking = false);
  }

  // Pedido de Rhoney (19/09/2026): cada peça também precisa de áudio
  // próprio, não só o texto inteiro no botão do topo — só faz sentido
  // nas PEÇAS (idioma estranho), nunca nas opções de significado
  // (português, voz errada pra elas).
  Future<void> _speakTile(String tile) async {
    final voice = _voice;
    if (voice == null || _ttsSpeaking) return;
    setState(() => _ttsSpeaking = true);
    await TtsService.instance.speak(tile, voice: voice, speed: _ttsSpeed);
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
      final correct = result['correct'] as bool;
      // Pedido de Rhoney (19/09/2026, teste real): som de acerto/erro na
      // própria resposta, mesmo padrão já usado em challenge_screen.dart.
      unawaited(FeedbackService.instance.play(correct ? FeedbackSound.correct : FeedbackSound.incorrect));
      setState(() {
        _correct = correct;
        _xpAwarded = result['xp_awarded'] as int;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // Pedido de Rhoney (19/09/2026, teste real no dispositivo): na rodada
  // "meaning", tocar numa opção já vale como resposta — o som de
  // acerto/erro (tocado dentro de _submit) acontece na própria palavra
  // tocada, sem precisar de um botão "Verificar" separado.
  void _selectMeaningAndSubmit(String option) {
    setState(() => _selectedMeaning = option);
    _submit();
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
        if (!widget._immersaoTotal) ...[
          Text(l10n.wordConstellationInstructionLabel, style: TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 16),
        ],
        // Pedido de Rhoney (19/09/2026, teste real): quando o Desafio de
        // origem já tem uma ilustração de vocabulário (vocab_media_url,
        // gerada via Canva — scripts/upload_vocab_media.py), ela
        // substitui o cartão de texto+áudio do topo. Nunca fabricada
        // aqui — só aparece se já existir. §4.3 (correção obrigatória,
        // 19/09/2026): sem ilustração, o áudio da palavra/frase-alvo
        // precisa estar vinculado ao próprio elemento textual clicável
        // (mesmo princípio de MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md §2.2.2).
        if (round['vocab_media_url'] != null) ...[
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                round['vocab_media_url'] as String,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _TargetPromptCard(
                  text: round['prompt_text'] as String,
                  speaking: _ttsSpeaking,
                  onTap: _voice == null ? null : _speak,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          Center(
            child: _TargetPromptCard(
              text: round['prompt_text'] as String,
              speaking: _ttsSpeaking,
              onTap: _voice == null ? null : _speak,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: _SpeedChips(speed: _ttsSpeed, onChanged: (s) => setState(() => _ttsSpeed = s))),
        ],
        const SizedBox(height: 24),
        Expanded(
          child: kind == 'pieces' ? _buildPiecesUi(l10n) : _buildMeaningUi(l10n),
        ),
        // Pedido de Rhoney (19/09/2026, teste real): na rodada "meaning"
        // tocar na opção já responde (§ acima, _selectMeaningAndSubmit)
        // — o botão "Verificar" só faz sentido pra "pieces" (montagem de
        // várias peças antes de poder conferir).
        if (kind == 'pieces')
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
                  onSpeak: () => _speakTile(indexed.value),
                  onRemove: () => _removeTile(indexed.key),
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
              _ConstellationTile(
                label: tile,
                filled: false,
                onTap: () => _addTile(tile),
                onSpeak: () => _speakTile(tile),
              ),
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
            onTap: _submitting ? () {} : () => _selectMeaningAndSubmit(option),
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
  const _ConstellationTile({
    required this.label,
    required this.filled,
    required this.onTap,
    this.expand = false,
    this.onSpeak,
    this.onRemove,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;
  final bool expand;
  // Só as PEÇAS (idioma estranho) recebem isto — as opções de
  // significado (português) nunca, mesma voz errada de sempre.
  final VoidCallback? onSpeak;
  // Pedido de Rhoney (19/09/2026, teste real): peça já montada precisa
  // de um "x" explícito pra remover — tocar na própria peça já
  // removia, mas não era óbvio o bastante como affordance.
  final VoidCallback? onRemove;

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
          padding: EdgeInsets.only(left: 16, right: (onSpeak != null || onRemove != null) ? 6 : 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.w600),
              ),
              if (onSpeak != null) ...[
                const SizedBox(width: 4),
                _MiniSpeakerButton(onTap: onSpeak!),
              ],
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                _MiniRemoveButton(onTap: onRemove!),
              ],
            ],
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

/// Versão pequena do botão Duolingo-style, cabe dentro de uma peça.
class _MiniSpeakerButton extends StatelessWidget {
  const _MiniSpeakerButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.teal,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.volume_up_rounded, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}

/// Botão "x" explícito pra remover uma peça já montada — pedido de
/// Rhoney (19/09/2026, teste real): tocar na peça já removia, mas
/// faltava um affordance claro de "isso aqui tira a peça".
class _MiniRemoveButton extends StatelessWidget {
  const _MiniRemoveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.close_rounded, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}

/// Palavra/frase-alvo + botão de áudio como UM elemento único e
/// tocável — nunca um ícone solto separado do texto (§4.3, correção
/// obrigatória de 19/09/2026). Pedido de Rhoney (19/09/2026, teste real
/// no dispositivo): o ícone precisa estar colado NA palavra, mesmo
/// padrão já usado nas peças (_ConstellationTile/_MiniSpeakerButton) —
/// não um círculo grande e separado do texto, mesmo que dentro do
/// mesmo cartão. Todo o cartão continua tocável, não só o ícone.
class _TargetPromptCard extends StatelessWidget {
  const _TargetPromptCard({required this.text, required this.speaking, required this.onTap});

  final String text;
  final bool speaking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: speaking ? 0.6 : 1,
      child: Material(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(text, style: Theme.of(context).textTheme.headlineSmall),
                ),
                const SizedBox(width: 10),
                _MiniSpeakerButton(onTap: onTap ?? () {}),
              ],
            ),
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
