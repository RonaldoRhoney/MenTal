import 'dart:convert';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// V2 item 9 — Contador de passos (STEP_COUNTER_MOVIMENTO.md). O sensor
/// TYPE_STEP_COUNTER (via pacote `pedometer`) devolve a contagem
/// CUMULATIVA desde o último boot do aparelho — não desde que o app foi
/// aberto. Isso permite calcular o total de passos de um ciclo mesmo que
/// o app tenha ficado fechado boa parte do tempo: basta guardar
/// localmente qual era a leitura do sensor quando o ciclo começou (o
/// "baseline") e subtrair da leitura atual sempre que o app reabrir.
/// Único caso não coberto: reboot do aparelho no meio do ciclo zera o
/// contador de hardware — limitação conhecida e aceitável para uma
/// feature de bônus, não faz parte da autoridade de XP/score do jogo.
///
/// O backend continua sendo a única autoridade sobre XP: este serviço só
/// decide QUANTOS passos ainda não foram enviados (delta local), nunca
/// decide o bônus — isso é sempre calculado em app/movement.py.
class MovementLocalDelta {
  MovementLocalDelta({required this.uncollectedSteps, required this.totalStepsInCycle});

  final int uncollectedSteps;
  final int totalStepsInCycle;
}

class MovementService {
  MovementService._();
  static final MovementService instance = MovementService._();

  static const _kStateKey = 'movement_cycle_state_v1';
  static const _kLastKnownRawStepsKey = 'movement_last_known_raw_steps_v1';

  Map<String, dynamic> _state = {};
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStateKey);
    if (raw != null) {
      try {
        _state = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        _state = {};
      }
    }
    _loaded = true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStateKey, jsonEncode(_state));
  }

  Future<bool> hasPermission() async {
    try {
      return await Permission.activityRecognition.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final status = await Permission.activityRecognition.request();
      return status.isGranted;
    } catch (_) {
      // Canal de plugin indisponível (ex.: ambiente de teste sem mock,
      // ou aparelho/versão sem suporte) — a feature fica indisponível,
      // nunca derruba o app (mesmo princípio de FeedbackService).
      return false;
    }
  }

  /// Achado real testando no Moto G22 (2026-08-21): TYPE_STEP_COUNTER só
  /// emite um evento quando um passo de verdade é detectado depois do
  /// listener ser registrado — não existe "leitura imediata" ao
  /// assinar o stream, ao contrário do que a documentação do pacote
  /// sugere (confirmado também em issues públicas do próprio pacote e na
  /// documentação da Android sobre TYPE_STEP_COUNTER: o evento só chega
  /// quando há atividade ou flush do sensor, não ao registrar). Por isso
  /// a tela precisa manter uma assinatura VIVA (streamSubscription), não
  /// pedir uma leitura pontual com timeout.
  ///
  /// Toda leitura recebida por QUALQUER tela (Home ou Movimento) é
  /// gravada como "última leitura conhecida" (ver [lastKnownRawSteps]) —
  /// é isso que permite mostrar o total certo assim que o app reabre,
  /// mesmo que o usuário tenha ficado com o app fechado andando: a
  /// decisão de Rhoney (2026-08-21) foi "catch-up ao reabrir", não
  /// serviço em segundo plano com notificação fixa — o total sempre bate
  /// porque o sensor de hardware é cumulativo desde o boot, independente
  /// de haver ou não um listener registrado.
  Stream<int> stepCountStream() {
    return Pedometer.stepCountStream.asyncMap((event) async {
      await recordRawSteps(event.steps);
      return event.steps;
    });
  }

  Future<void> recordRawSteps(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastKnownRawStepsKey, steps);
  }

  /// Última leitura do sensor conhecida, de QUALQUER sessão do app —
  /// permite mostrar um valor correto imediatamente ao reabrir, antes
  /// mesmo de um novo evento do sensor chegar nesta sessão.
  Future<int?> lastKnownRawSteps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kLastKnownRawStepsKey);
  }

  /// Garante que um ciclo novo já nasça com baseline correto usando a
  /// última leitura conhecida (em vez de esperar um evento fresco, que
  /// pode demorar). Se nunca houve nenhuma leitura (ativação bem
  /// recente, sensor nunca lido antes), não faz nada — pendingDeltaFor
  /// cria o baseline na primeira leitura real que chegar, como fallback.
  Future<void> ensureBaselineFor(String cycleId) async {
    await ensureLoaded();
    if (_state.containsKey(cycleId)) return;
    final last = await lastKnownRawSteps();
    if (last == null) return;
    _state[cycleId] = {'baseline': last, 'lastSubmittedTotal': 0};
    await _persist();
  }

  /// Calcula quantos passos deste ciclo ainda não foram submetidos ao
  /// backend. Na primeira vez que um `cycleId` é visto sem baseline
  /// ainda definido (nem por [ensureBaselineFor] nem por chamada
  /// anterior), grava a leitura atual como baseline e retorna delta 0.
  Future<MovementLocalDelta> pendingDeltaFor(String cycleId, int currentStepsSinceBoot) async {
    await ensureLoaded();
    final entry = _state[cycleId] as Map<String, dynamic>?;
    if (entry == null) {
      _state[cycleId] = {'baseline': currentStepsSinceBoot, 'lastSubmittedTotal': 0};
      await _persist();
      return MovementLocalDelta(uncollectedSteps: 0, totalStepsInCycle: 0);
    }
    final baseline = entry['baseline'] as int;
    final lastSubmittedTotal = entry['lastSubmittedTotal'] as int;
    final totalSoFar = currentStepsSinceBoot - baseline < 0 ? 0 : currentStepsSinceBoot - baseline;
    final uncollected = totalSoFar - lastSubmittedTotal < 0 ? 0 : totalSoFar - lastSubmittedTotal;
    return MovementLocalDelta(uncollectedSteps: uncollected, totalStepsInCycle: totalSoFar);
  }

  /// Chamado após uma coleta bem-sucedida no backend — registra que o
  /// total até `totalStepsInCycle` já foi enviado, para a próxima
  /// chamada calcular só o delta novo.
  Future<void> markCollected(String cycleId, int totalStepsInCycle) async {
    await ensureLoaded();
    final entry = _state[cycleId] as Map<String, dynamic>? ?? {'baseline': 0};
    entry['lastSubmittedTotal'] = totalStepsInCycle;
    _state[cycleId] = entry;
    await _persist();
  }

  /// Limpa o estado local (usado ao desativar a feature — o baseline de
  /// ciclos antigos não tem mais utilidade).
  Future<void> clear() async {
    await ensureLoaded();
    _state = {};
    await _persist();
  }
}
