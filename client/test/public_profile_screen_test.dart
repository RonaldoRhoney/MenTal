import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/public_profile_screen.dart';

/// V4 item 1 — Perfil Público + Torcida (PERFIL_PUBLICO_E_TORCIDA_V1.md,
/// TORCIDA_MULTIPLA_V2.md). Prova que a tela só exibe o que o backend
/// devolve (nenhum cálculo próprio) e que enviar torcida atualiza o
/// contador local sem precisar de um segundo carregamento.
class _FakeApiClient extends ApiClient {
  _FakeApiClient({this.torcidaError}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final ApiException? torcidaError;
  int sentCount = 0;
  int movementInviteSentCount = 0;
  String? lastReactionType;

  @override
  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    return {
      'user_id': userId,
      'nickname': 'jogador-1234',
      'real_name': 'Maria Teste',
      'photo_url': null,
      'level': 7,
      'xp_total': 650,
      'xp_per_level': 100,
      'current_streak': 4,
      'badges': [
        {'code': 'first_conquest', 'name': 'Primeira Conquista', 'description': 'Conquistou um território', 'earned_at': '2026-08-01T00:00:00'},
      ],
      'worlds': [
        {'world_id': 'linguagem', 'name': 'Mundo da Linguagem', 'territory_ids': ['palavras', 'textos', 'enigmas'], 'completed': true},
        {'world_id': 'mente_logica', 'name': 'Mundo da Mente Lógica', 'territory_ids': ['numeros', 'logica'], 'completed': false},
      ],
      'best_territory_id': 'palavras',
      'best_territory_xp': 300,
      'torcida_sent_today_by_me': sentCount,
      'movement_invite_sent_today_by_me': movementInviteSentCount,
    };
  }

  @override
  Future<Map<String, dynamic>> sendTorcida(String userId, String reactionType) async {
    lastReactionType = reactionType;
    if (torcidaError != null) throw torcidaError!;
    sentCount += 1;
    return {'ok': true, 'sent_today_by_me': sentCount};
  }

  @override
  Future<Map<String, dynamic>> sendMovementInvite(String userId) async {
    movementInviteSentCount += 1;
    return {'ok': true, 'sent_today_by_me': movementInviteSentCount};
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
      home: PublicProfileScreen(client: client, userId: 'target-user-id'),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('mostra nome real, nível, XP, streak, badges conquistadas e melhor território', (tester) async {
    await _pump(tester, _FakeApiClient());

    expect(find.text('Maria Teste'), findsOneWidget);
    expect(find.text('Nível 7'), findsOneWidget);
    expect(find.text('650 XP'), findsOneWidget);
    expect(find.text('4 dias de sequência'), findsOneWidget);
    expect(find.text('Primeira Conquista'), findsOneWidget);
    expect(find.text('palavras'), findsOneWidget);
    expect(find.text('Mundo da Linguagem'), findsOneWidget);
  });

  testWidgets('tocar num ícone de torcida chama a API e atualiza o contador local sem novo GET', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    // Seção de Torcida fica abaixo do viewport padrão de teste com este
    // fixture (badges + mundos) — ListView virtualiza mesmo com filhos
    // explícitos (não só .builder), então precisa rolar até ela existir
    // na árvore antes de checar/tocar (mesmo padrão de stats_screen_test.dart).
    await tester.scrollUntilVisible(find.text('⚡'), 300, scrollable: find.byType(Scrollable));
    expect(find.text('Você já torceu 0x hoje'), findsOneWidget);

    await tester.tap(find.text('💚'));
    await tester.pumpAndSettle();

    expect(client.lastReactionType, 'coracao');
    expect(find.text('Você já torceu 1x hoje'), findsOneWidget);
    expect(find.text('Torcida enviada!'), findsOneWidget);
  });

  testWidgets('limite diário atingido mostra mensagem específica, não o erro cru do backend', (tester) async {
    final client = _FakeApiClient(
      torcidaError: ApiException(statusCode: 429, code: 'TORCIDA_DAILY_LIMIT_REACHED', message: 'Limite diário de torcida pra esta pessoa atingido.'),
    );
    await _pump(tester, client);

    await tester.scrollUntilVisible(find.text('⚡'), 300, scrollable: find.byType(Scrollable));
    await tester.tap(find.text('👍'));
    await tester.pumpAndSettle();

    expect(find.text('Você já atingiu o limite de torcida hoje pra esta pessoa'), findsOneWidget);
  });

  testWidgets('botão GO convida pro Movimento e depois fica desabilitado', (tester) async {
    final client = _FakeApiClient();
    await _pump(tester, client);

    await tester.scrollUntilVisible(find.text('GO'), 300, scrollable: find.byType(Scrollable));
    await tester.tap(find.text('GO'));
    await tester.pumpAndSettle();

    expect(client.movementInviteSentCount, 1);
    expect(find.text('Convite enviado!'), findsOneWidget);
    expect(find.text('Convite já enviado hoje'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.ancestor(of: find.text('GO'), matching: find.byType(FilledButton)));
    expect(button.onPressed, isNull);
  });
}
