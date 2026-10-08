import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

/// MENTAL_AGENTE_FLUTUANTE_V1.md + MENTAL_AGENTE_FLUTUANTE_DIAGNOSTICO_
/// TECNICO_V1.md (aprovado por Rhoney 07-08/10/2026) — estado do
/// personagem "Mental" flutuante, visível em (quase) toda tela do app.
///
/// Visibilidade final = enabled && homeReached && hiddenDepth == 0.
/// `hiddenDepth` é um contador único (não um bool) incrementado/
/// decrementado por qualquer tela que precise esconder o personagem
/// enquanto estiver montada — ChallengeScreen (todo território, não só
/// Idiomas: simplificação deliberada da v1, granularidade por FASE da
/// pergunta — perguntar/resultado — fica pra uma iteração futura),
/// MentalLingoScreen, WordConstellationScreen (Mundo dos Idiomas nunca
/// muda, §2/§7 do diagnóstico) e SettingsScreen (dúvida #6 do documento
/// original). Contador em vez de bool pra suportar telas aninhadas sem
/// uma reaparecer cedo demais por engano.
class FloatingMentalController extends ChangeNotifier {
  FloatingMentalController._();

  static final FloatingMentalController instance = FloatingMentalController._();

  static const _kEnabledKey = 'floating_mental_enabled_v1';
  static const _kPosXKey = 'floating_mental_pos_x_v1';
  static const _kPosYKey = 'floating_mental_pos_y_v1';

  bool _enabled = true;
  bool get enabled => _enabled;

  // Vira true uma única vez, quando a Home é alcançada pela primeira vez
  // nesta sessão do app — resolve de graça login/cadastro/age-gate/
  // onboarding/fluxo guest (dúvidas #4 e #6 do documento) sem precisar
  // de opt-out explícito em cada uma dessas telas.
  bool _homeReached = false;
  bool get homeReached => _homeReached;

  int _hiddenDepth = 0;

  Offset? _position;
  Offset? get position => _position;

  bool get visible => _enabled && _homeReached && _hiddenDepth == 0;

  // §6 do diagnóstico — o selo "Dica do My_Mental_AI" saiu da Home (o
  // personagem flutuante ocupa esse lugar), mas CoachScreen continua
  // existindo e alcançável a partir do painel do personagem ("ver mais
  // dicas"). Setado por main.dart (_updateClientFromSession), limpo no
  // logout — mesma vida útil do ApiClient da sessão.
  ApiClient? currentClient;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kEnabledKey) ?? true;
      final x = prefs.getDouble(_kPosXKey);
      final y = prefs.getDouble(_kPosYKey);
      if (x != null && y != null) _position = Offset(x, y);
    } catch (_) {
      // Falha de leitura nunca trava o app — personagem nasce ligado,
      // sem posição salva (a tela decide uma posição padrão).
    }
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabledKey, value);
    } catch (_) {}
  }

  void setHomeReached() {
    if (_homeReached) return;
    _homeReached = true;
    notifyListeners();
  }

  void pushHidden() {
    _hiddenDepth++;
    notifyListeners();
  }

  void popHidden() {
    if (_hiddenDepth > 0) _hiddenDepth--;
    notifyListeners();
  }

  Future<void> updatePosition(Offset position) async {
    _position = position;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kPosXKey, position.dx);
      await prefs.setDouble(_kPosYKey, position.dy);
    } catch (_) {}
  }
}

/// Wrapper sem UI própria — a tela só precisa envolver o que já retorna
/// hoje com `FloatingMentalHider(child: ...)` pra esconder o personagem
/// enquanto estiver montada, sem precisar tocar no próprio initState/
/// dispose da tela (menor diff possível nas telas grandes como
/// challenge_screen.dart e mental_lingo_screen.dart).
class FloatingMentalHider extends StatefulWidget {
  const FloatingMentalHider({super.key, required this.child});

  final Widget child;

  @override
  State<FloatingMentalHider> createState() => _FloatingMentalHiderState();
}

class _FloatingMentalHiderState extends State<FloatingMentalHider> {
  @override
  void initState() {
    super.initState();
    FloatingMentalController.instance.pushHidden();
  }

  @override
  void dispose() {
    FloatingMentalController.instance.popHidden();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
