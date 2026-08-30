import 'package:shared_preferences/shared_preferences.dart';

/// "Como usar o MENTAL" — tutorial de 6 telas (29/08/2026, pedido de
/// Rhoney): aparece uma vez, logo após o splash, antes de qualquer
/// login — puramente local (não é dado de jogo, não precisa de conta
/// nem de backend). Fica sempre disponível de novo em Ajuste
/// (settings_screen.dart), que só abre a tela sem mexer nesta flag.
class OnboardingTutorialService {
  OnboardingTutorialService._();

  static const _kPrefsKey = 'onboarding_tutorial_seen_v1';

  static Future<bool> hasSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kPrefsKey) ?? false;
    } catch (_) {
      // Falha de leitura nunca deve travar o app na tela de tutorial pra
      // sempre — melhor pular do que prender o usuário.
      return true;
    }
  }

  static Future<void> markSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefsKey, true);
    } catch (_) {}
  }
}
