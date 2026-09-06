import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/services/feed_activity_service.dart';

/// FEED_SOCIAL_V1.md — badge de atividade nova no card "Amigos" da
/// Home. "Visto" é rastreado só no dispositivo (SharedPreferences),
/// nunca no backend.
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.events) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final List<Map<String, dynamic>> events;

  @override
  Future<Map<String, dynamic>> getFeed({String? before}) async {
    return {'events': events, 'next_cursor': null};
  }
}

Map<String, dynamic> _event(String createdAt) => {
      'id': createdAt,
      'user_id': 'user-1',
      'nickname': 'joao123',
      'photo_url': null,
      'event_type': 'level_up_milestone',
      'text': 'joao123 chegou ao Nível 20! ⭐',
      'created_at': createdAt,
    };

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('nunca visto antes conta todos os eventos da primeira página', () async {
    final client = _FakeApiClient([_event('2026-09-06T10:00:00'), _event('2026-09-05T10:00:00')]);
    expect(await FeedActivityService.unseenCount(client), 2);
  });

  test('markSeen registra o evento mais recente, unseenCount some depois', () async {
    final client = _FakeApiClient([_event('2026-09-06T10:00:00'), _event('2026-09-05T10:00:00')]);
    await FeedActivityService.markSeen(client.events);
    expect(await FeedActivityService.unseenCount(client), 0);
  });

  test('conta só os eventos mais recentes que o último visto', () async {
    await FeedActivityService.markSeen([_event('2026-09-05T10:00:00')]);
    final client = _FakeApiClient([_event('2026-09-06T10:00:00'), _event('2026-09-05T10:00:00')]);
    expect(await FeedActivityService.unseenCount(client), 1);
  });

  test('falha de rede nunca trava — trata como zero', () async {
    final client = _FailingApiClient();
    expect(await FeedActivityService.unseenCount(client), 0);
  });
}

class _FailingApiClient extends ApiClient {
  _FailingApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> getFeed({String? before}) async {
    throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Sem conexão');
  }
}
