import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mental/api/api_client.dart';

/// Regressão (2026-08-22, teste informal com pessoas de fora): sem
/// timeout/tratamento de erro de rede no ApiClient, uma falha de conexão
/// (ex.: backend do Render "dormindo" e nunca respondendo) não lançava
/// ApiException — as telas (que só capturam `on ApiException catch`)
/// ficavam com o spinner girando pra sempre, sem nenhum erro visível.
void main() {
  test('falha de conexão (SocketException) vira ApiException, não exceção crua', () async {
    final mockClient = MockClient((request) async {
      throw const SocketException('Falha de conexão simulada');
    });
    final client = ApiClient(baseUrl: 'https://example.com', accessToken: 'fake-token', httpClient: mockClient);

    await expectLater(
      client.confirmMajority(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
    );
  });

  test('timeout vira ApiException com código TIMEOUT, não trava para sempre', () async {
    final mockClient = MockClient((request) async {
      // Nunca completa dentro do timeout do ApiClient — simula backend
      // travado/hibernando sem nunca responder.
      await Future.delayed(const Duration(seconds: 5));
      throw StateError('não deveria chegar aqui — o timeout deveria disparar antes');
    });
    final client = ApiClient(
      baseUrl: 'https://example.com',
      accessToken: 'fake-token',
      httpClient: mockClient,
      timeout: const Duration(milliseconds: 100),
    );

    await expectLater(
      client.confirmMajority(),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TIMEOUT')),
    );
  });

  test(
    'conexão recusada (cold start do Render) repete automaticamente e '
    'tem sucesso na 2ª tentativa, sem expor erro nenhum',
    () async {
      // MENTAL_ESPECIFICACAO_TECNICA_APROVADA_MOVIMENTO_v2.docx §9/§25 —
      // a 1ª tentativa nunca chega a ser processada pelo servidor (conexão
      // recusada, container do Render ainda subindo) — repetir é seguro
      // e não duplica nada, diferente de um timeout.
      var attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        if (attempts == 1) throw const SocketException('Conexão recusada simulada (cold start)');
        return http.Response('{"status": "ok"}', 200);
      });
      final client = ApiClient(baseUrl: 'https://example.com', accessToken: 'fake-token', httpClient: mockClient);

      final result = await client.confirmMajority();

      expect(result, {'status': 'ok'});
      expect(attempts, 2);
    },
  );

  test(
    'timeout NUNCA repete sozinho (evita duplicar XP/recompensa numa coleta)',
    () async {
      var attempts = 0;
      final mockClient = MockClient((request) async {
        attempts++;
        await Future.delayed(const Duration(seconds: 5));
        throw StateError('não deveria chegar aqui');
      });
      final client = ApiClient(
        baseUrl: 'https://example.com',
        accessToken: 'fake-token',
        httpClient: mockClient,
        timeout: const Duration(milliseconds: 100),
      );

      await expectLater(client.confirmMajority(), throwsA(isA<ApiException>()));
      expect(attempts, 1);
    },
  );

  test(
    'resposta HTTP 200 com corpo não-JSON (proxy/erro do provedor) vira ApiException, não FormatException crua',
    () async {
      // Achado real: durante cold start do Render, o proxy às vezes
      // devolve uma página de erro HTML mesmo em respostas que o cliente
      // HTTP considera "completas" — jsonDecode lançava FormatException,
      // que não é ApiException e escapava sem tratamento nas telas.
      final mockClient = MockClient((request) async {
        return http.Response('<html><body>502 Bad Gateway</body></html>', 200);
      });
      final client = ApiClient(baseUrl: 'https://example.com', accessToken: 'fake-token', httpClient: mockClient);

      await expectLater(
        client.confirmMajority(),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'NETWORK_ERROR')),
      );
    },
  );
}
