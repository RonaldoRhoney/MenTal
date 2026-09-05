import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/services/app_version_service.dart';

/// SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md §2 (05/09/2026) — aviso
/// gentil de nova versão disponível. A comparação de versão é feita
/// 100% no client (backend só devolve os dois números).
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.response) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final Map<String, dynamic>? response;

  @override
  Future<Map<String, dynamic>> getAppVersion() async {
    if (response == null) throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Sem conexão');
    return response!;
  }
}

void main() {
  group('AppVersionService.compare', () {
    test('versão menor é considerada menor', () {
      expect(AppVersionService.compare('0.2.9', '0.3.0'), lessThan(0));
    });

    test('versões iguais comparam igual', () {
      expect(AppVersionService.compare('0.3.0', '0.3.0'), 0);
    });

    test('versão maior é considerada maior', () {
      expect(AppVersionService.compare('1.0.0', '0.9.9'), greaterThan(0));
    });

    test('compara por componente, não como string (evita bug tipo "0.10.0" < "0.9.0")', () {
      expect(AppVersionService.compare('0.10.0', '0.9.0'), greaterThan(0));
    });
  });

  group('AppVersionService.check', () {
    test('instalada igual à mais recente → upToDate', () async {
      final client = _FakeApiClient({'latest_version': kInstalledAppVersion, 'min_required_version': kInstalledAppVersion});
      final result = await AppVersionService.check(client);
      expect(result.status, AppUpdateStatus.upToDate);
    });

    test('nova versão disponível, sem exigir atualização → updateAvailable', () async {
      final client = _FakeApiClient({'latest_version': '99.0.0', 'min_required_version': kInstalledAppVersion});
      final result = await AppVersionService.check(client);
      expect(result.status, AppUpdateStatus.updateAvailable);
      expect(result.latestVersion, '99.0.0');
    });

    test('versão instalada abaixo do mínimo exigido → updateRequired', () async {
      final client = _FakeApiClient({'latest_version': '99.0.0', 'min_required_version': '99.0.0'});
      final result = await AppVersionService.check(client);
      expect(result.status, AppUpdateStatus.updateRequired);
    });

    test('falha de rede nunca deve travar — trata como upToDate', () async {
      final client = _FakeApiClient(null);
      final result = await AppVersionService.check(client);
      expect(result.status, AppUpdateStatus.upToDate);
    });
  });
}
