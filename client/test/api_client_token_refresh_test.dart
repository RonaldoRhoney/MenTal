import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:mental/api/api_client.dart';

/// Regressão (27/09/2026, Mental Lingo): a tela aberta segurava o ApiClient com o token de quando
/// foi criada; depois de ~1h o servidor respondia 401 "Signature has expired" e o jogador via o
/// erro cru. Agora o ApiClient usa o token mais recente da sessão e, num 401, renova e repete 1x.
void main() {
  tearDown(() {
    ApiClient.latestAccessToken = null;
    ApiClient.refreshAccessToken = null;
  });

  test('usa o token mais recente da sessão, mesmo num ApiClient criado com token antigo', () async {
    final seen = <String?>[];
    final mock = MockClient((request) async {
      seen.add(request.headers['Authorization']);
      return http.Response(jsonEncode({'ok': true}), 200);
    });
    final client = ApiClient(baseUrl: 'https://x', accessToken: 'antigo', httpClient: mock);
    await client.askMentalLingo('oi');
    ApiClient.latestAccessToken = 'novo';
    await client.askMentalLingo('oi');
    expect(seen, ['Bearer antigo', 'Bearer novo']);
  });

  test('401 (token vencido) renova a sessão e repete a chamada uma vez, sem erro para o jogador', () async {
    final seen = <String?>[];
    final mock = MockClient((request) async {
      seen.add(request.headers['Authorization']);
      if (request.headers['Authorization'] == 'Bearer vencido') {
        return http.Response(jsonEncode({'detail': 'Signature has expired'}), 401);
      }
      return http.Response(jsonEncode({'found': true}), 200);
    });
    var refreshCalls = 0;
    ApiClient.refreshAccessToken = () async {
      refreshCalls++;
      return 'renovado';
    };
    final client = ApiClient(baseUrl: 'https://x', accessToken: 'vencido', httpClient: mock);
    final result = await client.askMentalLingo('oi');
    expect(result['found'], true);
    expect(seen, ['Bearer vencido', 'Bearer renovado']);
    expect(refreshCalls, 1);
    expect(ApiClient.latestAccessToken, 'renovado');
  });

  test('401 sem renovação possível mostra o erro (não repete em laço)', () async {
    var calls = 0;
    final mock = MockClient((request) async {
      calls++;
      return http.Response(jsonEncode({'detail': 'Signature has expired'}), 401);
    });
    ApiClient.refreshAccessToken = () async => null;
    final client = ApiClient(baseUrl: 'https://x', accessToken: 'vencido', httpClient: mock);
    await expectLater(client.askMentalLingo('oi'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)));
    expect(calls, 1);
  });
}
