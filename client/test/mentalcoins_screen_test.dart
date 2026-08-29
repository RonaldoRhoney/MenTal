import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/mentalcoins_screen.dart';

/// MentalCoins (U.I/MENTALCOINS_V1.md) — saldo/Hall da Fama/catálogo são
/// 100% autoridade do backend; esta tela só exibe o que a API devolve.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.balance = 0}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  int balance;
  List<Map<String, dynamic>> hallOfFame = [];
  List<Map<String, dynamic>> catalog = [
    {'id': 'moldura_dourada', 'name': 'Moldura Dourada', 'description': 'Moldura de destaque.', 'cost': 80, 'item_type': 'avatar_frame', 'redeemed': false},
  ];
  String? redeemedItemId;
  ApiException? redeemError;

  @override
  Future<Map<String, dynamic>> getMentalCoinsBalance() async => {
        'balance': balance,
        'cycle_start': '2026-08-24',
        'cycle_end': '2026-08-30',
      };

  @override
  Future<Map<String, dynamic>> getMentalCoinsHallOfFame() async => {'entries': hallOfFame};

  @override
  Future<Map<String, dynamic>> getMentalCoinsCatalog() async => {'items': catalog};

  @override
  Future<Map<String, dynamic>> redeemMentalCoinsItem(String itemId) async {
    if (redeemError != null) throw redeemError!;
    redeemedItemId = itemId;
    return {'balance': balance, 'cycle_start': '2026-08-24', 'cycle_end': '2026-08-30'};
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
      home: MentalCoinsScreen(client: client),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra saldo e catálogo carregados do backend', (tester) async {
    final client = _FakeApiClient(balance: 200);
    await _pump(tester, client);

    expect(find.text('200'), findsOneWidget);
    expect(find.text('Moldura Dourada'), findsOneWidget);
  });

  testWidgets('Hall da Fama vazio mostra mensagem de estado vazio', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    expect(find.textContaining('Nenhuma semana fechada'), findsOneWidget);
  });

  testWidgets('Hall da Fama com vencedores mostra nickname e valor', (tester) async {
    final client = _FakeApiClient()
      ..hallOfFame = [
        {'category': 'xp_daily', 'rank': 1, 'reference_date': '2026-08-24', 'user_id': 'u1', 'nickname': 'Maria', 'amount': 10, 'metric_value': 500},
      ];
    await _pump(tester, client);

    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('+10'), findsOneWidget);
  });

  testWidgets('resgatar item com saldo suficiente debita e marca como resgatado', (tester) async {
    final client = _FakeApiClient(balance: 200);
    await _pump(tester, client);

    await tester.tap(find.widgetWithText(FilledButton, 'Resgatar'));
    await tester.pumpAndSettle();

    expect(client.redeemedItemId, 'moldura_dourada');
    expect(find.text('Resgatado'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Resgatar'), findsNothing);
  });

  testWidgets('botão de resgate fica desabilitado quando saldo é insuficiente', (tester) async {
    final client = _FakeApiClient(balance: 10);
    await _pump(tester, client);

    final button = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Resgatar'));
    expect(button.onPressed, isNull);
  });

  testWidgets('item já resgatado mostra label "Resgatado" sem botão', (tester) async {
    final client = _FakeApiClient(balance: 200)
      ..catalog = [
        {'id': 'moldura_dourada', 'name': 'Moldura Dourada', 'description': 'Moldura de destaque.', 'cost': 80, 'item_type': 'avatar_frame', 'redeemed': true},
      ];
    await _pump(tester, client);

    expect(find.text('Resgatado'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Resgatar'), findsNothing);
  });
}
