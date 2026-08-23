import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente HTTP para a API MENTAL.
///
/// Login real via Supabase Auth (docs/02_IMPLEMENTATION/SUPABASE_SETUP.md
/// §5, implementado 2026-08-22): accessToken é o JWT real da sessão
/// (`Supabase.instance.client.auth.currentSession?.accessToken`), validado
/// no backend via JWKS (backend/app/auth.py) — nunca mais o modo
/// DEV_INSECURE (user_id em texto puro), que só o backend local sem
/// SUPABASE_URL configurado ainda aceita, pra desenvolvimento.
class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.accessToken,
    http.Client? httpClient,
    Duration timeout = const Duration(seconds: 30),
  })  : _client = httpClient ?? http.Client(),
        _timeout = timeout;

  final String baseUrl;
  final String accessToken;
  final http.Client _client;
  final Duration _timeout;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  // Todo request passa por aqui — Achados reais (2026-08-22, teste
  // informal): (1) sem timeout, uma falha de rede (backend do Render
  // "dormindo", cold start, conexão perdida) nunca lançava ApiException,
  // deixando o spinner girando pra sempre; (2) mesmo com timeout, um
  // proxy/erro do provedor pode devolver uma resposta HTTP "bem-sucedida"
  // com corpo não-JSON (página HTML de erro) durante o cold start —
  // `jsonDecode` lançava `FormatException`, que também escapava do único
  // catch que as telas têm (`on ApiException catch`), resetando a tela
  // pros botões iniciais sem nenhum erro visível. Por isso o decode
  // acontece AQUI DENTRO do mesmo try/catch, não depois — toda falha do
  // pipeline completo (rede, timeout, decode) vira ApiException.
  Future<Map<String, dynamic>> _get(Uri uri, {Map<String, String>? headers}) =>
      _wrap(() => _client.get(uri, headers: headers));

  Future<Map<String, dynamic>> _post(Uri uri, {Map<String, String>? headers, Object? body}) =>
      _wrap(() => _client.post(uri, headers: headers, body: body));

  Future<Map<String, dynamic>> _put(Uri uri, {Map<String, String>? headers, Object? body}) =>
      _wrap(() => _client.put(uri, headers: headers, body: body));

  Future<Map<String, dynamic>> _wrap(Future<http.Response> Function() request) async {
    try {
      final resp = await request().timeout(_timeout);
      return _decode(resp);
    } on TimeoutException {
      throw ApiException(
        statusCode: 0,
        code: 'TIMEOUT',
        message: 'O servidor demorou demais para responder. Tente novamente.',
      );
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        statusCode: 0,
        code: 'NETWORK_ERROR',
        message: 'Sem conexão com o servidor. Tente novamente.',
      );
    }
  }

  Future<Map<String, dynamic>> ageGate(String ageMode) async {
    return _post(
      _uri('/age-gate'),
      headers: _headers,
      body: jsonEncode({'age_mode': ageMode}),
    );
  }

  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return _get(
      _uri('/challenges/next', {'territory_id': territoryId, 'mode': mode}),
      headers: _headers,
    );
  }

  Future<Map<String, dynamic>> requestHint(String challengeId, String attemptId) async {
    return _post(
      _uri('/challenges/$challengeId/hint'),
      headers: _headers,
      body: jsonEncode({'attempt_id': attemptId}),
    );
  }

  Future<Map<String, dynamic>> submitAnswer(
    String challengeId,
    String attemptId,
    String submittedAnswer, {
    int? responseTimeMs,
    bool timedOut = false,
  }) async {
    return _post(
      _uri('/challenges/$challengeId/answer'),
      headers: _headers,
      body: jsonEncode({
        'attempt_id': attemptId,
        'submitted_answer': submittedAnswer,
        'response_time_ms': responseTimeMs,
        'timed_out': timedOut,
      }),
    );
  }

  Future<Map<String, dynamic>> progress() async {
    return _get(_uri('/progress'), headers: _headers);
  }

  Future<Map<String, dynamic>> ranking({String scope = 'global', String window = 'weekly'}) async {
    return _get(
      _uri('/ranking', {'scope': scope, 'window': window}),
      headers: _headers,
    );
  }

  Future<Map<String, dynamic>> getInviteCode() async {
    return _get(_uri('/social/invite-code'), headers: _headers);
  }

  Future<Map<String, dynamic>> addFriend(String inviteCode) async {
    return _post(
      _uri('/social/friends'),
      headers: _headers,
      body: jsonEncode({'invite_code': inviteCode}),
    );
  }

  Future<Map<String, dynamic>> getFriends() async {
    return _get(_uri('/social/friends'), headers: _headers);
  }

  Future<Map<String, dynamic>> rewardShare() async {
    return _post(_uri('/social/share-reward'), headers: _headers);
  }

  Future<Map<String, dynamic>> createBattle({
    required String opponentUserId,
    required String territoryId,
    required int difficultyLevel,
  }) async {
    return _post(
      _uri('/battles'),
      headers: _headers,
      body: jsonEncode({
        'opponent_user_id': opponentUserId,
        'territory_id': territoryId,
        'difficulty_level': difficultyLevel,
      }),
    );
  }

  Future<Map<String, dynamic>> getMyBattleChallenge(String battleId) async {
    return _get(_uri('/battles/$battleId/my-challenge'), headers: _headers);
  }

  Future<Map<String, dynamic>> listBattles() async {
    return _get(_uri('/battles'), headers: _headers);
  }

  Future<Map<String, dynamic>> getProfile() async {
    return _get(_uri('/profile'), headers: _headers);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? avatarId,
    String? realName,
    String? locationState,
    String? locationCountry,
    required bool locationPublic,
  }) async {
    return _put(
      _uri('/profile'),
      headers: _headers,
      body: jsonEncode({
        'avatar_id': avatarId,
        'real_name': realName,
        'location_state': locationState,
        'location_country': locationCountry,
        'location_public': locationPublic,
      }),
    );
  }

  Future<Map<String, dynamic>> badges() async {
    return _get(_uri('/badges'), headers: _headers);
  }

  Future<Map<String, dynamic>> stats() async {
    return _get(_uri('/stats'), headers: _headers);
  }

  Future<Map<String, dynamic>> registerPushToken(String pushToken) async {
    return _post(
      _uri('/notifications/register-token'),
      headers: _headers,
      body: jsonEncode({'push_token': pushToken}),
    );
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    return _get(_uri('/notifications/preferences'), headers: _headers);
  }

  Future<Map<String, dynamic>> updateNotificationPreferences({
    required bool reengagementEnabled,
    required bool socialEnabled,
  }) async {
    return _put(
      _uri('/notifications/preferences'),
      headers: _headers,
      body: jsonEncode({'reengagement_enabled': reengagementEnabled, 'social_enabled': socialEnabled}),
    );
  }

  Future<Map<String, dynamic>> enableMovement() async {
    return _post(_uri('/movement/enable'), headers: _headers);
  }

  Future<Map<String, dynamic>> disableMovement() async {
    return _post(_uri('/movement/disable'), headers: _headers);
  }

  Future<Map<String, dynamic>> movementStatus() async {
    return _get(_uri('/movement/status'), headers: _headers);
  }

  Future<Map<String, dynamic>> setMovementGoal(int? dailyGoalSteps) async {
    return _put(
      _uri('/movement/goal'),
      headers: _headers,
      body: jsonEncode({'daily_goal_steps': dailyGoalSteps}),
    );
  }

  Future<Map<String, dynamic>> collectMovementSteps({required int steps, String? cycleId}) async {
    return _post(
      _uri('/movement/collect'),
      headers: _headers,
      body: jsonEncode({'steps': steps, 'cycle_id': cycleId}),
    );
  }

  Map<String, dynamic> _decode(http.Response resp) {
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 400) {
      final error = body['error'] as Map<String, dynamic>?;
      throw ApiException(
        statusCode: resp.statusCode,
        code: error?['code'] as String? ?? 'UNKNOWN_ERROR',
        message: error?['message'] as String? ?? 'Erro desconhecido',
      );
    }
    return body;
  }
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.code, required this.message});

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => 'ApiException($statusCode, $code, $message)';
}
