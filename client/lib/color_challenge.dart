import 'dart:math';

import 'package:flutter/material.dart';

/// V3.0.1_DESAFIO_CORES.md descrevia uma versão "Stroop simplificada"
/// (texto neutro, sem interferência de cor). Pedido de Rhoney
/// (2026-09-03, testando o Relâmpago real: "está muito fácil, as
/// respostas devem ter cores e a cor da pergunta deve ser colorida de
/// outra criando maior grau de dificuldade") substitui isso pela
/// versão CLÁSSICA do efeito Stroop: as alternativas aparecem coloridas
/// na cor que nomeiam, e a palavra-alvo dentro do enunciado aparece
/// numa tinta DIFERENTE da cor que ela nomeia — o jogador precisa ler
/// (não só reconhecer a cor) sob pressão de tempo, o que é
/// genuinamente mais difícil que a versão neutra anterior.
///
/// Puramente visual — nunca muda challenge_id/options/correct_answer
/// nem qualquer contrato com o backend, só como o client pinta o texto
/// já existente. Território "cores" continua 100% de responsabilidade
/// do backend pra XP/resultado; isto é só apresentação.
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

/// Monta o enunciado com a palavra-alvo destacada numa tinta diferente
/// da cor que ela nomeia (interferência de Stroop). Escolhe a cor da
/// tinta de forma determinística a partir do próprio prompt (mesmo
/// enunciado sempre rende a mesma "armadilha visual" — não pisca ao
/// reconstruir o widget), sempre excluindo a cor real nomeada.
List<TextSpan> buildColorChallengePromptSpans(String prompt, TextStyle? baseStyle) {
  for (final entry in kColorChallengePalette.entries) {
    final wordName = entry.key;
    // Encontra a palavra no prompt preservando a capitalização original
    // (conteúdo curado sempre capitaliza o nome da cor, ex.: "Vermelha").
    final pattern = RegExp(wordName, caseSensitive: false);
    final match = pattern.firstMatch(prompt);
    if (match == null) continue;

    final decoyOptions = kColorChallengePalette.keys.where((k) => k != wordName).toList();
    final seed = prompt.hashCode;
    final decoyWord = decoyOptions[Random(seed).nextInt(decoyOptions.length)];
    final decoyColor = kColorChallengePalette[decoyWord]!;

    return [
      TextSpan(text: prompt.substring(0, match.start), style: baseStyle),
      TextSpan(
        text: prompt.substring(match.start, match.end),
        style: baseStyle?.copyWith(color: decoyColor, fontWeight: FontWeight.w800),
      ),
      TextSpan(text: prompt.substring(match.end), style: baseStyle),
    ];
  }
  // Nenhuma cor conhecida encontrada no prompt (não deveria acontecer
  // pro território "cores" com conteúdo curado) — mostra sem destaque,
  // nunca quebra a tela por causa de um enunciado inesperado.
  return [TextSpan(text: prompt, style: baseStyle)];
}
