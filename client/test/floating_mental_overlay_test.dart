import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/main.dart' show rootNavigatorKey;
import 'package:mental/services/floating_mental_controller.dart';
import 'package:mental/widgets/floating_mental_overlay.dart';

/// MENTAL_AGENTE_FLUTUANTE_V1.md, atualização de 08/10/2026 (My_Mental_AI
/// removido — "o agente flutuante assume seu lugar com todas suas
/// características"): o painel agora mostra os dados reais de GET /coach,
/// substituindo a antiga CoachScreen/coach_screen_test.dart (removida).
class _FakeApiClient extends ApiClient {
  _FakeApiClient(this.response) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final Map<String, dynamic>? response;

  @override
  Future<Map<String, dynamic>> getCoach() async {
    if (response == null) throw ApiException(statusCode: 0, code: 'NETWORK_ERROR', message: 'Sem conexão');
    return response!;
  }
}

Widget _app(ApiClient client) {
  FloatingMentalController.instance.currentClient = client;
  FloatingMentalController.instance.setHomeReached();
  return MaterialApp(
    // showModalBottomSheet usa rootNavigatorKey.currentContext (achado
    // real testando no aparelho, 08/10/2026: o painel sem isso pedia
    // showModalBottomSheet com um context que não está dentro da árvore
    // do Navigator, já que FloatingMentalOverlay é montado como IRMÃO
    // do Navigator no builder do MaterialApp, não descendente dele).
    navigatorKey: rootNavigatorKey,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const Stack(children: [SizedBox.expand(), FloatingMentalOverlay()]),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('toque no personagem abre o painel com resumo e cartões reais do /coach', (tester) async {
    final client = _FakeApiClient({
      'summary': {'total_answers': 42, 'accuracy': 0.75, 'weekly_xp': 120, 'weekly_rank': 3},
      'cards': [
        {
          'id': 'weakest',
          'title': 'Foque em {territory}',
          'body': 'Sua taxa de acerto em {territory} está mais baixa.',
          'territory_id': 'linguagem',
          'action': {'type': 'territory', 'territory_id': 'linguagem'},
        },
        {
          'id': 'streak',
          'title': 'Sequência',
          'body': 'Continue jogando todo dia.',
          'territory_id': null,
          'action': null,
        },
      ],
    });
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingMentalOverlay));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('coach_summary')), findsOneWidget);
    expect(find.byKey(const Key('coach_card_weakest')), findsOneWidget);
    expect(find.byKey(const Key('coach_action_weakest')), findsOneWidget);

    // Painel é um DraggableScrollableSheet — o 2º cartão pode começar fora
    // do viewport inicial.
    await tester.scrollUntilVisible(find.byKey(const Key('coach_card_streak')), 100);
    expect(find.byKey(const Key('coach_card_streak')), findsOneWidget);
    expect(find.byKey(const Key('coach_action_streak')), findsNothing);
  });

  testWidgets('falha de rede mostra aviso com botão de tentar de novo', (tester) async {
    final client = _FakeApiClient(null);
    await tester.pumpWidget(_app(client));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingMentalOverlay));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('pt'));
    expect(find.text(l10n.coachLoadError), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);
  });
}
