import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/screens/mental_lingo_screen.dart';
import 'package:mental/services/lingo_translator.dart';
import 'package:mental/services/mental_lingo_service.dart';

/// MENTAL LINGO (MUNDO/Mundo_dos_Idiomas/Mental_Lingo/MENTAL_LINGO_
/// ASSISTENTE_VOZ_V1.1.md, aprovado 23/09/2026 — escopo V1 custo zero).
/// `speech_to_text` fala com um MethodChannel nativo, sem implementação
/// nenhuma registrada no ambiente de teste `flutter test` — a chamada
/// real lança MissingPluginException, que MentalLingoService.init()
/// captura e transforma em "reconhecimento indisponível" (ver
/// mental_lingo_service.dart). Esse é justamente o caminho que dá pra
/// testar aqui de verdade, sem precisar simular um plugin nativo: o
/// banner de entrada, o estado inicial da tela e o tratamento de erro
/// quando o reconhecimento de voz não está disponível.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');
}

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('MentalLingoBanner mostra "MENTAL LINGO" e abre a tela ao tocar', (tester) async {
    final client = _FakeApiClient();
    await tester.pumpWidget(_app(Scaffold(body: MentalLingoBanner(client: client))));
    expect(find.text('Converse por voz com a IA'), findsOneWidget);
    expect(find.text('Toque para falar'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mental_lingo_banner')));
    await tester.pumpAndSettle();

    expect(find.byType(MentalLingoScreen), findsOneWidget);
  });

  testWidgets('Estado inicial: convite a tocar no microfone, sem pergunta/resposta', (tester) async {
    final client = _FakeApiClient();
    await tester.pumpWidget(_app(MentalLingoScreen(client: client)));
    await tester.pump();

    expect(find.byKey(const Key('mental_lingo_mic_button')), findsOneWidget);
    // MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md (ajuste de 28/09/2026): captura
    // por apertar-e-segurar é o padrão agora, não mais toque único.
    expect(find.textContaining('Aperte e segure o microfone'), findsOneWidget);
    expect(find.byKey(const Key('mental_lingo_question_bubble')), findsNothing);
    expect(find.byKey(const Key('mental_lingo_answer_bubble')), findsNothing);
  });

  testWidgets(
      '3 modos de captura coexistem (MENTAL_LINGO_RELATORIO_TESTES_CAMPO_V1.md, '
      '29/09/2026) e a escolha persiste', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final client = _FakeApiClient();
    await tester.pumpWidget(_app(MentalLingoScreen(client: client)));
    await tester.pump();

    // Os 3 botões existem, "apertar e segurar" é o padrão inicial.
    expect(find.byKey(const Key('mental_lingo_capture_mode_holdToTalk')), findsOneWidget);
    expect(find.byKey(const Key('mental_lingo_capture_mode_tapTwice')), findsOneWidget);
    expect(find.byKey(const Key('mental_lingo_capture_mode_autoDetect')), findsOneWidget);
    expect(find.textContaining('Aperte e segure o microfone'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mental_lingo_capture_mode_autoDetect')));
    await tester.pump();
    // Modo 3 também começa por toque, igual ao Modo 2 (nunca por apertar-e-segurar).
    expect(find.textContaining('Toque no microfone'), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('mental_lingo_capture_mode'), 'autoDetect');

    // O mock de SharedPreferences é global ao isolate de teste — sem
    // resetar aqui, os testes seguintes deste arquivo carregariam
    // "autoDetect" salvo em vez do padrão (achado real: quebrou 3 outros
    // testes que dependem do modo apertar-e-segurar).
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Reconhecimento de voz indisponível mostra erro honesto, sem travar a tela',
      (tester) async {
    final client = _FakeApiClient();
    await tester.pumpWidget(_app(MentalLingoScreen(client: client)));
    await tester.pump();

    // Segura o botão manualmente (em vez de `tester.longPress`, que solta
    // antes do MethodChannel real resolver o erro) — só solta DEPOIS do
    // gap assíncrono de verdade abaixo, igual ao uso real: segurar,
    // aparecer o erro, soltar.
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('mental_lingo_mic_button'))));
    await tester.pump(const Duration(milliseconds: 600));
    // O MethodChannel do speech_to_text não tem implementação registrada
    // no ambiente de teste — a chamada real (MissingPluginException)
    // atravessa um gap assíncrono de verdade, que só `runAsync` destrava
    // (pump/pumpAndSettle sozinhos não avançam esse tipo de await).
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(find.byKey(const Key('mental_lingo_error_text')), findsOneWidget);
    expect(find.byKey(const Key('mental_lingo_retry_button')), findsOneWidget);
  });

  test('extractLingoKeyTerm acha a palavra/frase-chave nos padrões de pergunta', () {
    expect(extractLingoKeyTerm('como se escreve queijo em inglês'), 'queijo');
    expect(extractLingoKeyTerm('Como se diz "bom dia" em espanhol?'), 'bom dia');
    expect(extractLingoKeyTerm('o que significa Wednesday'), 'Wednesday');
    expect(extractLingoKeyTerm('qual é a tradução de casa para francês'), 'casa');
    expect(extractLingoKeyTerm('use queijo em uma frase'), 'queijo');
    expect(extractLingoKeyTerm('me dê um exemplo com Cheese'), 'Cheese');
    expect(extractLingoKeyTerm('como uso hot?'), 'hot');
    expect(extractLingoKeyTerm('Oi, então você pode me dizer como se escreve queijo em inglês, por favor?'), 'queijo');
    expect(extractLingoKeyTerm('como se diz queijo em inglês.'), 'queijo');
    expect(extractLingoKeyTerm('me dê uma frase com a palavra queijo em inglês'), 'queijo');
    expect(extractLingoKeyTerm('o que é queijo em inglês?'), 'queijo');
    expect(extractLingoKeyTerm('crie uma frase em inglês com a palavra queijo'), 'queijo');
    expect(extractLingoKeyTerm('faz um exemplo curto com café da manhã'), 'café da manhã');
    expect(extractLingoKeyTerm('use house numa frase'), 'house');
    expect(extractLingoKeyTerm('oi tudo bem'), isNull);
  });

  testWidgets('Frase fora do vocabulário é traduzida no aparelho e o termo traduzido ganha destaque', (tester) async {
    final client = _PhraseApi({'found': false, 'intent': 'translate', 'phrase': 'eu quero um café', 'target_language': 'ingles', 'answer_text': 'x'});
    final translator = _FakeTranslator(out: 'I want a coffee');
    await tester.pumpWidget(_app(MentalLingoScreen(
        client: client, service: _FakeSpeech('como se diz eu quero um café em inglês'), translator: translator)));
    await tester.pump();
    await tester.longPress(find.byKey(const Key('mental_lingo_mic_button')));
    await tester.pump();
    // Prazo de segurança que aguarda o resultado final chegar depois de
    // soltar o botão (MENTAL_LINGO_ASSISTENTE_VOZ_V1.1.md, apertar-e-segurar).
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(translator.calls, [('eu quero um café', 'pt', 'ingles')]);
    expect(find.byKey(const Key('mental_lingo_answer_bubble')), findsOneWidget);
    expect(find.textContaining("'eu quero um café' se traduz como 'I want a coffee'", findRichText: true), findsOneWidget);
    expect(find.textContaining('Tradução automática feita no seu aparelho', findRichText: true), findsOneWidget);
  });

  testWidgets('Falha na tradução mostra mensagem honesta, sem inventar', (tester) async {
    final client = _PhraseApi({'found': false, 'intent': 'translate', 'phrase': 'bom dia a todos', 'target_language': 'espanhol', 'answer_text': 'x'});
    final translator = _FakeTranslator(fail: true);
    await tester.pumpWidget(_app(MentalLingoScreen(
        client: client, service: _FakeSpeech('como se diz bom dia a todos em espanhol'), translator: translator)));
    await tester.pump();
    await tester.longPress(find.byKey(const Key('mental_lingo_mic_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    expect(find.textContaining('Não consegui baixar o idioma', findRichText: true), findsOneWidget);
    expect(find.textContaining('Tradução automática', findRichText: true), findsNothing);
  });
}

class _PhraseApi extends ApiClient {
  _PhraseApi(this._reply) : super(baseUrl: 'http://fake', accessToken: 'fake-token');
  final Map<String, dynamic> _reply;
  @override
  Future<Map<String, dynamic>> askMentalLingo(String question) async => _reply;
}

class _FakeSpeech extends MentalLingoService {
  _FakeSpeech(this._said) : super.forTesting();
  final String _said;
  // O reconhecedor real só responde quando alguém fala: entrega a fala UMA vez (a tela reabre a
  // escuta depois de cada resultado; se o falso respondesse sempre, o teste entraria em laço infinito).
  bool _delivered = false;
  @override
  Future<bool> init({required void Function(String message) onError, required void Function(String status) onStatus}) async => true;
  @override
  Future<void> listen({
    required void Function(String text) onFinalResult,
    void Function(String text)? onPartialResult,
    Duration? silenceTimeout,
  }) async {
    if (_delivered) return;
    _delivered = true;
    onFinalResult(_said);
  }
  @override
  Future<void> cancel() async {}
  @override
  Future<void> stop() async {}
}

class _FakeTranslator implements LingoTranslator {
  _FakeTranslator({this.out = '', this.fail = false});
  final String out;
  final bool fail;
  final List<(String, String, String)> calls = [];
  @override
  Future<String?> detectLanguage(String text) async => 'ingles';
  @override
  Future<String> translate(String text, {required String from, required String to, void Function()? onDownloading}) async {
    calls.add((text, from, to));
    if (fail) throw LingoTranslateException('Não consegui baixar o idioma de tradução. Verifique a internet e tente de novo.');
    return out;
  }
}
