import 'package:health/health.dart';
import '../models/step_reading.dart';

/// Integração com Health Connect via pacote `health`.
///
/// Modo: leitura E escrita (o MENTAL também é fonte de dados para outros
/// apps que leem do Health Connect).
class HealthConnectService {
  final Health _health = Health();

  static const _dataTypes = [HealthDataType.STEPS];
  static const _permissions = [HealthDataAccess.READ_WRITE];

  Future<bool> requestPermissions() async {
    await _health.configure();
    final granted = await _health.requestAuthorization(
      _dataTypes,
      permissions: _permissions,
    );
    return granted;
  }

  Future<bool> isHealthConnectAvailable() async {
    // No Android, checa se o Health Connect está instalado no aparelho.
    final status = await _health.getHealthConnectSdkStatus();
    return status == HealthConnectSdkStatus.sdkAvailable;
  }

  /// Busca os registros de passos mais recentes de todas as fontes
  /// conectadas ao Health Connect (Fitbit, Samsung Health, Strava, etc.),
  /// excluindo o próprio MENTAL para não reprocessar o que ele mesmo
  /// escreveu.
  Future<List<StepReading>> fetchExternalStepReadings({
    required DateTime since,
  }) async {
    final now = DateTime.now();
    final data = await _health.getHealthDataFromTypes(
      types: _dataTypes,
      startTime: since,
      endTime: now,
    );

    return data
        .where((point) => point.sourceName != _mentalSourceName)
        .map(
          (point) => StepReading(
            steps: (point.value as NumericHealthValue).numericValue.toInt(),
            source: StepSource.wearable,
            timestamp: point.dateTo,
            originAppName: point.sourceName,
          ),
        )
        .toList();
  }

  /// Escreve os passos contados pelo sensor do próprio celular no Health
  /// Connect, para que o MENTAL também sirva como fonte para outros apps.
  Future<bool> writeSteps({
    required int steps,
    required DateTime start,
    required DateTime end,
  }) async {
    return _health.writeHealthData(
      value: steps.toDouble(),
      type: HealthDataType.STEPS,
      startTime: start,
      endTime: end,
    );
  }

  static const String _mentalSourceName = 'MENTAL';
}
