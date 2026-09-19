import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/api/api_client.dart';
import 'package:mental/l10n/generated/app_localizations.dart';
import 'package:mental/screens/challenge_screen.dart';

/// MUNDO_IDIOMAS_AUDIO_E_LIBRAS_V1.md §3/§4 — prova que vocab_media_url
/// renderiza direto (imagem/GIF) ou como botão "Ver o sinal" (vídeo,
/// Libras), e que a ausência do campo (None, a maioria dos desafios
/// ainda sem curadoria) nunca quebra a tela.
class _VocabMediaFakeApiClient extends ApiClient {
  _VocabMediaFakeApiClient({required this.vocabMediaType}) : super(baseUrl: 'http://fake', accessToken: 'fake-token');

  final String? vocabMediaType;

  @override
  Future<Map<String, dynamic>> nextChallenge(String territoryId, {String mode = 'normal'}) async {
    return {
      'challenge_id': 'fake-id',
      'territory_id': territoryId,
      'difficulty_level': 1,
      'prompt': 'Pergunta de teste',
      'options': ['A', 'B', 'C', 'D'],
      'hints_available': 0,
      if (vocabMediaType != null) ...{
        'vocab_media_url': 'https://example.com/media.$vocabMediaType',
        'vocab_media_type': vocabMediaType,
        'vocab_media_source_name': 'Fonte de Teste',
        'vocab_media_source_url': 'https://example.com',
      },
    };
  }
}

Future<void> _pump(WidgetTester tester, String? vocabMediaType) async {
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
        client: _VocabMediaFakeApiClient(vocabMediaType: vocabMediaType),
        territoryId: 'libras',
        territoryLabel: 'Libras',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('vocab_media_type "video" mostra botão "Ver o sinal" + crédito da fonte', (tester) async {
    await _pump(tester, 'video');
    expect(find.widgetWithText(OutlinedButton, 'Ver o sinal'), findsOneWidget);
    expect(find.textContaining('Fonte de Teste'), findsOneWidget);
  });

  testWidgets('vocab_media_type "image" renderiza a imagem, sem o botão de vídeo', (tester) async {
    await _pump(tester, 'image');
    expect(find.widgetWithText(OutlinedButton, 'Ver o sinal'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('sem vocab_media_url (maioria dos desafios ainda não curados) a tela funciona normal', (tester) async {
    await _pump(tester, null);
    expect(find.text('Pergunta de teste'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Ver o sinal'), findsNothing);
  });
}
