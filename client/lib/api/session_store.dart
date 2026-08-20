import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persiste o user_id local usado no modo DEV_INSECURE (ver api_client.dart).
class SessionStore {
  static const _key = 'mental_dev_user_id';

  Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null) return existing;

    final newId = const Uuid().v4();
    await prefs.setString(_key, newId);
    return newId;
  }
}
