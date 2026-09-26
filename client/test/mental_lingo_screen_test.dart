import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(find.textContaining('Toque no microfone'), findsOneWidget);
    expect(find.byKey(const Key('mental_lingo_question_bubble')), findsNothing);
    expect(find.byKey(const Key('mental_lingo_answer_bubble')), findsNothing);
  });

  testWidgets('Reconhecimento de voz indisponível mostra erro honesto, sem travar a tela',
      (tester) async {
    final client = _FakeApiClient();
    await tester.pumpWidget(_app(MentalLingoScreen(client: client)));
    await tester.pump();

    await tester.tap(find.byKey(const Key('mental_lingo_mic_button')));
    // O MethodChannel do speech_to_text não tem implementação registrada
    // no ambiente de teste — a chamada real (MissingPluginException)
    // atravessa um gap assíncrono de verdade, que só `runAsync` destrava
    // (pump/pumpAndSettle sozinhos não avançam esse tipo de await).
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await tester.pump();

    expect(find.byKey(const Key('mental_lingo_error_text')), findsOneWidget);
    expect(find.byKey(const Key('mental_lingo_retry_button')), findsOneWidget);
  });

  test('extractLingoKeyTerm acha a palavra/frase-chave nos padrões de pergunta', () {
    expect(extractLingoKeyTerm('como se escreve queijo em inglês'), 'queijo');
    expect(extractLingoKeyTerm('Como se diz "bom dia" em espanhol?'), 'bom dia');
    expect(extractLingoKeyTerm('o que significa Wednesday'), 'Wednesday');
    expect(extractLingoKeyTerm('qual é a tradução de casa para francês'), 'casa');
    expect(extractLingoKeyTerm('oi tudo bem'), isNull);
  });

  testWidgets('Frase fora do vocabulário é traduzida no aparelho e o termo traduzido ganha destaque', (tester) async {
    final client = _PhraseApi({'found': false, 'intent': 'translate', 'phrase': 'eu quero um café', 'target_language': 'ingles', 'answer_text': 'x'});
    final translator = _FakeTranslator(out: 'I want a coffee');
    await tester.pumpWidget(_app(MentalLingoScreen(
        client: client, service: _FakeSpeech('como se diz eu quero um café em inglês'), translator: translator)));
    await tester.pump();
    await tester.tap(find.byKey(const Key('mental_lingo_mic_button')));
    await tester.pump();
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
    await tester.tap(find.byKey(const Key('mental_lingo_mic_button')));
    await tester.pump();
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
  Future<void> listen({required void Function(String text) onFinalResult}) async {
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
