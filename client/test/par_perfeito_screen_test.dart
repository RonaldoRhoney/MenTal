import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/par_perfeito_screen.dart';

/// MUNDO_IDIOMAS_INGLES_PAR_PERFEITO_V1.md §3/§9 — formato "Pares de
/// cards". O toque na pronúncia (TtsService.speak) nunca é esperado no
/// teste (mesma cautela de word_constellation_screen_test.dart): em
/// sandbox sem rede ele falha rápido e silenciosamente, sem travar.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.roundResponse, this.completeResponse})
      : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final Map<String, dynamic>? roundResponse;
  Map<String, dynamic>? completeResponse;
  List<String>? lastCompletedItemIds;

  @override
  Future<Map<String, dynamic>> nextParPerfeitoRound(String territoryId) async {
    if (roundResponse == null) {
      throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Sem conexão');
    }
    return roundResponse!;
  }

  @override
  Future<Map<String, dynamic>> completeParPerfeitoRound({required String territoryId, required List<String> itemIds}) async {
    lastCompletedItemIds = itemIds;
    return completeResponse ?? {'xp_awarded_total': 0};
  }
}

final _twoPairsRound = {
  'territory_id': 'ingles_parperfeito_basico',
  'difficulty_level': 1,
  'items': [
    {'id': 'a1', 'word_en': 'Welcome', 'meaning_pt': 'Bem-vindo'},
    {'id': 'a2', 'word_en': 'Coffee', 'meaning_pt': 'Café'},
  ],
};

final _threePairsRound = {
  'territory_id': 'ingles_parperfeito_basico',
  'difficulty_level': 1,
  'items': [
    {'id': 'a1', 'word_en': 'Welcome', 'meaning_pt': 'Bem-vindo'},
    {'id': 'a2', 'word_en': 'Coffee', 'meaning_pt': 'Café'},
    {'id': 'a3', 'word_en': 'Tea', 'meaning_pt': 'Chá'},
  ],
};

Widget _app(ApiClient client) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ParPerfeitoScreen(client: client, territoryId: 'ingles_parperfeito_basico', territoryLabel: 'Par Perfeito'),
  );
}

void main() {
  testWidgets('carrega a rodada e mostra as duas colunas de cards', (tester) async {
    final client = _FakeApiClient(roundResponse: _twoPairsRound);
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(find.text('Café'), findsOneWidget);
  });

  testWidgets('formar o par certo marca os dois cards e, no fim, envia só os pares certos de primeira', (tester) async {
    final client = _FakeApiClient(roundResponse: _twoPairsRound, completeResponse: {'xp_awarded_total': 6});
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Welcome'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bem-vindo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Café'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    expect(client.lastCompletedItemIds, unorderedEquals(['a1', 'a2']));
    expect(find.text('+6 XP'), findsOneWidget);
  });

  testWidgets('errar um par não trava a rodada, e os dois lados envolvidos no erro não entram no crédito de XP', (tester) async {
    final client = _FakeApiClient(roundResponse: _threePairsRound, completeResponse: {'xp_awarded_total': 3});
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    // Welcome (a1) com o significado errado (Café, de a2) primeiro — as
    // DUAS pontas do erro (a1 e a2) ficam marcadas, mesmo que depois
    // sejam formadas corretamente (evita mapear os pares por tentativa-
    // e-erro e só então "acertar de verdade" pra ganhar XP).
    await tester.tap(find.text('Welcome'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Café'));
    await tester.pumpAndSettle();

    // Agora forma os três pares certos.
    await tester.tap(find.text('Welcome'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bem-vindo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Café'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chá'));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // a1 e a2 tiveram erro — só a3 (Tea/Chá, nunca tocado errado) vai pro crédito de XP.
    expect(client.lastCompletedItemIds, ['a3']);
  });

  testWidgets('falha de rede ao carregar a rodada mostra erro com botão de tentar de novo', (tester) async {
    final client = _FakeApiClient(roundResponse: null);
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
    expect(find.text('Sem conexão'), findsOneWidget);
    expect(find.text(l10n.tryAgainButton), findsOneWidget);
  });
}
