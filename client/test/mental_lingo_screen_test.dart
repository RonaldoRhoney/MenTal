import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/screens/mental_lingo_screen.dart';

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
}
