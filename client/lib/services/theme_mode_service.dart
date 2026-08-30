import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Alternância claro/escuro (29/08/2026, pedido de Rhoney: botão na Home
/// pra trocar de tom). Padrão continua o escuro original — só muda
/// quando o usuário escolher, e a escolha persiste entre sessões.
///
/// ChangeNotifier global (mesmo padrão de singleton já usado em
/// MovementService.instance) em vez de InheritedWidget/Theme.of(context):
/// AppColors (theme/app_theme.dart) é consumida como constante estática
/// direto em ~30 arquivos da UI, sem passar por context — plugar um
/// ThemeExtension exigiria reescrever todos esses pontos. Aqui, o toggle
/// só precisa notificar o topo da árvore (main.dart) pra reconstruir o
/// MaterialApp; os getters de AppColors já resolvem sozinhos pro tom
/// atual em qualquer novo build() que rodar depois disso.
class ThemeModeService extends ChangeNotifier {
  ThemeModeService._();
  static final ThemeModeService instance = ThemeModeService._();

  static const _kPrefsKey = 'app_dark_mode_v1';

  bool _isDark = true;
  bool get isDark => _isDark;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getBool(_kPrefsKey);
      if (saved != null && saved != _isDark) {
        _isDark = saved;
        notifyListeners();
      }
    } catch (_) {
      // Preferência de tom é reforço visual, nunca bloqueia o app —
      // mesmo princípio dos demais serviços (ex.: PushService).
    }
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPrefsKey, _isDark);
    } catch (_) {}
  }
}
