import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/stats_screen.dart';

/// V2 item 5 — Estatísticas. Prova que os números exibidos são os que o
/// backend calculou (GET /stats), incluindo a formatação de percentual e
/// fração — nenhum cálculo próprio no client.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> stats() async {
    return {
      'xp_total': 210,
      'level': 3,
      'total_attempts': 20,
      'total_correct': 15,
      'accuracy': 0.75,
      'total_hints_used': 4,
      'hint_free_correct': 12,
      'current_streak': 2,
      'longest_streak': 5,
      'badges_earned': 2,
      'badges_total': 5,
      'by_territory': [
        {
          'territory_id': 'numeros',
          'total_attempts': 10,
          'total_correct': 8,
          'accuracy': 0.8,
          'current_difficulty_level': 2,
          'xp_in_territory': 90,
          'conquered': false,
        },
        {
          'territory_id': 'visual',
          'total_attempts': 0,
          'total_correct': 0,
          'accuracy': 0.0,
          'current_difficulty_level': 1,
          'xp_in_territory': 0,
          'conquered': false,
        },
      ],
    };
  }
}

void main() {
  testWidgets('StatsScreen mostra números reais formatados (percentual e fração), inclusive território sem tentativa', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatsScreen(client: _FakeApiClient()),
      ),
    );
    await tester.pumpAndSettle();

    // "20" aparece na linha "Desafios respondidos" E no centro do donut
    // de composição das respostas — duas fontes legítimas do mesmo
    // número (total_attempts), não uma duplicata.
    expect(find.text('20'), findsAtLeastNWidgets(1));
    expect(find.text('75%'), findsAtLeastNWidgets(1)); // donut de acerto geral
    // Legenda do donut de composição: sem dica (12), com dica (15-12=3),
    // erros (20-15=5) — derivados de total_correct/hint_free_correct/
    // total_attempts, nenhum cálculo próprio além de subtração simples.
    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2 / 5 dias'), findsOneWidget); // streak atual/mais longa
    expect(find.text('2 / 5'), findsOneWidget); // badges

    // Os cards por território ficam abaixo do donut + gráfico de barras
    // — conteúdo mais alto agora que a tela tem gráficos, então fora do
    // viewport padrão de teste até rolar (a tela real rola normalmente;
    // isso é só o teste alcançando a parte de baixo, não um bug).
    await tester.scrollUntilVisible(
      find.textContaining('10 respondidos'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.textContaining('10 respondidos'), findsOneWidget);
    // "80%" aparece no mini-donut do território "numeros" E no card com
    // o número exato — mesma dupla fonte legítima do padrão já usado no
    // donut de acerto geral.
    expect(find.textContaining('80%'), findsAtLeastNWidgets(1));
    expect(find.textContaining('Nível de dificuldade atual: 2'), findsOneWidget);

    // Território sem nenhuma tentativa mostra o estado vazio, não "0%".
    await tester.scrollUntilVisible(
      find.text('Ainda sem desafios respondidos neste território.'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Ainda sem desafios respondidos neste território.'), findsOneWidget);
  });
}
