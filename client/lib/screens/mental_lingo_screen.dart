import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/api_client.dart';
import '../idioma_voices.dart';
import '../services/mental_lingo_service.dart';
import '../services/tts_service.dart';
import '../theme/agent_neon.dart';
import '../theme/app_theme.dart';

/// MENTAL LINGO — assistente de voz do Mundo dos Idiomas
/// (MUNDO/Mundo_dos_Idiomas/Mental_Lingo/MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md,
/// aprovado por Rhoney, 23/09/2026 — escopo V1 100% custo zero). Voz
/// própria do assistente (respostas em português) — não confundir com
/// as vozes de pronúncia por idioma de `idioma_voices.dart` (essas
/// pronunciam a PALAVRA estrangeira; esta lê a EXPLICAÇÃO em português).
const String kMentalLingoVoice = 'pt-BR-FranciscaNeural';

/// Banner de entrada do MENTAL LINGO — pedido de Rhoney (23/09/2026):
/// "mais estilizado, com design profissional, como mostra a imagem". O
/// print de referência fica em MUNDO/Mundo_dos_Idiomas/Mental_Lingo/
/// Mental_Lingo.webp: cartão escuro com borda neon azul e brilho, mic em
/// anéis luminosos com mini-onda, "MENTAL" branco + "LINGO" ciano, chip
/// "Toque para perguntar", ondas decorativas no canto e botão em gradiente
/// azul→índigo com contorno claro. Identidade PRÓPRIA do agente (neon
/// azul), por isso as cores ficam aqui e não nos tokens gerais do app.
/// Aparece só dentro do Mundo dos Idiomas (_WorldDetailScreen decide).

class MentalLingoBanner extends StatelessWidget {
  const MentalLingoBanner({super.key, required this.client});

  final ApiClient client;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('mental_lingo_banner'),
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => MentalLingoScreen(client: client)),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [kAgentNavy, kAgentNavy2],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: kAgentBlue.withValues(alpha: 0.85), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: kAgentBlue.withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 0.5),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                    child: Row(
                      children: [
                        const _GlowingMic(size: 52),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2),
                                  children: [
                                    TextSpan(
                                        text: 'MENTAL ',
                                        style: TextStyle(color: Colors.white)),
                                    TextSpan(
                                        text: 'LINGO',
                                        style: TextStyle(color: kAgentCyan)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text('Converse por voz com a IA',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  style: TextStyle(
                                      color: Color(0xFFB8BEDF),
                                      fontSize: 11.5)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: kAgentBlue.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                        width: 14,
                                        height: 10,
                                        child: CustomPaint(
                                            painter: _WavePainter(
                                                barCount: 5,
                                                opacity: 1,
                                                cyan: true))),
                                    SizedBox(width: 5),
                                    Flexible(
                                      child: Text('Toque para perguntar',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Color(0xFF9FB4FF),
                                              fontSize: 9.5)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Ondas acima do botão (como no print), sem sobreposição.
                            const SizedBox(
                              width: 96,
                              height: 30,
                              child: CustomPaint(
                                  painter: _WavePainter(
                                      barCount: 17, opacity: 0.75)),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [kAgentBlue, kAgentIndigo]),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    width: 1.4),
                                boxShadow: [
                                  BoxShadow(
                                      color: kAgentBlue.withValues(alpha: 0.5),
                                      blurRadius: 12),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.mic_rounded,
                                      color: Colors.white, size: 15),
                                  SizedBox(width: 4),
                                  Text('Toque para falar',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Microfone em anéis luminosos com marcas de mira e mini-onda embaixo
/// (assinatura visual do print de referência).
class _GlowingMic extends StatelessWidget {
  const _GlowingMic({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                kAgentBlue.withValues(alpha: 0.35),
                Colors.transparent
              ]),
              boxShadow: [
                BoxShadow(
                    color: kAgentCyan.withValues(alpha: 0.35), blurRadius: 16)
              ],
            ),
          ),
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kAgentNavy,
              border: Border.all(color: kAgentCyan, width: 2),
            ),
          ),
          CustomPaint(size: Size(size, size), painter: const _TicksPainter()),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Icon(Icons.mic_rounded, color: Colors.white, size: 28),
          ),
          Positioned(
            bottom: size * 0.2,
            child: const SizedBox(
                width: 22,
                height: 8,
                child: CustomPaint(
                    painter:
                        _WavePainter(barCount: 7, opacity: 1, cyan: true))),
          ),
        ],
      ),
    );
  }
}

class _TicksPainter extends CustomPainter {
  const _TicksPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAgentCyan.withValues(alpha: 0.8)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    for (final d in [
      const Offset(0, -1),
      const Offset(0, 1),
      const Offset(-1, 0),
      const Offset(1, 0)
    ]) {
      canvas.drawLine(c + d * (r - 1), c + d * (r - 6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Barras de onda sonora simétricas (alturas fixas, sem animação — o
/// print é estático; animar aqui custaria rebuild contínuo na lista).
class _WavePainter extends CustomPainter {
  const _WavePainter(
      {required this.barCount, required this.opacity, this.cyan = false});

  final int barCount;
  final double opacity;
  final bool cyan;

  @override
  void paint(Canvas canvas, Size size) {
    const shape = [
      0.25,
      0.5,
      0.8,
      0.4,
      1.0,
      0.6,
      0.9,
      0.35,
      0.7,
      0.45,
      0.85,
      0.3,
      0.6,
      0.95,
      0.4,
      0.55,
      0.2
    ];
    final gap = size.width / barCount;
    for (var i = 0; i < barCount; i++) {
      final h = size.height * shape[i % shape.length];
      final color = cyan
          ? kAgentCyan
          : Color.lerp(kAgentBlue, kAgentIndigo, i / barCount)!;
      final paint = Paint()
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = gap * 0.45
        ..strokeCap = StrokeCap.round;
      final x = gap * i + gap / 2;
      canvas.drawLine(Offset(x, (size.height - h) / 2),
          Offset(x, (size.height + h) / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) => false;
}

enum _LingoState { ready, listening, processing, answering, error }

class MentalLingoScreen extends StatefulWidget {
  MentalLingoScreen(
      {super.key, required this.client, MentalLingoService? service})
      : _service = service ?? MentalLingoService.instance;

  final ApiClient client;
  final MentalLingoService _service;

  @override
  State<MentalLingoScreen> createState() => _MentalLingoScreenState();
}

class _MentalLingoScreenState extends State<MentalLingoScreen> {
  _LingoState _state = _LingoState.ready;
  String? _question;
  // Palavra/frase-chave da pergunta (devolvida pelo servidor) — recebe destaque no cartão.
  String? _matchedWord;
  String? _answer;
  // Trechos da resposta por idioma (voz nativa de cada um; ver MentalLingoAskOut.speech_segments).
  List<Map<String, dynamic>>? _speechSegments;
  // Resposta de fonte aberta ainda não revisada: o usuário pode votar se ajudou.
  Map<String, dynamic>? _suggestionKey;
  bool _voted = false;
  String? _errorMessage;
  bool _speakingAnswer = false;
  // O status "notListening" chega ANTES do resultado final da fala (achado
  // no teste real de Rhoney, 25/09/2026: pergunta falada virava "Não ouvi
  // nada"). Só declara silêncio se, passado este prazo, nenhum resultado veio.
  Timer? _noResultTimer;

  Future<void> _startListening() async {
    setState(() {
      _state = _LingoState.listening;
      _question = null;
      _answer = null;
      _errorMessage = null;
      _accumulated = '';
      _listenStartedAt = DateTime.now();
    });
    _safetyTimer?.cancel();
    _safetyTimer = Timer(_kSafetyCap, () {
      if (!mounted || _state != _LingoState.listening) return;
      if (_accumulated.isNotEmpty) {
        _submitAccumulated();
      } else {
        _cancelListening();
      }
    });
    final ok = await widget._service.init(
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _state = _LingoState.error;
          _errorMessage =
              'Não consegui acessar o microfone. Verifique a permissão do MENTAL nas configurações do aparelho.';
        });
      },
      onStatus: (status) {
        // Timeout de silêncio (pauseFor) ou stop/cancel: se a escuta
        // acabou e nenhuma pergunta chegou, avisa em vez de ficar preso
        // no estado "Ouvindo" pra sempre (v1.1 §Arquitetura a avaliar).
        if (!mounted) return;
        if ((status == 'notListening' || status == 'done') &&
            _state == _LingoState.listening &&
            _accumulated.isEmpty) {
          _noResultTimer?.cancel();
          _noResultTimer = Timer(const Duration(milliseconds: 3000), () {
            if (!mounted ||
                _state != _LingoState.listening ||
                _accumulated.isNotEmpty) return;
            setState(() {
              _state = _LingoState.error;
              _errorMessage =
                  'Não ouvi nada. Toque no microfone e tente de novo.';
            });
          });
        }
      },
    );
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _state = _LingoState.error;
        _errorMessage = 'Reconhecimento de voz indisponível neste aparelho.';
      });
      return;
    }
    await widget._service.listen(onFinalResult: _handleResult);
  }

  /// Pedido de Rhoney (25/09/2026): "o tempo de espera deve ser o tempo da
  /// pergunta do usuário". O reconhecedor do Android encerra cada sessão
  /// numa pausa curta de fala; em vez de enviar a 1ª frase, ACUMULAMOS os
  /// trechos, reabrimos a escuta e só enviamos quando o usuário para de
  /// falar de verdade (_kSubmitAfterSilence) ou toca no microfone.
  // Pedido de Rhoney (25/09/2026): "a escuta deve ser proporcional ao tempo da
  // pergunta". A tolerância a pausas cresce com quanto o usuário já falou:
  // 2,5s base + 15% do tempo decorrido, no máximo 8s (pergunta curta envia
  // rápido; pergunta longa ganha mais fôlego pra respirar/pensar).
  DateTime? _listenStartedAt;

  // Pergunta que já chegou completa ("como se escreve casa em inglês", "o que
  // significa house"): não há por que esperar o fôlego extra — envia logo.
  static final RegExp _completeQuestion = RegExp(
    r'^(como (se|é que se) (escreve|diz|fala)|traduz[ao]?|qual (é )?a tradu[çc][ãa]o de)\s+.+\s+(em|para)\s+(inglês|ingles|espanhol|francês|frances)\??$|^o que (significa|quer dizer)\s+\S+',
    caseSensitive: false,
  );

  Duration _submitDelay() {
    if (_completeQuestion.hasMatch(_accumulated.trim())) return const Duration(milliseconds: 1200);
    final started = _listenStartedAt;
    final elapsedMs = started == null ? 0 : DateTime.now().difference(started).inMilliseconds;
    return Duration(milliseconds: (2000 + elapsedMs * 0.12).clamp(2000, 6000).round());
  }

  String _accumulated = '';
  Timer? _submitTimer;
  // Teto de SEGURANÇA contra captura travada (MENTAL_IDIOMAS_ENTONACAO_TTS_URGENTE_V1.md
  // §2, 26/09/2026): alto o bastante pra nunca cortar uma pergunta falada normal (mesmo
  // de 30 s ou mais); a escuta em si segue a fala do usuário (silêncio sustentado).
  static const Duration _kSafetyCap = Duration(minutes: 3);
  Timer? _safetyTimer;

  Future<void> _handleResult(String text) async {
    if (!mounted || _state != _LingoState.listening) return;
    _noResultTimer?.cancel();
    final piece = text.trim();
    if (piece.isNotEmpty) {
      setState(() =>
          _accumulated = _accumulated.isEmpty ? piece : '$_accumulated $piece');
    }
    if (_accumulated.isEmpty) {
      setState(() {
        _state = _LingoState.error;
        _errorMessage = 'Não ouvi nada. Toque no microfone e tente de novo.';
      });
      return;
    }
    // Reabre a escuta pro caso de a pergunta continuar; se ninguém falar mais,
    // o prazo abaixo envia o que foi acumulado.
    _submitTimer?.cancel();
    _submitTimer = Timer(_submitDelay(), _submitAccumulated);
    try {
      await widget._service.listen(onFinalResult: _handleResult);
    } catch (_) {
      // sem reabrir: o prazo acima envia o que já temos.
    }
  }

  Future<void> _submitAccumulated() async {
    _safetyTimer?.cancel();
    _submitTimer?.cancel();
    _noResultTimer?.cancel();
    if (!mounted || _state != _LingoState.listening) return;
    final text = _accumulated.trim();
    if (text.isEmpty) return;
    widget._service.cancel();
    setState(() {
      _question = text;
      _state = _LingoState.processing;
    });
    try {
      final result = await widget.client.askMentalLingo(text);
      if (!mounted) return;
      setState(() {
        _answer = result['answer_text'] as String;
        _matchedWord = result['matched_word'] as String?;
        _speechSegments = (result['speech_segments'] as List?)?.cast<Map<String, dynamic>>();
        _suggestionKey = result['reviewed'] == false ? result['suggestion_key'] as Map<String, dynamic>? : null;
        _voted = false;
        _errorMessage = null;
        _state = _LingoState.answering;
      });
      _preloadAnswer();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _LingoState.error;
        _errorMessage = e.message;
      });
    }
  }

  void _cancelListening() {
    _safetyTimer?.cancel();
    _submitTimer?.cancel();
    _noResultTimer?.cancel();
    widget._service.cancel();
    setState(() => _state = _LingoState.ready);
  }

  /// Pedido de Rhoney (26/09/2026): "a AI Mental_Lingo deve falar as palavras de cada
  /// idioma de forma nativa". Cada trecho é falado pela voz do PRÓPRIO idioma
  /// (a explicação em português pela voz pt-BR; "House" pela voz do inglês etc.),
  /// em sequência. Palavra estrangeira dentro da frase não é repetida duas vezes.
  String _voiceFor(String lang) => lang == 'pt' ? kMentalLingoVoice : (voiceForTerritory(lang) ?? kMentalLingoVoice);

  /// Sintetiza todos os trechos EM PARALELO assim que a resposta chega, pra
  /// o toque em "Ouvir resposta" já achar tudo em cache (sem esperar a rede
  /// trecho a trecho).
  void _preloadAnswer() {
    final segments = _speechSegments;
    if (segments == null || segments.isEmpty) {
      final a = _answer;
      if (a != null) TtsService.instance.preload(a, voice: kMentalLingoVoice, speed: TtsSpeed.natural);
      return;
    }
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      TtsService.instance.preload(seg['text'] as String,
          voice: _voiceFor(seg['lang'] as String),
          speed: TtsSpeed.natural,
          repeatShortWords: false,
          continues: i < segments.length - 1);
    }
  }

  Future<void> _playAnswer() async {
    final answer = _answer;
    if (answer == null || _speakingAnswer) return;
    setState(() => _speakingAnswer = true);
    try {
      final segments = _speechSegments;
      if (segments == null || segments.isEmpty) {
        await TtsService.instance.speak(answer, voice: kMentalLingoVoice, speed: TtsSpeed.natural);
      } else {
        for (var i = 0; i < segments.length; i++) {
          if (!mounted) break;
          final seg = segments[i];
          final voice = _voiceFor(seg['lang'] as String);
          await TtsService.instance.speakAndWait(seg['text'] as String,
              voice: voice, speed: TtsSpeed.natural, repeatShortWords: false, continues: i < segments.length - 1);
        }
      }
    } finally {
      if (mounted) setState(() => _speakingAnswer = false);
    }
  }

  Future<void> _vote(bool useful) async {
    final key = _suggestionKey;
    if (key == null || _voted) return;
    setState(() => _voted = true);
    try {
      await widget.client.mentalLingoFeedback(key['word'] as String, key['target_language'] as String, useful);
    } on ApiException {
      // voto é só reforço; falha silenciosa
    }
  }

  void _newQuestion() {
    setState(() {
      _suggestionKey = null;
      _speechSegments = null;
      _matchedWord = null;
      _state = _LingoState.ready;
      _question = null;
      _answer = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _submitTimer?.cancel();
    _noResultTimer?.cancel();
    widget._service.cancel();
    super.dispose();
  }

  String _stateLabel() {
    switch (_state) {
      case _LingoState.ready:
        return 'Toque no microfone e pergunte sobre o vocabulário dos Idiomas.';
      case _LingoState.listening:
        return 'Ouvindo…';
      case _LingoState.processing:
        return 'Processando…';
      case _LingoState.answering:
        return 'Resposta pronta';
      case _LingoState.error:
        return 'Não foi dessa vez';
    }
  }

  IconData _micIcon() {
    switch (_state) {
      case _LingoState.listening:
        return Icons.graphic_eq_rounded;
      case _LingoState.processing:
        return Icons.hourglass_top_rounded;
      case _LingoState.error:
        return Icons.mic_off_rounded;
      case _LingoState.ready:
      case _LingoState.answering:
        return Icons.mic_rounded;
    }
  }

  VoidCallback? _micTap() {
    switch (_state) {
      case _LingoState.ready:
      case _LingoState.error:
      case _LingoState.answering:
        return _startListening;
      case _LingoState.listening:
        return _accumulated.isNotEmpty ? _submitAccumulated : _cancelListening;
      case _LingoState.processing:
        return null;
    }
  }

  Widget _buildMicButton() {
    final active = _state == _LingoState.listening;
    return GestureDetector(
      key: const Key('mental_lingo_mic_button'),
      onTap: _micTap(),
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient:
              LinearGradient(colors: [AppColors.purple, AppColors.mystery]),
          border: Border.all(
              color: AppColors.purple.withValues(alpha: active ? 1 : 0.4),
              width: active ? 4 : 2),
        ),
        child: _state == _LingoState.processing
            ? const Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3))
            : Icon(_micIcon(), color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildBubble(
      {required String label, required String text, required Key key}) {
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTheme.technicalStyle(
                  color: AppColors.purple, fontSize: 11)),
          const SizedBox(height: 4),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// Pedido de Rhoney (26/09/2026): "dê maior destaque à palavra/frase perguntada pelo
  /// usuário, fica mais intuitivo". Cartão de destaque (identidade neon dos agentes) com a
  /// pergunta em tamanho grande e a palavra/frase-chave em dourado, sobre fundo marcado.
  Widget _buildQuestionCard({required String text, String? highlight, required Key key}) {
    final base = GoogleFonts.fraunces(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.bone, height: 1.3);
    final marked = base.copyWith(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: AppColors.gold,
      backgroundColor: AppColors.gold.withValues(alpha: 0.16),
    );
    final spans = <TextSpan>[];
    final term = highlight?.trim();
    final idx = (term == null || term.isEmpty) ? -1 : text.toLowerCase().indexOf(term.toLowerCase());
    if (idx < 0) {
      spans.add(TextSpan(text: text, style: base));
    } else {
      if (idx > 0) spans.add(TextSpan(text: text.substring(0, idx), style: base));
      spans.add(TextSpan(text: text.substring(idx, idx + term!.length), style: marked));
      if (idx + term.length < text.length) spans.add(TextSpan(text: text.substring(idx + term.length), style: base));
    }
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: agentNeonDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VOCÊ PERGUNTOU', style: AppTheme.technicalStyle(color: kAgentCyan, fontSize: 11)),
          const SizedBox(height: 8),
          Text.rich(TextSpan(children: spans)),
        ],
      ),
    );
  }

  /// Pedido de Rhoney (26/09/2026): destacar também a resposta em idioma estrangeiro
  /// (ex.: "Cheese"), como já é feito com a palavra perguntada. Os termos estrangeiros
  /// vêm dos trechos de fala do servidor (idioma != pt) e aparecem maiores, em ciano, sobre
  /// fundo marcado; o resto da explicação fica em tamanho normal.
  Widget _buildAnswerCard({required String text, required List<String> foreignTerms, required Key key}) {
    final base = GoogleFonts.inter(fontSize: 17, height: 1.35, color: AppColors.bone);
    final marked = GoogleFonts.fraunces(
      fontSize: 26,
      fontWeight: FontWeight.w800,
      color: kAgentCyan,
      backgroundColor: kAgentCyan.withValues(alpha: 0.14),
    );
    final spans = <TextSpan>[];
    var pos = 0;
    final lower = text.toLowerCase();
    for (final term in foreignTerms) {
      final t = term.trim();
      if (t.isEmpty) continue;
      final idx = lower.indexOf(t.toLowerCase(), pos);
      if (idx < 0) continue;
      if (idx > pos) spans.add(TextSpan(text: text.substring(pos, idx), style: base));
      spans.add(TextSpan(text: text.substring(idx, idx + t.length), style: marked));
      pos = idx + t.length;
    }
    if (pos < text.length) spans.add(TextSpan(text: text.substring(pos), style: base));
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: agentNeonDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MENTAL LINGO', style: AppTheme.technicalStyle(color: AppColors.purple, fontSize: 11)),
          const SizedBox(height: 8),
          Text.rich(TextSpan(children: spans)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    switch (_state) {
      case _LingoState.listening:
        return TextButton.icon(
          key: const Key('mental_lingo_cancel_button'),
          onPressed: _cancelListening,
          icon: const Icon(Icons.close_rounded),
          label: const Text('Cancelar'),
        );
      case _LingoState.answering:
        // Pedido de Rhoney (26/09/2026): os dois botões mais profissionais, no padrão do
        // MENTAL — lado a lado, mesma largura e altura, formato pílula do tema. "Nova
        // pergunta" é a ação primária (dourado, como os demais botões principais do app);
        // "Ouvir resposta" é a secundária, com a identidade neon dos agentes (Mental Lingo).
        return Row(
          children: [
            Expanded(
              child: _LingoAudioButton(
                key: const Key('mental_lingo_listen_answer_button'),
                speaking: _speakingAnswer,
                onPressed: _speakingAnswer ? null : _playAnswer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                key: const Key('mental_lingo_new_question_button'),
                onPressed: _newQuestion,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                icon: const Icon(Icons.mic_rounded, size: 20),
                label: const Text('Nova pergunta', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
        );
      case _LingoState.error:
        return OutlinedButton.icon(
          key: const Key('mental_lingo_retry_button'),
          onPressed: _startListening,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar de novo'),
        );
      case _LingoState.ready:
      case _LingoState.processing:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.titleLarge,
            children: [
              TextSpan(
                  text: 'MENTAL ',
                  style: TextStyle(
                      color: AppColors.bone, fontWeight: FontWeight.w800)),
              TextSpan(
                  text: 'LINGO',
                  style: TextStyle(
                      color: AppColors.purple, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Microfone no MEIO da tela (pedido de Rhoney, 25/09/2026); o conteúdo
              // (pergunta/resposta/erro) desce junto e rola se for longo.
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMicButton(),
                        const SizedBox(height: 18),
                        Text(_stateLabel(),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 20),
                        if (_state == _LingoState.listening &&
                            _accumulated.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildBubble(
                                label: 'Ouvindo…',
                                text: _accumulated,
                                key: const Key('mental_lingo_live_bubble')),
                          ),
                        if (_question != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildQuestionCard(
                                text: _question!,
                                highlight: _matchedWord ?? extractLingoKeyTerm(_question!),
                                key: const Key('mental_lingo_question_bubble')),
                          ),
                        if (_answer != null)
                          _buildAnswerCard(
                              text: _answer!,
                              foreignTerms: [
                                for (final seg in _speechSegments ?? const <Map<String, dynamic>>[])
                                  if (seg['lang'] != 'pt') seg['text'] as String,
                              ],
                              key: const Key('mental_lingo_answer_bubble')),
                        if (_state == _LingoState.answering && _suggestionKey != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _voted
                                ? Text('Obrigado! Isso ajuda a revisar as respostas.',
                                    key: const Key('mental_lingo_voted_text'),
                                    style: TextStyle(color: AppColors.muted))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Essa resposta ajudou?'),
                                      IconButton(
                                          key: const Key('mental_lingo_vote_up'),
                                          onPressed: () => _vote(true),
                                          icon: const Icon(Icons.thumb_up_alt_outlined)),
                                      IconButton(
                                          key: const Key('mental_lingo_vote_down'),
                                          onPressed: () => _vote(false),
                                          icon: const Icon(Icons.thumb_down_alt_outlined)),
                                    ],
                                  ),
                          ),
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _errorMessage!,
                              key: const Key('mental_lingo_error_text'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        // Botões junto do conteúdo (mesmo bloco centralizado): o espaço em
                        // cima e embaixo fica proporcional em qualquer estado da tela.
                        if (_state != _LingoState.ready && _state != _LingoState.processing) ...[
                          const SizedBox(height: 24),
                          SizedBox(width: double.infinity, child: _buildActions()),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Termo-chave de uma pergunta ("como se escreve queijo em inglês" -> "queijo"), extraído no
/// próprio app com os mesmos padrões do servidor — assim o destaque aparece já ao enviar a
/// pergunta, sem depender da resposta. Devolve null se não reconhecer o padrão.
String? extractLingoKeyTerm(String question) {
  final q = question.trim().replaceAll(RegExp(r'[?!.]+$'), '').trim();
  const patterns = [
    r'^como (?:se|é que se) (?:escreve|diz|fala)\s+(.+?)\s+em\s+\S+$',
    r'^traduz[ao]?\s+(?:a palavra\s+)?(.+?)\s+(?:para|em)\s+\S+$',
    r'^qual\s+(?:é\s+)?a\s+tradu[çc][ãa]o\s+de\s+(.+?)\s+(?:para|em)\s+\S+$',
    r'^o que\s+(?:significa|quer dizer)\s+(.+?)$',
  ];
  for (final pattern in patterns) {
    final m = RegExp(pattern, caseSensitive: false).firstMatch(q);
    if (m != null) {
      final term = m.group(1)!.trim().replaceAll(RegExp('^[\'"]+|[\'"]+\$'), '');
      if (term.isNotEmpty) return term;
    }
  }
  return null;
}

/// Botão secundário "Ouvir resposta" com a identidade neon dos agentes (navy, contorno
/// ciano e brilho suave — mesma família do banner do Mental Lingo). Mostra "Falando…"
/// enquanto a resposta toca.
class _LingoAudioButton extends StatelessWidget {
  const _LingoAudioButton({super.key, required this.speaking, required this.onPressed});

  final bool speaking;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: kAgentCyan.withValues(alpha: speaking ? 0.45 : 0.22), blurRadius: 14),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: kAgentNavy,
          foregroundColor: AppColors.bone,
          disabledForegroundColor: AppColors.bone,
          side: BorderSide(color: kAgentCyan.withValues(alpha: 0.9), width: 1.4),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        icon: Icon(speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded, size: 20, color: kAgentCyan),
        label: Text(speaking ? 'Falando…' : 'Ouvir resposta', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
