import 'dart:async';
import '../models/step_reading.dart';

/// Consolida as leituras de passos vindas de múltiplas fontes (sensor do
/// celular + Health Connect) em um único total "oficial" do dia.
///
/// Regra de negócio definida: quando existir uma leitura de wearable válida
/// para o dia corrente, ela substitui totalmente a contagem do sensor do
/// celular (evita somar o mesmo passo duas vezes). Se nenhum wearable
/// estiver reportando dados, o sensor do celular é usado como fallback.
class StepReconciliationService {
  StepReading? _lastPhoneReading;
  StepReading? _lastWearableReading;

  final _reconciledStepsController = StreamController<int>.broadcast();

  /// Total de passos "oficial" já reconciliado, pronto para alimentar a
  /// notificação e a UI.
  Stream<int> get reconciledSteps => _reconciledStepsController.stream;

  int _lastEmittedTotal = 0;
  int get lastEmittedTotal => _lastEmittedTotal;

  /// Chamado pelo listener do sensor nativo do celular.
  void onPhoneReading(StepReading reading) {
    assert(reading.source == StepSource.phoneSensor);
    _lastPhoneReading = reading;
    _reconcileAndEmit();
  }

  /// Chamado pelo listener passivo do Health Connect quando chega um novo
  /// registro de um wearable/app externo.
  void onWearableReading(StepReading reading) {
    assert(reading.source == StepSource.wearable);
    _lastWearableReading = reading;
    _reconcileAndEmit();
  }

  void _reconcileAndEmit() {
    final wearable = _lastWearableReading;
    final phone = _lastPhoneReading;

    final bool wearableIsFresh = wearable != null &&
        _isSameDay(wearable.timestamp, DateTime.now()) &&
        DateTime.now().difference(wearable.timestamp) <
            const Duration(hours: 2);

    final int total;
    if (wearableIsFresh) {
      // Prioriza sempre o wearable quando disponível (decisão do produto).
      total = wearable.steps;
    } else if (phone != null) {
      total = phone.steps;
    } else {
      return; // Nenhuma leitura ainda.
    }

    _lastEmittedTotal = total;
    _reconciledStepsController.add(total);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Reset diário — chamar à meia-noite (ex: via WorkManager) para zerar
  /// as referências e recomeçar a contagem do dia seguinte.
  void resetForNewDay() {
    _lastPhoneReading = null;
    _lastWearableReading = null;
    _lastEmittedTotal = 0;
  }

  void dispose() {
    _reconciledStepsController.close();
  }
}
