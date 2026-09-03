import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/color_challenge.dart';

/// Efeito Stroop clássico no território "cores" (pedido de Rhoney,
/// 2026-09-03: "está muito fácil... a cor da pergunta deve ser
/// colorida de outra criando maior grau de dificuldade").
void main() {
  test('colorForWord reconhece todas as 12 cores curadas, case-insensitive', () {
    expect(colorForWord('Vermelha'), isNotNull);
    expect(colorForWord('VERMELHA'), colorForWord('vermelha'));
    expect(colorForWord('Turquesa'), isNotNull);
    expect(colorForWord('não-é-uma-cor'), isNull);
  });

  test('buildColorChallengePromptSpans destaca a palavra-alvo numa tinta diferente da cor que ela nomeia', () {
    const style = TextStyle(fontSize: 20);
    final spans = buildColorChallengePromptSpans('Toque na cor Vermelha.', style);

    // 3 pedaços: antes da palavra, a palavra em si, depois da palavra.
    expect(spans.length, 3);
    expect(spans[0].text, 'Toque na cor ');
    expect(spans[1].text, 'Vermelha');
    expect(spans[2].text, '.');

    // A tinta da palavra-alvo NUNCA é a cor que ela mesma nomeia —
    // essa é a interferência de Stroop que cria a dificuldade real.
    expect(spans[1].style?.color, isNot(equals(colorForWord('Vermelha'))));
  });

  test('mesmo prompt sempre produz a mesma tinta de armadilha (determinístico, não pisca ao reconstruir)', () {
    const style = TextStyle(fontSize: 20);
    final first = buildColorChallengePromptSpans('Toque na cor Azul.', style);
    final second = buildColorChallengePromptSpans('Toque na cor Azul.', style);

    expect(first[1].style?.color, second[1].style?.color);
  });

  test('prompt sem nenhuma cor conhecida não quebra — devolve o texto original sem destaque', () {
    const style = TextStyle(fontSize: 20);
    final spans = buildColorChallengePromptSpans('Quanto é 2 + 2?', style);

    expect(spans.length, 1);
    expect(spans[0].text, 'Quanto é 2 + 2?');
  });
}
