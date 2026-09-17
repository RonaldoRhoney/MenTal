import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/notifications_screen.dart';

/// CENTRAL_DE_NOTIFICACOES_HOME_V1.md — prova que a tela só exibe o
/// que GET /notifications já devolve pronto (nenhum texto montado no
/// client), que tocar numa notificação não lida marca como lida, e que
/// "marcar todas como lidas" funciona.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.notifications = const []}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  List<Map<String, dynamic>> notifications;
  String? markedReadId;
  bool markAllReadCalled = false;

  @override
  Future<Map<String, dynamic>> getNotifications({String? before}) async {
    return {'notifications': notifications, 'unread_count': notifications.where((n) => n['read'] != true).length, 'next_cursor': null};
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    markedReadId = notificationId;
  }

  @override
  Future<void> markAllNotificationsRead() async {
    markAllReadCalled = true;
  }
}

Future<void> _pump(WidgetTester tester, ApiClient client) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: NotificationsScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista vazia mostra mensagem, sem botão de marcar todas como lidas', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    expect(find.text('Nenhuma notificação por aqui ainda.'), findsOneWidget);
    expect(find.text('Marcar todas como lidas'), findsNothing);
  });

  testWidgets('mostra título/corpo exatamente como o backend mandou, não lida em negrito', (tester) async {
    final client = _FakeApiClient(notifications: [
      {
        'id': 'n1',
        'type': 'torcida',
        'title': 'Você recebeu uma torcida! 🎉',
        'body': 'Fulano te mandou um 👍!',
        'data': null,
        'read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    ]);
    await _pump(tester, client);

    expect(find.text('Você recebeu uma torcida! 🎉'), findsOneWidget);
    expect(find.text('Fulano te mandou um 👍!'), findsOneWidget);
    expect(find.text('Marcar todas como lidas'), findsOneWidget);
  });

  testWidgets('tocar numa notificação não lida marca como lida no backend', (tester) async {
    final client = _FakeApiClient(notifications: [
      {
        'id': 'n1',
        'type': 'system',
        'title': 'Sentimos sua falta!',
        'body': 'Volte pra continuar sua sequência.',
        'data': null,
        'read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    ]);
    await _pump(tester, client);

    await tester.tap(find.text('Sentimos sua falta!'));
    await tester.pumpAndSettle();

    expect(client.markedReadId, 'n1');
  });

  testWidgets('botão "marcar todas como lidas" chama o endpoint certo', (tester) async {
    final client = _FakeApiClient(notifications: [
      {
        'id': 'n1',
        'type': 'system',
        'title': 'Título',
        'body': 'Corpo',
        'data': null,
        'read': false,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      },
    ]);
    await _pump(tester, client);

    await tester.tap(find.text('Marcar todas como lidas'));
    await tester.pumpAndSettle();

    expect(client.markAllReadCalled, isTrue);
    expect(find.text('Marcar todas como lidas'), findsNothing);
  });
}
