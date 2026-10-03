import 'package:shared_preferences/shared_preferences.dart';

/// MUNDO_IDIOMAS_PROGRESSAO_POR_FASE_V1.md §7 — lembra, por aparelho
/// (mesmo padrão de onboarding_tutorial_service.dart), se a celebração
/// de "Mundo conquistado" já apareceu pra este Mundo, pra nunca repetir
/// o mesmo evento toda vez que o jogador reabre a tela do Mundo depois
/// de já ter visto a celebração uma vez.
class WorldCelebrationService {
  WorldCelebrationService._();

  static const _kPrefsKeyPrefix = 'world_celebration_seen_v1_';

  static Future<bool> hasCelebrated(String worldId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('$_kPrefsKeyPrefix$worldId') ?? false;
    } catch (_) {
      // Falha de leitura nunca deve travar a tela — na dúvida, deixa
      // celebrar de novo (pior caso é repetir uma vez, não travar nada).
      return false;
    }
  }

  static Future<void> markCelebrated(String worldId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_kPrefsKeyPrefix$worldId', true);
    } catch (_) {}
  }
}
