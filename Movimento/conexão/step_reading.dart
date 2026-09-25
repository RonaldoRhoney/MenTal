/// Origem da leitura de passos.
enum StepSource {
  /// Sensor nativo do celular (TYPE_STEP_COUNTER).
  phoneSensor,

  /// Dado vindo do Health Connect, associado a um wearable/app externo
  /// (Fitbit, Samsung Health, Strava, Garmin, etc.).
  wearable,
}

/// Representa uma leitura de passos em um ponto no tempo, já com a origem
/// identificada para permitir a reconciliação (wearable > celular).
class StepReading {
  final int steps;
  final StepSource source;
  final DateTime timestamp;

  /// Nome do app/dispositivo de origem quando vier do Health Connect
  /// (ex: "Fitbit", "Samsung Health"). Nulo quando source == phoneSensor.
  final String? originAppName;

  const StepReading({
    required this.steps,
    required this.source,
    required this.timestamp,
    this.originAppName,
  });

  StepReading copyWith({
    int? steps,
    StepSource? source,
    DateTime? timestamp,
    String? originAppName,
  }) {
    return StepReading(
      steps: steps ?? this.steps,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      originAppName: originAppName ?? this.originAppName,
    );
  }

  @override
  String toString() =>
      'StepReading(steps: $steps, source: $source, origin: $originAppName, at: $timestamp)';
}
