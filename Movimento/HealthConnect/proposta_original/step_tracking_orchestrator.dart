import 'dart:async';
import 'package:pedometer/pedometer.dart';
import '../models/step_reading.dart';
import 'health_connect_service.dart';
import 'step_reconciliation_service.dart';
import 'step_notification_service.dart';

/// Ponto único de entrada do módulo de passos. Liga:
/// 1) o sensor nativo do celular (tempo real)
/// 2) o listener/polling do Health Connect (wearables e outros apps)
/// 3) a reconciliação (wearable > celular)
/// 4) o gatilho de notificação a cada 1500 passos
class StepTrackingOrchestrator {
  final HealthConnectService _healthConnect;
  final StepReconciliationService _reconciliation;
  final StepNotificationService _notification;

  StreamSubscription<StepCount>? _phoneSensorSub;
  Timer? _healthConnectSafetyNetTimer;
  DateTime _dayStart = _startOfToday();

  StepTrackingOrchestrator({
    HealthConnectService? healthConnect,
    StepReconciliationService? reconciliation,
    StepNotificationService? notification,
  })  : _healthConnect = healthConnect ?? HealthConnectService(),
        _reconciliation = reconciliation ?? StepReconciliationService(),
        _notification = notification ?? StepNotificationService();

  /// Expõe o total reconciliado para a UI (tela de Movimento) consumir.
  Stream<int> get reconciledSteps => _reconciliation.reconciledSteps;

  Future<void> start() async {
    await _healthConnect.requestPermissions();

    // 1) Sensor nativo — tempo real.
    _phoneSensorSub = Pedometer.stepCountStream.listen(
      _onPhoneSensorEvent,
      onError: (_) {
        // Sensor indisponível no aparelho: seguimos só com Health Connect.
      },
    );

    // 2) Health Connect — sync de segurança a cada 15 min.
    // (O listener passivo/Change Notifications real deve ser registrado
    // nativamente; aqui o timer cobre o fallback pedido no plano.)
    _healthConnectSafetyNetTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _syncHealthConnect(),
    );

    // Primeira sincronização imediata ao iniciar.
    await _syncHealthConnect();
  }

  void _onPhoneSensorEvent(StepCount event) {
    final reading = StepReading(
      steps: event.steps,
      source: StepSource.phoneSensor,
      timestamp: event.timeStamp,
    );
    _reconciliation.onPhoneReading(reading);
    _checkNotification();

    // Também escreve no Health Connect (modo leitura E escrita).
    _healthConnect.writeSteps(
      steps: event.steps,
      start: _dayStart,
      end: DateTime.now(),
    );
  }

  Future<void> _syncHealthConnect() async {
    final readings = await _healthConnect.fetchExternalStepReadings(
      since: _dayStart,
    );
    if (readings.isEmpty) return;

    // Usa a leitura mais recente entre as fontes externas.
    readings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _reconciliation.onWearableReading(readings.first);
    _checkNotification();
  }

  void _checkNotification() {
    _notification.onReconciledStepsUpdate(_reconciliation.lastEmittedTotal);
  }

  /// Chamar à meia-noite (ex: agendado via WorkManager) para zerar o dia.
  void resetForNewDay() {
    _dayStart = _startOfToday();
    _reconciliation.resetForNewDay();
    _notification.resetForNewDay();
  }

  static DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> stop() async {
    await _phoneSensorSub?.cancel();
    _healthConnectSafetyNetTimer?.cancel();
    _reconciliation.dispose();
  }
}
