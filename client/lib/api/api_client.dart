import 'dart:convert';
import 'package:http/http.dart' as http;

/// Cliente HTTP para a API MENTAL (Vertical Slice 01).
///
/// GAP CONHECIDO, documentado no relatório do Vertical Slice 01: não existe
/// ainda um projeto Supabase real configurado para o MENTAL, então este
/// cliente usa o mesmo modo DEV_INSECURE do backend (backend/app/auth.py)
/// — o "token" enviado é o próprio user_id em texto puro, gerado uma vez
/// e persistido localmente (ver SessionStore). Antes de qualquer build de
/// release, isso precisa ser substituído por login real via Supabase Auth
/// (ARCHITECTURE.md §4) — não é uma decisão de arquitetura, é ausência de
/// infraestrutura ainda não provisionada.
class ApiClient {
  ApiClient({required this.baseUrl, required this.userId});

  final String baseUrl;
  final String userId;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $userId',
        'Content-Type': 'application/json',
      };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> ageGate(String ageMode) async {
    final resp = await http.post(
      _uri('/age-gate'),
      headers: _headers,
      body: jsonEncode({'age_mode': ageMode}),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    final resp = await http.get(
      _uri('/challenges/next', {'territory_id': territoryId, 'mode': mode}),
      headers: _headers,
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> requestHint(String challengeId, String attemptId) async {
    final resp = await http.post(
      _uri('/challenges/$challengeId/hint'),
      headers: _headers,
      body: jsonEncode({'attempt_id': attemptId}),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> submitAnswer(
    String challengeId,
    String attemptId,
    String submittedAnswer, {
    int? responseTimeMs,
    bool timedOut = false,
  }) async {
    final resp = await http.post(
      _uri('/challenges/$challengeId/answer'),
      headers: _headers,
      body: jsonEncode({
        'attempt_id': attemptId,
        'submitted_answer': submittedAnswer,
        'response_time_ms': responseTimeMs,
        'timed_out': timedOut,
      }),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> progress() async {
    final resp = await http.get(_uri('/progress'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> ranking({String scope = 'global', String window = 'weekly'}) async {
    final resp = await http.get(
      _uri('/ranking', {'scope': scope, 'window': window}),
      headers: _headers,
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> getInviteCode() async {
    final resp = await http.get(_uri('/social/invite-code'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> addFriend(String inviteCode) async {
    final resp = await http.post(
      _uri('/social/friends'),
      headers: _headers,
      body: jsonEncode({'invite_code': inviteCode}),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> getFriends() async {
    final resp = await http.get(_uri('/social/friends'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> rewardShare() async {
    final resp = await http.post(_uri('/social/share-reward'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> createBattle({
    required String opponentUserId,
    required String territoryId,
    required int difficultyLevel,
  }) async {
    final resp = await http.post(
      _uri('/battles'),
      headers: _headers,
      body: jsonEncode({
        'opponent_user_id': opponentUserId,
        'territory_id': territoryId,
        'difficulty_level': difficultyLevel,
      }),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> getMyBattleChallenge(String battleId) async {
    final resp = await http.get(_uri('/battles/$battleId/my-challenge'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> listBattles() async {
    final resp = await http.get(_uri('/battles'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> getProfile() async {
    final resp = await http.get(_uri('/profile'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> updateProfile({
    String? avatarId,
    String? realName,
    String? locationState,
    String? locationCountry,
    required bool locationPublic,
  }) async {
    final resp = await http.put(
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
    return _decode(resp);
  }

  Future<Map<String, dynamic>> badges() async {
    final resp = await http.get(_uri('/badges'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> stats() async {
    final resp = await http.get(_uri('/stats'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> registerPushToken(String pushToken) async {
    final resp = await http.post(
      _uri('/notifications/register-token'),
      headers: _headers,
      body: jsonEncode({'push_token': pushToken}),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> getNotificationPreferences() async {
    final resp = await http.get(_uri('/notifications/preferences'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> updateNotificationPreferences({
    required bool reengagementEnabled,
    required bool socialEnabled,
  }) async {
    final resp = await http.put(
      _uri('/notifications/preferences'),
      headers: _headers,
      body: jsonEncode({'reengagement_enabled': reengagementEnabled, 'social_enabled': socialEnabled}),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> enableMovement() async {
    final resp = await http.post(_uri('/movement/enable'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> disableMovement() async {
    final resp = await http.post(_uri('/movement/disable'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> movementStatus() async {
    final resp = await http.get(_uri('/movement/status'), headers: _headers);
    return _decode(resp);
  }

  Future<Map<String, dynamic>> setMovementGoal(int? dailyGoalSteps) async {
    final resp = await http.put(
      _uri('/movement/goal'),
      headers: _headers,
      body: jsonEncode({'daily_goal_steps': dailyGoalSteps}),
    );
    return _decode(resp);
  }

  Future<Map<String, dynamic>> collectMovementSteps({required int steps, String? cycleId}) async {
    final resp = await http.post(
      _uri('/movement/collect'),
      headers: _headers,
      body: jsonEncode({'steps': steps, 'cycle_id': cycleId}),
    );
    return _decode(resp);
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
