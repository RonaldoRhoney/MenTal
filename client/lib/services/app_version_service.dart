/// SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md §2 (05/09/2026) — aviso
/// gentil de nova versão disponível. O backend só devolve dois números
/// de versão (GET /app/version); a comparação com a versão instalada
/// é feita aqui, sempre no client (mesma decisão registrada no
/// documento: "cliente compara com sua própria versão instalada").
library;

import '../api/api_client.dart';

/// Mantido em sincronia manual com `version:` de pubspec.yaml (sem o
/// sufixo "+build", que é só o número de build interno, nunca exibido
/// nem comparado aqui) — atualizar junto de cada bump de versão.
const String kInstalledAppVersion = '0.3.0';

enum AppUpdateStatus { upToDate, updateAvailable, updateRequired }

class AppVersionCheckResult {
  const AppVersionCheckResult(this.status, {this.latestVersion});

  final AppUpdateStatus status;
  final String? latestVersion;
}

class AppVersionService {
  AppVersionService._();

  /// Compara duas versões no formato "major.minor.patch" (mesma
  /// convenção do `version:` de pubspec.yaml). Resiliente a formatos
  /// levemente diferentes (menos/mais componentes) — trata componente
  /// ausente como 0, nunca lança.
  static int compare(String a, String b) {
    final partsA = _parse(a);
    final partsB = _parse(b);
    for (var i = 0; i < 3; i++) {
      final diff = partsA[i].compareTo(partsB[i]);
      if (diff != 0) return diff;
    }
    return 0;
  }

  static List<int> _parse(String version) {
    final segments = version.split('.');
    return List.generate(3, (i) => i < segments.length ? int.tryParse(segments[i]) ?? 0 : 0);
  }

  /// Resiliente por design (mesmo princípio de PushService/
  /// FeedbackService): qualquer falha aqui (sem rede, backend fora do
  /// ar) nunca pode travar o carregamento da Home — só significa que o
  /// aviso de atualização não aparece desta vez.
  static Future<AppVersionCheckResult> check(ApiClient client) async {
    try {
      final data = await client.getAppVersion();
      final latest = data['latest_version'] as String;
      final minRequired = data['min_required_version'] as String;
      if (compare(kInstalledAppVersion, minRequired) < 0) {
        return AppVersionCheckResult(AppUpdateStatus.updateRequired, latestVersion: latest);
      }
      if (compare(kInstalledAppVersion, latest) < 0) {
        return AppVersionCheckResult(AppUpdateStatus.updateAvailable, latestVersion: latest);
      }
      return const AppVersionCheckResult(AppUpdateStatus.upToDate);
    } catch (_) {
      return const AppVersionCheckResult(AppUpdateStatus.upToDate);
    }
  }
}
