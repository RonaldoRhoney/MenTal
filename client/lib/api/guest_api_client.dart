import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_client.dart' show ApiException;

/// MENTAL_FLUXO_GUEST_3_QUESTOES_DIAGNOSTICO_TECNICO_V1.md §3.1 — os
/// únicos 3 endpoints do app que não exigem token de usuário autenticado
/// (ver comentário no topo de backend/app/routers/guest.py). Separado de
/// ApiClient de propósito: ApiClient exige accessToken obrigatório no
/// construtor (estruturalmente impossível ter uma instância sem sessão),
/// então um cliente guest precisa ser outra classe, não um ApiClient com
/// token nulo.
class GuestApiClient {
  GuestApiClient({required this.baseUrl, http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  static const _timeout = Duration(seconds: 60);

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<dynamic> _get(Uri uri) => _wrap(() => _client.get(uri));

  Future<dynamic> _post(Uri uri, Object? body) => _wrap(
        () => _client.post(uri, headers: {'Content-Type': 'application/json'}, body: body),
      );

  Future<dynamic> _wrap(Future<http.Response> Function() request) async {
    try {
      final resp = await request().timeout(_timeout);
      return _decode(resp);
    } on SocketException {
      throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Sem conexão com o servidor. Tente novamente.');
    } on TimeoutException {
      throw ApiException(statusCode: 0, code: 'TIMEOUT', message: 'O servidor demorou demais para responder. Tente novamente.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Sem conexão com o servidor. Tente novamente.');
    }
  }

  dynamic _decode(http.Response resp) {
    dynamic body;
    try {
      body = resp.body.isEmpty ? null : jsonDecode(resp.body);
    } catch (_) {
      throw ApiException(statusCode: resp.statusCode, code: 'DECODE_ERROR', message: 'Resposta inesperada do servidor.');
    }
    if (resp.statusCode >= 200 && resp.statusCode < 300) return body;
    final error = (body is Map && body['error'] is Map) ? body['error'] as Map : null;
    throw ApiException(
      statusCode: resp.statusCode,
      code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
      message: error?['message'] as String? ?? 'Erro inesperado.',
    );
  }

  Future<List<Map<String, dynamic>>> listWorlds() async {
    final body = await _get(_uri('/guest/worlds'));
    return (body as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> nextChallenge(String territoryId) async {
    final body = await _get(_uri('/guest/challenges/next', {'territory_id': territoryId}));
    return body as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitAnswer(String challengeId, String submittedAnswer) async {
    final body = await _post(
      _uri('/guest/challenges/$challengeId/answer'),
      jsonEncode({'submitted_answer': submittedAnswer}),
    );
    return body as Map<String, dynamic>;
  }
}
