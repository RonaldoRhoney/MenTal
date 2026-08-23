import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
      client.ageGate('adult'),
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
      client.ageGate('adult'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'TIMEOUT')),
    );
  });
}
