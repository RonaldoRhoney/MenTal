import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/word_search_screen.dart';

/// CACA_PALAVRAS_BUG_E_VISUAL_V1.md §2 (18/09/2026) — prova que uma
/// palavra encontrada ganha cor própria (não mais um verde/cinza
/// uniforme) e continua tendo um indicador NÃO dependente de cor
/// (risco + ícone de check), pra acessibilidade.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  @override
  Future<Map<String, dynamic>> nextWordPuzzle(String territoryId) async => {
        'result_id': 'result-1',
        // 2 palavras de propósito — encontrar só "CAT" não completa o
        // puzzle, então o teste não dispara _submit()/CelebrationOverlay
        // (cuja animação de confete nunca "assenta" e travaria
        // pumpAndSettle).
        'grid': ['CATZ', 'XXXX', 'DOGX', 'XXXX'],
        'grid_size': 4,
        'words': ['CAT', 'DOG'],
        'theme': 'Animais',
      };

  @override
  Future<Map<String, dynamic>> completeWordPuzzle({required String resultId, required List<String> foundWords}) async => {
        'xp_awarded': 10,
        'speed_bonus_xp': 0,
      };
}

Future<void> _pump(WidgetTester tester) async {
  // Viewport de telefone (o padrão do harness de teste é mais "paisagem"
  // que qualquer aparelho real e não comporta a grade + lista de
  // palavras sem overflow, mesmo numa sessão de 3 palavras).
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: WordSearchScreen(client: _FakeApiClient(), territoryId: 'caca_palavras', territoryLabel: 'Caça-palavras'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('palavra ainda não encontrada não mostra risco nem ícone de check', (tester) async {
    await _pump(tester);

    final chipText = tester.widget<Text>(find.text('CAT'));
    expect(chipText.style?.decoration, isNot(TextDecoration.lineThrough));
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
  });

  testWidgets('arrastar sobre a palavra na grade marca risco + ícone de check (indicador não depende só de cor)', (tester) async {
    await _pump(tester);

    // Grade 4x4 dentro de um AspectRatio(1) — acha o retângulo real
    // renderizado e calcula o centro das células (0,0) e (0,2), que
    // formam a palavra "CAT" na primeira linha.
    final gridFinder = find.byType(GestureDetector).first;
    final gridBox = tester.getRect(gridFinder);
    final cellSize = gridBox.width / 4;
    final start = gridBox.topLeft + Offset(cellSize / 2, cellSize / 2);
    final end = gridBox.topLeft + Offset(cellSize * 2 + cellSize / 2, cellSize / 2);

    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(end);
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();

    final chipText = tester.widget<Text>(find.text('CAT'));
    expect(chipText.style?.decoration, TextDecoration.lineThrough);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });
}
