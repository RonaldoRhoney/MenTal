import 'dart:math';

import 'package:flutter/material.dart';

/// V3.0.1_DESAFIO_CORES.md descrevia uma versão "Stroop simplificada"
/// (texto neutro, sem interferência de cor). Pedido de Rhoney
/// (2026-09-03, testando o Relâmpago real) evoluiu em 3 rodadas até
/// este desenho final:
/// 1ª tentativa (texto de cada alternativa na cor que ela mesma nomeia)
///    — rejeitada: "as cores estão entregando a resposta" (dava pra
///    achar só procurando "o botão da cor certa", sem ler).
/// 2ª tentativa (cor do ENUNCIADO destacada numa tinta diferente) —
///    rejeitada: "a cor da pergunta não precisa ser colorida".
/// Desenho final: o ENUNCIADO fica neutro (sem destaque). As 4 CAIXAS
/// de resposta (fundo, não só o texto) recebem as cores REAIS das 4
/// alternativas desta pergunta, mas EMBARALHADAS entre si — nenhuma
/// caixa fica com a cor que ela mesma nomeia (não entrega a resposta),
/// e a cor pedida no enunciado aparece garantidamente em alguma caixa
/// ERRADA ("a cor da pergunta na resposta deve confundir o usuário").
/// O jogador só acerta lendo o texto de cada caixa, nunca reconhecendo
/// a cor de relance.
const Map<String, Color> kColorChallengePalette = {
  'vermelha': Color(0xFFE53935),
  'azul': Color(0xFF2979FF),
  'verde': Color(0xFF43A047),
  'amarela': Color(0xFFFDD835),
  'roxa': Color(0xFF8E24AA),
  'laranja': Color(0xFFFB8C00),
  'rosa': Color(0xFFEC407A),
  // "Preta" em preto puro seria ilegível no fundo escuro do app — usa
  // um cinza-chumbo com contraste real, ainda lido como "escuro/preto".
  'preta': Color(0xFF5C5C5C),
  'branca': Color(0xFFFFFFFF),
  'cinza': Color(0xFF9E9E9E),
  'marrom': Color(0xFF6D4C41),
  'turquesa': Color(0xFF1DE9B6),
};

/// Normaliza pra bater contra o mapa acima independente de acentuação
/// (o conteúdo curado não usa acento nesses nomes, mas protege contra
/// mudança futura de curadoria).
String _normalize(String word) => word.trim().toLowerCase();

Color? colorForWord(String word) => kColorChallengePalette[_normalize(word)];

/// Cor de texto legível sobre um fundo qualquer da paleta acima —
/// preto ou branco, o que tiver mais contraste (ex.: fundo "Amarela"
/// pede texto escuro; fundo "Roxa" pede texto claro).
Color readableTextColorOn(Color background) {
  return ThemeData.estimateBrightnessForColor(background) == Brightness.dark ? Colors.white : Colors.black87;
}

/// Deriva a cor de FUNDO de cada caixa de alternativa, embaralhando as
/// cores reais das próprias `options` desta pergunta entre si — nunca
/// a cor que a caixa mesma nomeia. Um deslocamento cíclico (rotação por
/// 1..n-1 posições) sobre uma lista de cores distintas garante
/// matematicamente que nenhuma posição mantém sua própria cor
/// (derangement), incluindo a caixa da resposta certa. Como as 4 cores
/// usadas são exatamente as das alternativas desta pergunta, a cor
/// pedida no enunciado sempre aparece em alguma caixa ERRADA — a
/// confusão visual pedida por Rhoney.
///
/// `contextSeed` (o prompt) decide a rotação de forma determinística —
/// mesma pergunta sempre embaralha do mesmo jeito (não pisca ao
/// reconstruir o widget), mas perguntas diferentes não repetem sempre o
/// mesmo deslocamento (evita decorar "gira sempre 1 posição").
List<Color> deriveOptionBoxColors(String contextSeed, List<String> options) {
  final trueColors = [for (final o in options) colorForWord(o) ?? kColorChallengePalette['cinza']!];
  final n = trueColors.length;
  if (n < 2) return trueColors;

  final shift = 1 + Random(contextSeed.hashCode).nextInt(n - 1);
  return List.generate(n, (i) => trueColors[(i + shift) % n]);
}
