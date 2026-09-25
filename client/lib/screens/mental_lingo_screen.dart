import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../services/mental_lingo_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// MENTAL LINGO — assistente de voz do Mundo dos Idiomas
/// (MUNDO/Mundo_dos_Idiomas/Mental_Lingo/MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md,
/// aprovado por Rhoney, 23/09/2026 — escopo V1 100% custo zero). Voz
/// própria do assistente (respostas em português) — não confundir com
/// as vozes de pronúncia por idioma de `idioma_voices.dart` (essas
/// pronunciam a PALAVRA estrangeira; esta lê a EXPLICAÇÃO em português).
const String kMentalLingoVoice = 'pt-BR-FranciscaNeural';

/// Banner de entrada do MENTAL LINGO — pedido de Rhoney: a interface do
/// print de referência (guardado em
/// MUNDO/Mundo_dos_Idiomas/Mental_Lingo/Mental_Lingo.webp) deve ser
/// mantida exatamente como está, ou melhorada, nunca simplificada.
/// Aparece só dentro do Mundo dos Idiomas (_WorldDetailScreen decide
/// isso, nunca este widget).
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
            MaterialPageRoute(builder: (_) => MentalLingoScreen(client: client)),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.mystery.withValues(alpha: 0.32),
                  AppColors.purple.withValues(alpha: 0.32),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.55)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.purple.withValues(alpha: 0.25),
                    border: Border.all(color: AppColors.purple.withValues(alpha: 0.7), width: 2),
                  ),
                  child: Icon(Icons.mic_rounded, color: AppColors.bone, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: Theme.of(context).textTheme.titleMedium,
                          children: [
                            TextSpan(
                                text: 'MENTAL ',
                                style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.w800)),
                            TextSpan(
                                text: 'LINGO',
                                style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text('Converse por voz com a IA',
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.graphic_eq_rounded, size: 14, color: AppColors.purple),
                          const SizedBox(width: 4),
                          Text('Toque para perguntar',
                              style: AppTheme.technicalStyle(color: AppColors.purple, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.purple, AppColors.mystery]),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Toque para falar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _LingoState { ready, listening, processing, answering, error }

class MentalLingoScreen extends StatefulWidget {
  MentalLingoScreen({super.key, required this.client, MentalLingoService? service})
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
            _errorMessage = 'Não ouvi nada. Toque no microfone e tente de novo.';
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
          gradient: LinearGradient(colors: [AppColors.purple, AppColors.mystery]),
          border: Border.all(
              color: AppColors.purple.withValues(alpha: active ? 1 : 0.4), width: active ? 4 : 2),
        ),
        child: _state == _LingoState.processing
            ? const Padding(
                padding: EdgeInsets.all(28),
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
            : Icon(_micIcon(), color: Colors.white, size: 40),
      ),
    );
  }

  Widget _buildBubble({required String label, required String text, required Key key}) {
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
          Text(label, style: AppTheme.technicalStyle(color: AppColors.purple, fontSize: 11)),
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
              TextSpan(text: 'MENTAL ', style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.w800)),
              TextSpan(text: 'LINGO', style: TextStyle(color: AppColors.purple, fontWeight: FontWeight.w800)),
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
                  textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
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
                    label: 'MENTAL LINGO', text: _answer!, key: const Key('mental_lingo_answer_bubble')),
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
