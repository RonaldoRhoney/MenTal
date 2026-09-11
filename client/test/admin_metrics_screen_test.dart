import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/screens/admin_metrics_screen.dart';
import 'package:mental/theme/app_theme.dart';

/// Achado real (07/09/2026, pedido de Rhoney: "nome e foto devem ser
/// visíveis"): o backend já tinha os endpoints de moderação de foto
/// (fail-closed) desde 28/08/2026, mas nenhuma tela do client os
/// usava — fotos ficavam presas em "pending" pra sempre. Este teste
/// cobre só a seção nova (moderação); as demais seções do painel ainda
/// não têm cobertura própria (achado pré-existente, fora do escopo
/// deste ajuste).
class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.pendingPhotos}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final List<Map<String, dynamic>> pendingPhotos;
  final List<Map<String, dynamic>> moderateCalls = [];
  ApiException? moderateError;

  @override
  Future<Map<String, dynamic>> getAdminMetricsSummary({String period = '7d'}) async {
    return {
      'active_users_today': 0,
      'active_users_week': 0,
      'engaged_users_in_period': 0,
      'new_signups_in_period': 0,
      'average_streak_active_users': 0,
      'top_progressors': <Map<String, dynamic>>[],
      'accuracy_by_territory': <Map<String, dynamic>>[],
      'feedback_distribution': {'facil': 0, 'medio': 0, 'dificil': 0, 'muito_dificil': 0},
      'movement': {
        'enabled_users': 0,
        'active_users_in_period': 0,
        'total_steps_in_period': 0,
        'average_steps_per_active_user': 0,
        'goal_distribution': <Map<String, dynamic>>[],
      },
      'demographics': {
        'gender': <Map<String, dynamic>>[],
        'age_range': <Map<String, dynamic>>[],
        'state': <Map<String, dynamic>>[],
        'city': <Map<String, dynamic>>[],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getAdminContentSuggestions() async {
    return {'items': <Map<String, dynamic>>[]};
  }

  @override
  Future<Map<String, dynamic>> getAdminPendingProfilePhotos() async {
    return {'items': pendingPhotos};
  }

  @override
  Future<Map<String, dynamic>> moderateProfilePhoto({required String userId, required bool approved}) async {
    moderateCalls.add({'user_id': userId, 'approved': approved});
    if (moderateError != null) throw moderateError!;
    return {'ok': true};
  }
}

// Achado real (mesmo já documentado em settings_screen_test.dart): a
// tela do painel admin é longa (várias seções empilhadas) e no
// viewport padrão de teste (800x600) o conteúdo mais abaixo — incluindo
// a nova seção de moderação de fotos — fica fora da extensão
// construída pelo ListView, então find.text/tap não o enxergam.
Future<void> _pump(WidgetTester tester, ApiClient client) async {
  tester.view.physicalSize = const Size(800, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.themeData,
      home: AdminMetricsScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista fotos pendentes de moderação', (tester) async {
    final client = _FakeApiClient(pendingPhotos: [
      {'user_id': 'user-1', 'nickname': 'joao123', 'photo_url': null},
    ]);
    await _pump(tester, client);

    expect(find.text('FOTOS DE PERFIL PENDENTES DE MODERAÇÃO'), findsOneWidget);
    expect(find.text('joao123'), findsOneWidget);
  });

  testWidgets('mostra nome real em vez do apelido quando disponível (NOME_REAL_E_FOTO_EM_TODO_LUGAR_V1.md)', (tester) async {
    final client = _FakeApiClient(pendingPhotos: [
      {'user_id': 'user-1', 'nickname': 'joao123', 'real_name': 'João Silva', 'photo_url': null},
    ]);
    await _pump(tester, client);

    expect(find.text('João Silva'), findsOneWidget);
    expect(find.text('joao123'), findsNothing);
  });

  testWidgets('sem fotos pendentes mostra estado vazio', (tester) async {
    final client = _FakeApiClient(pendingPhotos: []);
    await _pump(tester, client);

    expect(find.text('FOTOS DE PERFIL PENDENTES DE MODERAÇÃO'), findsOneWidget);
    // findsWidgets (não findsOneWidget): _EmptyRow é o mesmo widget
    // compartilhado por outras seções do painel (top_progressors,
    // accuracy_by_territory etc.) — todas vazias no fake acima, então
    // aparece mais de uma vez na árvore.
    expect(find.text('Sem dados no período.'), findsWidgets);
  });

  testWidgets('aprovar chama a API e remove a linha da lista', (tester) async {
    final client = _FakeApiClient(pendingPhotos: [
      {'user_id': 'user-1', 'nickname': 'joao123', 'photo_url': null},
    ]);
    await _pump(tester, client);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(client.moderateCalls, [
      {'user_id': 'user-1', 'approved': true},
    ]);
    expect(find.text('joao123'), findsNothing);
  });

  testWidgets('rejeitar chama a API e remove a linha da lista', (tester) async {
    final client = _FakeApiClient(pendingPhotos: [
      {'user_id': 'user-1', 'nickname': 'joao123', 'photo_url': null},
    ]);
    await _pump(tester, client);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(client.moderateCalls, [
      {'user_id': 'user-1', 'approved': false},
    ]);
    expect(find.text('joao123'), findsNothing);
  });

  testWidgets('erro ao moderar mostra SnackBar e mantém a linha na lista', (tester) async {
    final client = _FakeApiClient(pendingPhotos: [
      {'user_id': 'user-1', 'nickname': 'joao123', 'photo_url': null},
    ])..moderateError = ApiException(statusCode: 500, code: 'INTERNAL_ERROR', message: 'Erro ao moderar');
    await _pump(tester, client);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.check_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Erro ao moderar'), findsOneWidget);
    expect(find.text('joao123'), findsOneWidget);
  });
}
