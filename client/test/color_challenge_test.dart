import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mental/color_challenge.dart';

/// Efeito Stroop clássico no território "cores" (pedido de Rhoney,
/// 2026-09-03, 3 rodadas de ajuste testando no aparelho real):
/// enunciado fica neutro; as 4 caixas de resposta usam as cores REAIS
/// das próprias alternativas, embaralhadas entre si — nenhuma caixa
/// mostra a cor que ela mesma nomeia, e a cor pedida no enunciado
/// sempre aparece em alguma caixa ERRADA (confusão deliberada).
void main() {
  test('colorForWord reconhece todas as 12 cores curadas, case-insensitive', () {
    expect(colorForWord('Vermelha'), isNotNull);
    expect(colorForWord('VERMELHA'), colorForWord('vermelha'));
    expect(colorForWord('Turquesa'), isNotNull);
    expect(colorForWord('não-é-uma-cor'), isNull);
  });

  test('deriveOptionBoxColors nunca deixa uma caixa com a cor que ela mesma nomeia', () {
    // Achado real (03/09/2026, Rhoney: "as cores estão entregando a
    // resposta") — cada caixa precisa de uma cor DIFERENTE da que ela
    // nomeia, senão dá pra achar a resposta certa só pela cor, sem ler.
    const options = ['Vermelha', 'Azul', 'Verde', 'Amarela'];
    for (final prompt in ['Toque na cor Vermelha.', 'Toque na cor Azul.', 'Encontre rápido: a cor Verde.']) {
      final boxColors = deriveOptionBoxColors(prompt, options);
      expect(boxColors.length, options.length);
      for (var i = 0; i < options.length; i++) {
        expect(boxColors[i], isNot(equals(colorForWord(options[i]))), reason: 'prompt=$prompt opção=${options[i]}');
      }
    }
  });

  test('a cor pedida no enunciado sempre aparece em alguma caixa (a confusão pedida por Rhoney)', () {
    const options = ['Vermelha', 'Azul', 'Verde', 'Amarela'];
    final boxColors = deriveOptionBoxColors('Toque na cor Verde.', options);

    // "a cor da pergunta na resposta deve confundir o usuário" — a cor
    // Verde precisa estar presente em alguma caixa (necessariamente uma
    // caixa ERRADA, já que a própria caixa "Verde" nunca pode ser
    // colorida de verde, conforme o teste acima).
    expect(boxColors, contains(colorForWord('Verde')));
  });

  test('deriveOptionBoxColors é determinístico pro mesmo prompt (não pisca ao reconstruir)', () {
    const options = ['Vermelha', 'Azul', 'Verde', 'Amarela'];
    final first = deriveOptionBoxColors('Toque na cor Azul.', options);
    final second = deriveOptionBoxColors('Toque na cor Azul.', options);

    expect(first, second);
  });

  test('readableTextColorOn escolhe preto ou branco pelo contraste real', () {
    expect(readableTextColorOn(const Color(0xFFFFFFFF)), Colors.black87);
    expect(readableTextColorOn(const Color(0xFF000000)), Colors.white);
  });
}
