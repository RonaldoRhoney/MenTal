import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../idioma_voices.dart';
import '../services/lingo_translator.dart';
import '../services/mental_lingo_service.dart';
import '../services/tts_service.dart';
import '../theme/agent_neon.dart';
import '../theme/app_theme.dart';
import '../widgets/mental_character.dart';

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
                        // MENTAL_PERSONAGEM_MASCOTE_V1.md §3.2: o
                        // personagem é a cara visual do MENTAL LINGO,
                        // substituindo o ícone genérico de microfone.
                        const MentalCharacter(
                          expression: MentalCharacterExpression.felizNeutro,
                          size: 52,
                        ),
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

// _GlowingMic e _TicksPainter (ícone de microfone genérico em anéis
// luminosos) foram removidos em 03/10/2026 — substituídos pelo
// personagem Mental no banner do LINGO (MENTAL_PERSONAGEM_MASCOTE_V1.md
// §3.2, decisão explícita de Rhoney). Histórico do desenho antigo
// continua no git caso precise de referência.

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

/// Os 3 modos de captura de voz que devem coexistir, escolhidos pelo usuário
/// (MENTAL_LINGO_RELATORIO_TESTES_CAMPO_V1.md, decisão de Rhoney 29/09/2026,
/// depois de testes reais em campo — Modo 3 tinha sido removido em 27/09 por
/// um bug de escuta de 1:20 em ambiente ruidoso, corrigido e reintroduzido).
enum _CaptureMode {
  /// Modo 1: apertar-e-segurar o botão enquanto fala, soltar pra enviar.
  /// Padrão — mesmo comportamento de mensagem de voz (WhatsApp).
  holdToTalk,

  /// Modo 2: toque pra começar, toque de novo pra encerrar e enviar. Sem
  /// exigir pressão contínua — alternativa de acessibilidade.
  tapTwice,

  /// Modo 3: toque pra começar; o app detecta sozinho o fim da fala por
  /// silêncio contínuo (`_kAutoDetectSilenceTimeout`). Vale um indicador
  /// visual de "ainda ouvindo" pra deixar claro que a escuta continua, com
  /// a opção de encerrar manualmente a qualquer momento.
  autoDetect,
}

class MentalLingoScreen extends StatefulWidget {
  MentalLingoScreen(
      {super.key, required this.client, MentalLingoService? service, LingoTranslator? translator})
      : _service = service ?? MentalLingoService.instance,
        _translator = translator ?? MlKitLingoTranslator.instance;

  final ApiClient client;
  final MentalLingoService _service;
  final LingoTranslator _translator;

  @override
  State<MentalLingoScreen> createState() => _MentalLingoScreenState();
}

class _MentalLingoScreenState extends State<MentalLingoScreen> {
  _LingoState _state = _LingoState.ready;
  String? _question;
  // Palavra/frase-chave da pergunta (devolvida pelo servidor) — recebe destaque no cartão.
  String? _matchedWord;
  String? _answer;
  // Termos a destacar no cartão da resposta quando não vêm dos trechos de fala (tradução de frase).
  List<String>? _answerHighlights;
  // Baixando o modelo de idioma da tradução no aparelho (só na primeira vez).
  bool _preparingTranslator = false;
  // Trechos da resposta por idioma (voz nativa de cada um; ver MentalLingoAskOut.speech_segments).
  List<Map<String, dynamic>>? _speechSegments;
  // Resposta de fonte aberta ainda não revisada: o usuário pode votar se ajudou.
  Map<String, dynamic>? _suggestionKey;
  bool _voted = false;
  String? _errorMessage;
  bool _speakingAnswer = false;

  // MENTAL_LINGO_RELATORIO_TESTES_CAMPO_V1.md (decisão de Rhoney,
  // 29/09/2026): 3 modos de captura coexistem, escolhidos pelo usuário.
  // Padrão continua sendo apertar-e-segurar (MENTAL_LINGO_ASSISTENTE_
  // VOZ_V1.1.md, 28/09/2026).
  _CaptureMode _captureMode = _CaptureMode.holdToTalk;
  // Modos 2 e 3 começam por toque (não por apertar-e-segurar) — usado nos
  // gestos abaixo pra decidir entre GestureDetector.onTap e onLongPress*.
  bool get _tapMode => _captureMode != _CaptureMode.holdToTalk;
  // Dedo arrastado pra fora da área do botão durante o apertar-e-segurar:
  // soltar nesse estado CANCELA a captura em vez de enviar (mesmo padrão de
  // apps de mensagem de voz).
  bool _willCancel = false;
  // Modo 3 (detecção automática): true depois de alguns segundos ouvindo
  // sem o reconhecedor ter encerrado sozinho — mostra o indicador "ainda
  // ouvindo" com opção de encerrar manualmente a qualquer momento.
  bool _showStillListeningHint = false;
  Timer? _stillListeningTimer;
  // Teto de silêncio contínuo do Modo 3 antes de encerrar sozinho — faixa
  // de 15-20s orientada no relatório de testes de campo; 18s no meio dela.
  // Bem menor que os 3min dos modos 1/2 (lá quem decide é o usuário).
  static const Duration _kAutoDetectSilenceTimeout = Duration(seconds: 18);
  // Indicador visual aparece depois desse tanto de escuta contínua — dá
  // tempo de uma resposta normal terminar sem o aviso piscar à toa, mas
  // ainda avisa bem antes do teto de 18s de silêncio disparar sozinho.
  static const Duration _kStillListeningHintDelay = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _loadCaptureModePreference();
  }

  static const _kCaptureModePrefKey = 'mental_lingo_capture_mode';
  // Chave antiga (booleana), mantida só pra migrar quem já tinha escolhido
  // o modo de toque único antes do Modo 3 existir — nunca mais escrita.
  static const _kLegacyTapModePrefKey = 'mental_lingo_tap_mode';

  Future<void> _loadCaptureModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final saved = prefs.getString(_kCaptureModePrefKey);
      _CaptureMode mode;
      if (saved != null) {
        mode = _CaptureMode.values.firstWhere(
          (m) => m.name == saved,
          orElse: () => _CaptureMode.holdToTalk,
        );
      } else if (prefs.getBool(_kLegacyTapModePrefKey) == true) {
        mode = _CaptureMode.tapTwice; // migra a preferência antiga
      } else {
        mode = _CaptureMode.holdToTalk;
      }
      setState(() => _captureMode = mode);
    } catch (_) {
      // preferência não crítica — mantém o padrão (apertar-e-segurar)
    }
  }

  Future<void> _setCaptureMode(_CaptureMode mode) async {
    if (mode == _captureMode) return;
    setState(() => _captureMode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCaptureModePrefKey, mode.name);
    } catch (_) {
      // falha ao salvar não impede o uso nesta sessão
    }
  }

  static const Map<_CaptureMode, (IconData, String)> _kCaptureModeChips = {
    _CaptureMode.holdToTalk: (Icons.back_hand_outlined, 'Apertar e segurar'),
    _CaptureMode.tapTwice: (Icons.touch_app_outlined, 'Toque duplo'),
    _CaptureMode.autoDetect: (Icons.graphic_eq_rounded, 'Detecção automática'),
  };

  /// Seletor de 3 opções (MENTAL_LINGO_RELATORIO_TESTES_CAMPO_V1.md, 29/09/2026)
  /// — substitui o antigo alternador binário; o modo ativo fica sempre visível.
  Widget _buildCaptureModeSelector() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: _CaptureMode.values.map((mode) {
        final active = mode == _captureMode;
        final (icon, label) = _kCaptureModeChips[mode]!;
        return OutlinedButton.icon(
          key: Key('mental_lingo_capture_mode_${mode.name}'),
          onPressed: () => _setCaptureMode(mode),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            backgroundColor: active ? kAgentBlue.withValues(alpha: 0.18) : null,
            side: BorderSide(
                color: active
                    ? kAgentBlue.withValues(alpha: 0.85)
                    : AppColors.bone.withValues(alpha: 0.3)),
            foregroundColor: active ? kAgentBlue : AppColors.bone,
          ),
          icon: Icon(icon, size: 16),
          label: Text(label, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
    );
  }

  Future<void> _startListening() async {
    setState(() {
      _state = _LingoState.listening;
      _question = null;
      _answer = null;
      _errorMessage = null;
      _accumulated = '';
      _willCancel = false;
      _awaitingFinal = false;
      _showStillListeningHint = false;
    });
    _safetyTimer?.cancel();
    _safetyTimer = Timer(_kSafetyCap, () {
      // Teto de segurança (nunca deveria disparar em uso normal, nem
      // segurando o botão nem no modo de toque): protege só contra o
      // reconhecedor travado por bug de software.
      if (!mounted || _state != _LingoState.listening) return;
      _stopAndSubmit();
    });
    _stillListeningTimer?.cancel();
    if (_captureMode == _CaptureMode.autoDetect) {
      // Indicador "ainda ouvindo" (Modo 3) — MENTAL_LINGO_RELATORIO_TESTES_
      // CAMPO_V1.md §4: dá pro usuário perceber, visualmente, que a escuta
      // automática continua ativa além do esperado, com opção de encerrar
      // manualmente a qualquer momento.
      _stillListeningTimer = Timer(_kStillListeningHintDelay, () {
        if (!mounted || _state != _LingoState.listening) return;
        setState(() => _showStillListeningHint = true);
      });
    }
    final ok = await widget._service.init(
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _state = _LingoState.error;
          _errorMessage =
              'Não consegui acessar o microfone. Verifique a permissão do MENTAL nas configurações do aparelho.';
        });
      },
      onStatus: _handleRecognizerStatus,
    );
    if (!ok) {
      if (!mounted) return;
      setState(() {
        _state = _LingoState.error;
        _errorMessage = 'Reconhecimento de voz indisponível neste aparelho.';
      });
      return;
    }
    await widget._service.listen(
      onFinalResult: _handleResult,
      onPartialResult: _handlePartialResult,
      silenceTimeout: _captureMode == _CaptureMode.autoDetect
          ? _kAutoDetectSilenceTimeout
          : null,
    );
  }

  /// Só relevante no Modo 3: o pacote encerra a escuta sozinho ("done")
  /// quando o silêncio contínuo passa de `_kAutoDetectSilenceTimeout` — é
  /// o sinal de que a fala terminou e a pergunta deve ser enviada. Nos
  /// modos 1/2, quem decide quando parar é sempre o usuário (soltar o
  /// botão / tocar de novo), então este callback não faz nada.
  void _handleRecognizerStatus(String status) {
    if (_captureMode != _CaptureMode.autoDetect) return;
    if (status != 'done' && status != 'notListening') return;
    if (!mounted || _state != _LingoState.listening) return;
    _stopAndSubmit();
  }

  void _handlePartialResult(String text) {
    if (!mounted || _state != _LingoState.listening) return;
    setState(() => _accumulated = text.trim());
  }

  String _accumulated = '';
  // Teto de SEGURANÇA contra captura travada (alto o bastante pra nunca
  // interferir no uso normal — apertar-e-segurar já é controlado pelo
  // próprio usuário soltando o botão).
  static const Duration _kSafetyCap = Duration(minutes: 3);
  Timer? _safetyTimer;
  // `true` entre o usuário soltar o botão (ou tocar de novo, no modo de
  // toque) e o resultado final da fala chegar — evita enviar a pergunta
  // antes do reconhecedor terminar de processar o que foi dito.
  bool _awaitingFinal = false;
  Timer? _finalizeTimeoutTimer;

  void _handleResult(String text) {
    if (!mounted || _state != _LingoState.listening) return;
    final piece = text.trim();
    if (piece.isNotEmpty) _accumulated = piece;
    if (_awaitingFinal) _finishAwaitingFinal();
  }

  void _finishAwaitingFinal() {
    _awaitingFinal = false;
    _finalizeTimeoutTimer?.cancel();
    if (_accumulated.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _state = _LingoState.error;
        _errorMessage = _tapMode
            ? 'Não ouvi nada. Toque no microfone e tente de novo.'
            : 'Não ouvi nada. Aperte e segure o microfone enquanto fala.';
      });
    } else {
      _submitAccumulated();
    }
  }

  /// Encerra a captura (soltou o botão, ou tocou de novo no modo de
  /// acessibilidade) e envia a pergunta assim que o resultado final da
  /// fala chegar. Um prazo curto de segurança evita ficar preso
  /// esperando indefinidamente se o reconhecedor não confirmar o fim.
  Future<void> _stopAndSubmit() async {
    if (!mounted || _state != _LingoState.listening) return;
    _stillListeningTimer?.cancel();
    if (_showStillListeningHint) setState(() => _showStillListeningHint = false);
    _awaitingFinal = true;
    _finalizeTimeoutTimer?.cancel();
    _finalizeTimeoutTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || !_awaitingFinal) return;
      _finishAwaitingFinal();
    });
    await widget._service.stop();
  }



  /// Frase fora do vocabulário curado: o servidor só reconheceu a intenção; a tradução em si é
  /// feita no aparelho (Google ML Kit, gratuito/offline). Devolve um resultado no mesmo formato
  /// da resposta do servidor. Falha vira resposta honesta, nunca tradução inventada.
  Future<Map<String, dynamic>> _translatePhrase(Map<String, dynamic> ask) async {
    final phrase = (ask['phrase'] as String).trim();
    const note = '\nTradução automática feita no seu aparelho — pode ter imprecisões.';
    try {
      late final String from;
      late final String to;
      if (ask['intent'] == 'translate') {
        from = 'pt';
        to = (ask['target_language'] as String?) ?? 'ingles';
      } else {
        final detected = await widget._translator.detectLanguage(phrase);
        if (detected == null || detected == 'pt') {
          return {
            'found': false,
            'answer_text': "Não consegui identificar o idioma de '$phrase'. Diga, por exemplo: \"como se diz $phrase em inglês\".",
            'matched_word': phrase,
          };
        }
        from = detected;
        to = 'pt';
      }
      final out = await widget._translator.translate(phrase, from: from, to: to, onDownloading: () {
        if (mounted) setState(() => _preparingTranslator = true);
      });
      if (mounted) setState(() => _preparingTranslator = false);
      if (from == 'pt') {
        // Igual à resposta do vocabulário: sem repetir "em inglês" no final (o jogador já disse o idioma).
        return {
          'found': true,
          'answer_text': "'$phrase' se traduz como '$out'.$note",
          'matched_word': phrase,
          'target_language': to,
          'speech_segments': [
            {'lang': 'pt', 'text': '$phrase se traduz como'},
            {'lang': to, 'text': out},
          ],
          'highlights': [out],
        };
      }
      return {
        'found': true,
        'answer_text': "'$phrase' significa '$out'.$note",
        'matched_word': phrase,
        'target_language': from,
        'speech_segments': [
          {'lang': from, 'text': phrase},
          {'lang': 'pt', 'text': 'significa $out'},
        ],
        'highlights': [out],
      };
    } on LingoTranslateException catch (e) {
      if (mounted) setState(() => _preparingTranslator = false);
      return {'found': false, 'answer_text': e.message, 'matched_word': phrase};
    }
  }

  Future<void> _submitAccumulated() async {
    _safetyTimer?.cancel();
    _finalizeTimeoutTimer?.cancel();
    if (!mounted || _state != _LingoState.listening) return;
    final text = _accumulated.trim();
    if (text.isEmpty) return;
    widget._service.cancel();
    setState(() {
      _question = text;
      _state = _LingoState.processing;
    });
    try {
      var result = await widget.client.askMentalLingo(text);
      if (!mounted) return;
      final intent = result['intent'] as String?;
      if (result['found'] != true && (intent == 'translate' || intent == 'translate_auto')) {
        result = await _translatePhrase(result);
        if (!mounted) return;
      }
      setState(() {
        _answerHighlights = (result['highlights'] as List?)?.cast<String>();
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
    _finalizeTimeoutTimer?.cancel();
    _stillListeningTimer?.cancel();
    _awaitingFinal = false;
    widget._service.cancel();
    setState(() {
      _state = _LingoState.ready;
      _willCancel = false;
      _showStillListeningHint = false;
    });
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
      _answerHighlights = null;
      _state = _LingoState.ready;
      _question = null;
      _answer = null;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _finalizeTimeoutTimer?.cancel();
    _stillListeningTimer?.cancel();
    widget._service.cancel();
    super.dispose();
  }

  String _stateLabel() {
    switch (_state) {
      case _LingoState.ready:
        return _tapMode
            ? 'Toque no microfone e pergunte sobre o vocabulário dos Idiomas.'
            : 'Aperte e segure o microfone, fale sua pergunta e solte.';
      case _LingoState.listening:
        return _willCancel ? 'Solte fora do botão pra cancelar' : 'Ouvindo…';
      case _LingoState.processing:
        return _preparingTranslator ? 'Preparando o tradutor (só na primeira vez)…' : 'Processando…';
      case _LingoState.answering:
        return 'Resposta pronta';
      case _LingoState.error:
        return 'Não foi dessa vez';
    }
  }

  IconData _micIcon() {
    switch (_state) {
      case _LingoState.listening:
        return _willCancel ? Icons.close_rounded : Icons.graphic_eq_rounded;
      case _LingoState.processing:
        return Icons.hourglass_top_rounded;
      case _LingoState.error:
        return Icons.mic_off_rounded;
      case _LingoState.ready:
      case _LingoState.answering:
        return Icons.mic_rounded;
    }
  }

  // MENTAL_PERSONAGEM_MASCOTE_V1.md §3.2/§6.3: o personagem é a cara
  // visual do MENTAL LINGO em cada um dos 5 estados já especificados em
  // MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md (Pronto/Ouvindo/Processando/
  // Respondendo/Falha) — mapeado pras 8 expressões aprovadas (§4).
  MentalCharacterExpression _characterExpression() {
    switch (_state) {
      case _LingoState.ready:
        return MentalCharacterExpression.felizNeutro;
      case _LingoState.listening:
        return MentalCharacterExpression.acenando;
      case _LingoState.processing:
        return MentalCharacterExpression.pensando;
      case _LingoState.answering:
        return MentalCharacterExpression.okPositivo;
      case _LingoState.error:
        return MentalCharacterExpression.negativoSuave;
    }
  }

  // Modo de acessibilidade (toque único): tocar começa, tocar de novo
  // encerra e envia — sem exigir pressão contínua no botão.
  VoidCallback? _tapModeAction() {
    switch (_state) {
      case _LingoState.ready:
      case _LingoState.error:
      case _LingoState.answering:
        return _startListening;
      case _LingoState.listening:
        return _stopAndSubmit;
      case _LingoState.processing:
        return null;
    }
  }

  static const double _kMicButtonSize = 96;
  // Margem além da área do botão que ainda conta como "dentro" antes de
  // marcar cancelamento — evita cancelar sem querer com um leve tremor
  // do dedo, mas ainda cancela com uma saída clara da área do botão.
  static const double _kCancelMargin = 56;

  void _onHoldStart(LongPressStartDetails _) {
    if (_tapMode) return;
    if (_state != _LingoState.listening) _startListening();
  }

  void _onHoldMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_tapMode || _state != _LingoState.listening) return;
    final pos = details.localPosition;
    final outside = pos.dx < -_kCancelMargin ||
        pos.dy < -_kCancelMargin ||
        pos.dx > _kMicButtonSize + _kCancelMargin ||
        pos.dy > _kMicButtonSize + _kCancelMargin;
    if (outside != _willCancel) setState(() => _willCancel = outside);
  }

  void _onHoldEnd(LongPressEndDetails _) {
    if (_tapMode || _state != _LingoState.listening) return;
    if (_willCancel) {
      _cancelListening();
    } else {
      _stopAndSubmit();
    }
  }

  void _onHoldCancel() {
    if (_tapMode || _state != _LingoState.listening) return;
    _cancelListening();
  }

  Widget _buildMicButton() {
    final active = _state == _LingoState.listening;
    return GestureDetector(
      key: const Key('mental_lingo_mic_button'),
      onTap: _tapMode ? _tapModeAction() : null,
      onLongPressStart: _tapMode ? null : _onHoldStart,
      onLongPressMoveUpdate: _tapMode ? null : _onHoldMoveUpdate,
      onLongPressEnd: _tapMode ? null : _onHoldEnd,
      onLongPressCancel: _tapMode ? null : _onHoldCancel,
      child: Container(
        width: _kMicButtonSize,
        height: _kMicButtonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: _willCancel
              ? [AppColors.mystery, AppColors.mystery]
              : [AppColors.purple, AppColors.mystery]),
          border: Border.all(
              color: (_willCancel ? AppColors.mystery : AppColors.purple)
                  .withValues(alpha: active ? 1 : 0.4),
              width: active ? 4 : 2),
        ),
        child: _state == _LingoState.listening
            ? Icon(_micIcon(), color: Colors.white, size: 40)
            : Padding(
                padding: const EdgeInsets.all(8),
                child: MentalCharacter(
                  expression: _characterExpression(),
                  size: _kMicButtonSize - 16,
                ),
              ),
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

  /// Cartões da tela do Mental Lingo com os tokens de cor OFICIAIS do app (AppColors: fundo,
  /// dourado, verde-azulado, roxo, osso), que também se adaptam ao tema claro. O azul-marinho/
  /// ciano neon fica só no banner e no microfone (identidade do agente, Mental_Lingo.webp).
  BoxDecoration _lingoCardDecoration(Color accent) => BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.2),
        boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.10), blurRadius: 12)],
      );

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
      decoration: _lingoCardDecoration(AppColors.gold),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VOCÊ PERGUNTOU', style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 11)),
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
      color: AppColors.teal,
      backgroundColor: AppColors.teal.withValues(alpha: 0.16),
    );
    final spans = <TextSpan>[];
    // Destaca TODAS as ocorrências (palavra inteira, sem diferenciar maiúsculas): no exemplo, o
    // termo aparece no título e dentro da própria frase.
    final terms = foreignTerms.map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
      ..sort((x, y) => y.length.compareTo(x.length));
    if (terms.isEmpty) {
      spans.add(TextSpan(text: text, style: base));
    } else {
      const letters = 'A-Za-zÀ-ÿ';
      final pattern = RegExp(
        '(?<![$letters])(${terms.map(RegExp.escape).join('|')})(?![$letters])',
        caseSensitive: false,
      );
      var pos = 0;
      for (final m in pattern.allMatches(text)) {
        if (m.start > pos) spans.add(TextSpan(text: text.substring(pos, m.start), style: base));
        spans.add(TextSpan(text: m.group(0), style: marked));
        pos = m.end;
      }
      if (pos < text.length) spans.add(TextSpan(text: text.substring(pos), style: base));
    }
    return Container(
      key: key,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: _lingoCardDecoration(AppColors.teal),
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
                        // 3 modos de captura coexistem, escolha do usuário
                        // (MENTAL_LINGO_RELATORIO_TESTES_CAMPO_V1.md, 29/09/2026)
                        // — só aparece fora da escuta, pra não distrair no meio
                        // da captura.
                        if (_state != _LingoState.listening &&
                            _state != _LingoState.processing)
                          _buildCaptureModeSelector(),
                        // Modo 3: sinal visual de que a escuta automática
                        // continua ativa além do esperado, com opção de
                        // encerrar manualmente a qualquer momento (§4 do
                        // relatório de testes de campo).
                        if (_state == _LingoState.listening &&
                            _showStillListeningHint)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: TextButton.icon(
                              key: const Key('mental_lingo_still_listening_hint'),
                              onPressed: _stopAndSubmit,
                              icon: Icon(Icons.hourglass_bottom_rounded,
                                  size: 18, color: AppColors.gold),
                              label: const Text(
                                  'Ainda ouvindo… toque pra encerrar agora'),
                            ),
                          ),
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
                              foreignTerms: _answerHighlights ??
                                  [
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
// Palavras de comando de um pedido de frase-exemplo (tiradas das pontas; o que sobra é o termo).
const Set<String> _kLingoCommandWords = {
  'me', 'dê', 'de', 'dá', 'dar', 'mostre', 'mostra', 'fale', 'diga', 'crie', 'cria', 'criar', 'faça', 'faz', 'fazer',
  'monte', 'montar', 'escreva', 'escrever', 'quero', 'queria', 'preciso', 'gostaria', 'pode', 'poderia', 'uma', 'um',
  'umas', 'uns', 'frase', 'frases', 'exemplo', 'exemplos', 'sentença', 'sentenças', 'oração', 'orações', 'curta',
  'curto', 'curtas', 'curtos', 'simples', 'fácil', 'facil', 'em', 'no', 'na', 'inglês', 'ingles', 'english', 'com',
  'a', 'o', 'as', 'os', 'palavra', 'termo', 'usando', 'use', 'usa', 'usar', 'utilize', 'utiliza', 'que', 'tenha',
  'tenham', 'contenha', 'contendo', 'para', 'pra', 'por', 'favor', 'sobre', 'ao', 'dentro', 'numa', 'num', 'da', 'do',
  'dos', 'das', 'seja',
};

String? extractLingoKeyTerm(String question) {
  // Mesma limpeza do servidor: pontuação final ("?", ".", "!"), preâmbulos ("então, você pode
  // me dizer...") e fechos ("por favor") não mudam o sentido da pergunta.
  final leading = RegExp(
    r'^(?:ol[áa]|oi|ei|ok|okay|então|entao|agora|bom|bem|e|mas|hey|mental lingo|lingo|por favor|'
    r'(?:você|voce)\s+(?:pode|poderia|consegue)|pode|poderia|(?:me\s+)?(?:diga|dizer|fale|falar|explique|explica|responda|ajude|ajuda)(?:-me)?|'
    r'(?:eu\s+)?(?:gostaria de|queria|quero|preciso)\s+saber|tem como|(?:será|sera)\s+que)(?:\s*[,:;-]\s*|\s+)',
    caseSensitive: false,
  );
  final tailPunct = RegExp('[\\s.?!…,;:"\'“”]+\$');
  var q = question.trim().replaceAll(RegExp(r'\s+'), ' ');
  for (var i = 0; i < 5; i++) {
    final next = q.replaceFirst(leading, '').trim();
    if (next == q) break;
    q = next;
  }
  q = q.replaceAll(tailPunct, '');
  q = q.replaceAll(RegExp(r'\s*[,;:-]?\s*(?:por favor|pf|obrigad[oa]|valeu)$', caseSensitive: false), '').replaceAll(tailPunct, '');
  const patterns = [
    r'^como (?:se|é que se) (?:escreve|diz|fala)\s+(.+?)\s+em\s+\S+$',
    r'^como (?:eu )?(?:posso |consigo |faço para )?(?:falo|digo|dizer|falar|escrever|escrevo)\s+(.+?)\s+em\s+\S+$',
    r'^tradu(?:z|za|zo|zir)\s+(?:a palavra\s+|a frase\s+)?(.+?)\s+(?:para|em)\s+\S+$',
    r'^qual\s+(?:é\s+)?a\s+tradu[çc][ãa]o\s+de\s+(.+?)(?:\s+(?:para|em)\s+\S+)?$',
    r'^qual\s+(?:é\s+)?a\s+palavra\s+(?:para|de)\s+(.+?)\s+em\s+\S+$',
    r'^o que\s+(?:é|seria)\s+(.+?)\s+em\s+\S+$',
    r'^o que\s+(?:significa|quer dizer)\s+(.+?)$',
    r'^como\s+(?:se\s+)?(?:diz|fala|escreve)\s+(.+?)$',
    r'^(.+?)\s+em\s+(?:ingl[êe]s|english|espanhol|español|franc[êe]s|français)$',
  ];
  // Pedido de FRASE-EXEMPLO por intenção (fase 2): tira as palavras de comando das pontas e o que
  // sobra é o termo — igual ao servidor ("crie uma frase em inglês com a palavra queijo").
  final howToUse = RegExp(
          r'^como\s+(?:eu\s+)?(?:uso|usar|se usa|posso usar|utilizo|utilizar)\s+(?:a\s+)?(?:palavra\s+)?(.+)$',
          caseSensitive: false)
      .firstMatch(q);
  if (howToUse != null) {
    return howToUse
        .group(1)!
        .trim()
        .replaceAll(RegExp(r'\s+(?:em|no idioma|na língua)\s+(?:ingl[êe]s|english)$', caseSensitive: false), '');
  }
  final asksExample =
      RegExp(r'\b(?:frases?|exemplos?|senten[çc]as?|ora[çc][ãõ]es|ora[çc][ãa]o)\b', caseSensitive: false).hasMatch(q);
  if (asksExample && !RegExp(r'^(?:o que|como se|como é|qual|traduz)', caseSensitive: false).hasMatch(q)) {
    final tokens = q.split(' ');
    bool isCommand(String t) => _kLingoCommandWords.contains(t.toLowerCase().replaceAll(RegExp('[\\s\'",]'), ''));
    while (tokens.isNotEmpty && isCommand(tokens.first)) {
      tokens.removeAt(0);
    }
    while (tokens.isNotEmpty && isCommand(tokens.last)) {
      tokens.removeLast();
    }
    if (tokens.isNotEmpty && tokens.length <= 3) return tokens.join(' ');
  }
  for (final pattern in patterns) {
    final m = RegExp(pattern, caseSensitive: false).firstMatch(q);
    if (m != null) {
      var term = m.group(1)!.trim().replaceAll(RegExp('^[\'"]+|[\'"]+\$'), '');
      term = term.replaceAll(RegExp(r'\s+(?:em|no idioma|na língua)\s+(?:ingl[êe]s|english)$', caseSensitive: false), '');
      if (term.isNotEmpty) return term;
    }
  }
  return null;
}

/// Botão secundário "Ouvir resposta": contorno verde-azulado do app (AppColors.teal) sobre o
/// fundo da tela, mesmo formato pílula dos demais botões. Mostra "Falando…" enquanto toca.
class _LingoAudioButton extends StatelessWidget {
  const _LingoAudioButton({super.key, required this.speaking, required this.onPressed});

  final bool speaking;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: speaking ? AppColors.teal.withValues(alpha: 0.14) : Colors.transparent,
        foregroundColor: AppColors.bone,
        disabledForegroundColor: AppColors.bone,
        side: BorderSide(color: AppColors.teal, width: 1.4),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
      ),
      icon: Icon(speaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded, size: 20, color: AppColors.teal),
      label: Text(speaking ? 'Falando…' : 'Ouvir resposta', maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}
