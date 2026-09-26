import 'package:health/health.dart';

import '../brasilia_time.dart';

/// Estado da leitura de passos do Health Connect.
enum HealthStepsStatus {
  /// Health Connect ausente ou desatualizado no aparelho (ou plataforma sem suporte).
  unavailable,

  /// Disponível, mas o usuário ainda não concedeu a permissão de leitura.
  notPermitted,

  /// Disponível e com permissão.
  connected,
}

/// Fonte de passos do Health Connect (Movimento/HealthConnect/DESENHO_TECNICO_V1.md,
/// aprovado por Rhoney em 25/09/2026). Interface pra o cartão da tela Movimento
/// poder ser testado sem plugin nativo.
///
/// Regras aprovadas: só LEITURA agregada (o Health Connect já deduplica fontes:
/// relógio, Fit, Samsung Health...), só registros AUTOMÁTICOS (nunca entrada
/// manual) e nada daqui vale XP/MentalCoins nem é enviado ao servidor.
abstract class HealthStepsSource {
  Future<HealthStepsStatus> status();

  /// Pede a permissão de leitura de passos (dialog do Health Connect). Só deve
  /// ser chamado por ação explícita do usuário (botão "Conectar").
  Future<bool> requestPermission();

  /// Total do dia de Brasília até agora, ou null se indisponível/sem dado/erro.
  Future<int?> todaySteps();
}

class HealthConnectStepsSource implements HealthStepsSource {
  HealthConnectStepsSource({Health? health}) : _health = health ?? Health();

  final Health _health;
  bool _configured = false;

  static const _types = [HealthDataType.STEPS];
  static const _access = [HealthDataAccess.READ];

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  @override
  Future<HealthStepsStatus> status() async {
    try {
      final sdk = await _health.getHealthConnectSdkStatus();
      if (sdk != HealthConnectSdkStatus.sdkAvailable) {
        return HealthStepsStatus.unavailable;
      }
      await _ensureConfigured();
      final ok = await _health.hasPermissions(_types, permissions: _access);
      return ok == true
          ? HealthStepsStatus.connected
          : HealthStepsStatus.notPermitted;
    } catch (_) {
      return HealthStepsStatus.unavailable;
    }
  }

  @override
  Future<bool> requestPermission() async {
    try {
      await _ensureConfigured();
      return await _health.requestAuthorization(_types, permissions: _access);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<int?> todaySteps() async {
    try {
      await _ensureConfigured();
      final start = brasiliaDayStartUtc(DateTime.now().toUtc());
      // includeManualEntry: false — passo digitado à mão (por qualquer app)
      // não entra; é a base da regra anti-fraude aprovada.
      return await _health.getTotalStepsInInterval(
        start,
        DateTime.now(),
        includeManualEntry: false,
      );
    } catch (_) {
      return null;
    }
  }
}
