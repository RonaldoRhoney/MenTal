import 'package:flutter/material.dart';

import '../api/api_client.dart';
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
  String? _answer;
  String? _errorMessage;
  bool _speakingAnswer = false;

  Future<void> _startListening() async {
    setState(() {
      _state = _LingoState.listening;
      _question = null;
      _answer = null;
      _errorMessage = null;
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
            _question == null) {
          setState(() {
            _state = _LingoState.error;
            _errorMessage =
                'Não ouvi nada. Toque no microfone e tente de novo.';
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

  Future<void> _handleResult(String text) async {
    if (!mounted) return;
    if (text.trim().isEmpty) {
      setState(() {
        _state = _LingoState.error;
        _errorMessage = 'Não ouvi nada. Toque no microfone e tente de novo.';
      });
      return;
    }
    setState(() {
      _question = text;
      _state = _LingoState.processing;
    });
    try {
      final result = await widget.client.askMentalLingo(text);
      if (!mounted) return;
      setState(() {
        _answer = result['answer_text'] as String;
        _state = _LingoState.answering;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _LingoState.error;
        _errorMessage = e.message;
      });
    }
  }

  void _cancelListening() {
    widget._service.cancel();
    setState(() => _state = _LingoState.ready);
  }

  Future<void> _playAnswer() async {
    final answer = _answer;
    if (answer == null || _speakingAnswer) return;
    setState(() => _speakingAnswer = true);
    await TtsService.instance.speak(answer, voice: kMentalLingoVoice);
    if (mounted) setState(() => _speakingAnswer = false);
  }

  void _newQuestion() {
    setState(() {
      _state = _LingoState.ready;
      _question = null;
      _answer = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
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
        return _cancelListening;
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
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            OutlinedButton.icon(
              key: const Key('mental_lingo_listen_answer_button'),
              onPressed: _speakingAnswer ? null : _playAnswer,
              icon: const Icon(Icons.volume_up_rounded),
              label: const Text('Ouvir resposta'),
            ),
            FilledButton.icon(
              key: const Key('mental_lingo_new_question_button'),
              onPressed: _newQuestion,
              icon: const Icon(Icons.mic_rounded),
              label: const Text('Nova pergunta'),
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
              const SizedBox(height: 12),
              _buildMicButton(),
              const SizedBox(height: 18),
              Text(_stateLabel(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 20),
              if (_question != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildBubble(
                      label: 'Você perguntou',
                      text: _question!,
                      key: const Key('mental_lingo_question_bubble')),
                ),
              if (_answer != null)
                _buildBubble(
                    label: 'MENTAL LINGO',
                    text: _answer!,
                    key: const Key('mental_lingo_answer_bubble')),
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
              const Spacer(),
              _buildActions(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
