import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/challenge_screen.dart';

/// Regressão para BUGS_TEST_REPORT_01.md — Bug 1.
///
/// Causa raiz confirmada: o TextField do desafio sem múltipla escolha
/// atualizava `_selectedOption` sem `setState()`, então o botão
/// "Confirmar resposta" (que depende de `_selectedOption != null`)
/// continuava desabilitado na renderização até algum OUTRO evento (ex.:
/// pedir dica) forçar um rebuild. Este teste prova que digitar sozinho,
/// sem nenhuma outra interação, já habilita o botão.
class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId) async {
    return {
      'challenge_id': 'fake-challenge-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': "Reordene as letras 'SALCA' para formar uma palavra.",
      'options': null,
      'hints_available': 2,
    };
  }
}

/// Simula um desafio do território "textos" (V2 item 3) — parágrafo-base
/// bem mais longo que qualquer enunciado dos territórios anteriores, com
/// múltipla escolha, para provar que a tela não estoura (RenderFlex
/// overflow) num viewport pequeno.
class _LongPromptFakeApiClient extends ApiClient {
  _LongPromptFakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId) async {
    return {
      'challenge_id': 'fake-challenge-id-textos',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': List.filled(20, 'Um parágrafo bem longo para testar o scroll da tela de desafio.').join(' '),
      'options': ['Opção A', 'Opção B', 'Opção C', 'Opção D'],
      'hints_available': 2,
    };
  }
}

/// Simula um desafio do território "visual" (V2 item 4) — opções em
/// formato "forma_preenchimento_cor_índice", sem nenhuma imagem real.
class _VisualFakeApiClient extends ApiClient {
  _VisualFakeApiClient() : super(baseUrl: 'http://fake', userId: 'fake-user');

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId) async {
    return {
      'challenge_id': 'fake-challenge-id-visual',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Qual figura é diferente das outras?',
      'options': ['circle_filled_gold_1', 'circle_filled_gold_2', 'square_filled_gold_3', 'circle_filled_gold_4'],
      'hints_available': 2,
    };
  }

  @override
  Future<Map<String, dynamic>> submitAnswer(String challengeId, String attemptId, String submittedAnswer) async {
    return {
      'is_correct': true,
      'correct_answer': 'square_filled_gold_3',
      'explanation': 'As outras três são círculos dourados preenchidos.',
      'xp_awarded': 10,
      'xp_base': 10,
      'hints_used': 0,
    };
  }
}

void main() {
  testWidgets(
    'botão "Confirmar resposta" habilita ao digitar, sem precisar de outra interação (regressão Bug 1)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _FakeApiClient(),
            territoryId: 'palavras',
            territoryLabel: 'Palavras',
          ),
        ),
      );
      await tester.pumpAndSettle();

      FilledButton confirmButton() =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar resposta'));

      expect(confirmButton().onPressed, isNull, reason: 'antes de digitar, deve estar desabilitado');

      await tester.enterText(find.byType(TextField), 'CASAL');
      await tester.pump();

      expect(
        confirmButton().onPressed,
        isNotNull,
        reason: 'ao digitar, o botão deve habilitar imediatamente — sem precisar de outra ação (ex.: pedir dica)',
      );
    },
  );

  testWidgets(
    'parágrafo-base longo (território "textos") não estoura a tela (regressão overflow)',
    (tester) async {
      // Viewport pequeno de propósito — telas de aparelho de entrada
      // (ex.: Moto G22) têm menos altura útil que o padrão de teste.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) => errors.add(details);
      addTearDown(() => FlutterError.onError = originalOnError);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _LongPromptFakeApiClient(),
            territoryId: 'textos',
            territoryLabel: 'Textos',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        errors.where((e) => e.exception.toString().contains('RenderFlex overflowed')),
        isEmpty,
        reason: 'parágrafo-base longo não pode causar overflow — a área de conteúdo precisa ser rolável',
      );
    },
  );

  testWidgets(
    'território "visual" renderiza ícones selecionáveis, não texto (V2 item 4)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _VisualFakeApiClient(),
            territoryId: 'visual',
            territoryLabel: 'Visual',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 4 opções visuais, cada uma com o ícone correto — a string bruta
      // da opção (ex.: "circle_filled_gold_1") nunca deve aparecer como
      // texto na tela, só o ícone decodificado.
      expect(find.byIcon(Icons.circle), findsNWidgets(3));
      expect(find.byIcon(Icons.square), findsOneWidget);
      expect(find.text('circle_filled_gold_1'), findsNothing);

      FilledButton confirmButton() =>
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Confirmar resposta'));
      expect(confirmButton().onPressed, isNull, reason: 'antes de tocar numa figura, deve estar desabilitado');

      await tester.tap(find.byIcon(Icons.square));
      await tester.pump();

      expect(confirmButton().onPressed, isNotNull, reason: 'ao tocar numa figura, o botão deve habilitar');
    },
  );

  testWidgets(
    'resultado do território "visual" mostra descrição legível, não o id bruto da opção (regressão)',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChallengeScreen(
            client: _VisualFakeApiClient(),
            territoryId: 'visual',
            territoryLabel: 'Visual',
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.square));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Confirmar resposta'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('square_filled_gold_3'),
        findsNothing,
        reason: 'o id interno da opção nunca deve aparecer cru na tela de resultado',
      );
      expect(find.textContaining('quadrado dourado'), findsOneWidget);
    },
  );
}
