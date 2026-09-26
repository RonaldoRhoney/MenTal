import 'package:flutter_test/flutter_test.dart';

import 'package:mental/services/tts_service.dart';

/// MENTAL_IDIOMAS_ENTONACAO_TTS_URGENTE_V1.md (26/09/2026): "car" e "I will"
/// saíam secos e rápidos. Medição: '1.0' = fala padrão do serviço (~258 palavras/min).
void main() {
  test('Normal deixou de ser a fala padrão rápida do serviço', () {
    expect(TtsSpeed.normal.ssmlRate, '0.75');
    expect(TtsSpeed.fast.ssmlRate, '0.95');
    expect(TtsSpeed.veryFast.ssmlRate, '1.2');
    // ordem crescente: Normal < Rápido < Acelerado
    final rates = TtsSpeed.values.map((s) => double.parse(s.ssmlRate)).toList();
    expect(rates, [...rates]..sort());
  });

  test('palavra isolada e par de palavras são ditos duas vezes, com pausa', () {
    expect(prepareTextForTts('car'), 'car... car.');
    expect(prepareTextForTts('  house '), 'house... house.');
    expect(prepareTextForTts('I will'), 'I will... I will.');
  });

  test('frases ganham ponto final; o que já tem pontuação não muda', () {
    expect(prepareTextForTts('I will go to the market tomorrow'), 'I will go to the market tomorrow.');
    expect(prepareTextForTts('Where are you?'), 'Where are you?');
    expect(prepareTextForTts('Hello!'), 'Hello!');
    expect(prepareTextForTts(''), '');
  });

  test('palavra estrangeira dentro de uma frase do Mental Lingo não é repetida', () {
    expect(prepareTextForTts('House', repeatShortWords: false), 'House.');
    expect(prepareTextForTts('em inglês', repeatShortWords: false), 'em inglês.');
    expect(prepareTextForTts('House'), 'House... House.');
  });
}
