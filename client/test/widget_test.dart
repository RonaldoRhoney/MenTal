import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/main.dart';

void main() {
  testWidgets('App inicializa e mostra o estado de carregamento explícito (mitigação de cold start)', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MentalApp());

    // Antes da sessão local resolver (SharedPreferences async), a tela
    // precisa mostrar feedback explícito — nunca branco/travado
    // (ARCHITECTURE.md §3, mitigação de cold start do Render).
    expect(find.text('Preparando seu desafio...'), findsOneWidget);
  });
}
