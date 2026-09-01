import 'dart:convert';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'movement_task_handler.dart';

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
  static const _kAcknowledgedPendingKey = 'movement_acknowledged_pending_cycles_v1';

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

  /// Abre a tela de permissões do app nas Configurações do Android —
  /// único jeito de recuperar a permissão quando o usuário já negou
  /// "não perguntar de novo" (achado real, 29/08/2026: reinstalar o app
  /// com Movimento já ativado na conta reseta a permissão do Android,
  /// mas a flag do servidor continua true — sem isso, o jogador ficava
  /// travado sem nenhuma ação possível na própria tela).
  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {}
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

  /// Igual a [pendingDeltaFor], mas para um ciclo JÁ FECHADO (o
  /// "pendente" pra coleta, fora do ciclo atual). Diferença crítica:
  /// NUNCA cria um baseline novo quando não existe um registrado
  /// localmente para esse `cycleId`. [pendingDeltaFor] faz isso porque é
  /// seguro para o ciclo atual (que acabou de nascer agora mesmo), mas
  /// para um ciclo antigo seria sempre errado — inventaria um baseline
  /// usando a leitura de HOJE, quando o baseline de verdade daquele
  /// ciclo é de um dia anterior. Achado real (30/08/2026,
  /// MENTAL_MOVIMENTO_REFORMULACAO.md §2): esse fallback é a causa raiz
  /// de "coletar não faz nada" no ciclo pendente — sempre calculava
  /// delta 0 e mascarava o problema.
  ///
  /// Sem baseline local prévio, este aparelho não tem como saber quanto
  /// daquele ciclo específico ainda falta enviar — retorna null para o
  /// chamador tratar como "nada a coletar a partir deste aparelho", em
  /// vez de inventar um delta.
  Future<MovementLocalDelta?> pendingDeltaForClosedCycle(String cycleId, int currentStepsSinceBoot) async {
    await ensureLoaded();
    final entry = _state[cycleId] as Map<String, dynamic>?;
    if (entry == null) return null;
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

  /// Marca um ciclo pendente como "já resolvido por este aparelho" —
  /// usado quando uma coleta do ciclo pendente não teve nenhum delta
  /// real pra enviar (ver [pendingDeltaForClosedCycle]), pra parar de
  /// convidar o usuário a tocar em "Coletar" indefinidamente sem efeito
  /// nenhum. Guardado numa lista simples de ids — a janela de graça do
  /// próprio ciclo (24h) já limita naturalmente o crescimento dessa
  /// lista, mas limpa entradas de ciclos que não estão mais entre os
  /// `keepCycleIds` (o atual + o pendente de verdade) a cada chamada
  /// pra nunca crescer sem limite.
  Future<void> acknowledgePendingCycle(String cycleId, {required Iterable<String> keepCycleIds}) async {
    final prefs = await SharedPreferences.getInstance();
    final acknowledged = (prefs.getStringList(_kAcknowledgedPendingKey) ?? <String>[]).toSet();
    acknowledged.add(cycleId);
    acknowledged.retainWhere(keepCycleIds.contains);
    await prefs.setStringList(_kAcknowledgedPendingKey, acknowledged.toList());
  }

  Future<bool> isPendingCycleAcknowledged(String cycleId) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kAcknowledgedPendingKey) ?? const <String>[]).contains(cycleId);
  }

  bool _foregroundTaskInitialized = false;

  void _ensureForegroundTaskInitialized() {
    if (_foregroundTaskInitialized) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'movement_tracking',
        channelName: 'Contagem de passos',
        channelDescription: 'Mantém a contagem de passos ativa com o app em segundo plano.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: true,
      ),
    );
    _foregroundTaskInitialized = true;
  }

  /// Notificação persistente é exigida pelo Android 13+ (POST_NOTIFICATIONS)
  /// pra manter o foreground service visível — sem ela o serviço até roda,
  /// mas o Android tende a matá-lo mais cedo por não conseguir mostrar a
  /// notificação obrigatória.
  Future<void> _ensureNotificationPermission() async {
    final status = await FlutterForegroundTask.checkNotificationPermission();
    if (status != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  /// Inicia o foreground service que mantém o sensor de passos vivo com
  /// o app em segundo plano/tela apagada (ver movement_task_handler.dart
  /// pro porquê disso ser necessário). Chamado ao ativar Movimento e
  /// sempre que a tela de Movimento carrega com a feature já ativa —
  /// idempotente, não faz nada se o serviço já estiver rodando.
  Future<bool> startForegroundTracking() async {
    try {
      _ensureForegroundTaskInitialized();
      await _ensureNotificationPermission();
      if (await FlutterForegroundTask.isRunningService) return true;
      final result = await FlutterForegroundTask.startService(
        serviceId: 3001,
        serviceTypes: const [ForegroundServiceTypes.health],
        notificationTitle: 'MENTAL — Movimento ativo',
        notificationText: 'Contando seus passos em segundo plano.',
        callback: startMovementTaskCallback,
      );
      return result is ServiceRequestSuccess;
    } catch (_) {
      // Mesmo princípio de hasPermission/requestPermission: falha aqui
      // nunca derruba o app, só deixa a contagem limitada ao app aberto
      // (comportamento anterior), nunca pior que isso.
      return false;
    }
  }

  /// Chamado ao desativar Movimento — sem isso o serviço (e a notificação)
  /// continuariam rodando indefinidamente mesmo com a feature desligada.
  Future<void> stopForegroundTracking() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
  }
}
