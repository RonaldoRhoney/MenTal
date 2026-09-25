import 'dart:async';

/// Controla o gatilho de atualização da notificação persistente.
///
/// Regra fixa do produto: a notificação só é atualizada quando o total
/// acumulado de passos avança pelo menos 1500 desde a última atualização
/// exibida — independentemente de a fonte ser o celular ou um wearable.
class StepNotificationService {
  static const int stepsThreshold = 1500;

  int _lastNotifiedTotal = 0;

  /// Recebe o total já reconciliado (StepReconciliationService) e decide
  /// se deve disparar uma atualização de notificação.
  ///
  /// Retorna true se a notificação foi (ou deveria ser) atualizada.
  bool onReconciledStepsUpdate(int currentTotal) {
    if (currentTotal - _lastNotifiedTotal >= stepsThreshold) {
      _lastNotifiedTotal = currentTotal;
      _updateOngoingNotification(currentTotal);
      return true;
    }
    return false;
  }

  void _updateOngoingNotification(int totalSteps) {
    // Integração real com flutter_foreground_task ou plugin nativo de
    // notificação entra aqui. Mantido como stub para não acoplar a este
    // arquivo uma dependência de plugin ainda não instalada no projeto.
    //
    // Exemplo de uso (flutter_foreground_task):
    // FlutterForegroundTask.updateService(
    //   notificationTitle: 'MENTAL — Movimento ativo',
    //   notificationText: '$totalSteps passos hoje',
    // );
  }

  void resetForNewDay() {
    _lastNotifiedTotal = 0;
  }
}
