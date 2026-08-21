import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// Território "visual" (V2 item 4) — decisão de armazenamento confirmada
/// com Rhoney antes de implementar (régua Free-First): nenhuma imagem
/// real, nenhum Supabase Storage. As opções são ícones vetoriais do
/// próprio Flutter, custo zero com certeza absoluta, funciona offline.
/// O backend só manda a string do id (seed.py, `_visual_option`); este
/// arquivo é o único lugar que decodifica esse id em ícone/cor de verdade.
class VisualOptionSpec {
  const VisualOptionSpec({required this.icon, required this.color, required this.description});

  final IconData icon;
  final Color color;

  /// Descrição em português para leitor de tela — o ícone nunca pode ser
  /// a única forma de comunicar a opção (mesmo princípio de acessibilidade
  /// de AUDIO_FEEDBACK.md §4, aplicado aqui a conteúdo visual).
  final String description;
}

const Map<String, IconData> _kShapeFilled = {
  'circle': Icons.circle,
  'square': Icons.square,
  'star': Icons.star,
  'heart': Icons.favorite,
};

const Map<String, IconData> _kShapeOutline = {
  'circle': Icons.circle_outlined,
  'square': Icons.square_outlined,
  'star': Icons.star_border,
  'heart': Icons.favorite_border,
};

const Map<String, String> _kShapeName = {
  'circle': 'círculo',
  'square': 'quadrado',
  'star': 'estrela',
  'heart': 'coração',
};

const Map<String, Color> _kColorValue = {
  'gold': AppColors.gold,
  'teal': AppColors.teal,
  'error': AppColors.error,
  'bone': AppColors.bone,
};

const Map<String, String> _kColorName = {
  'gold': 'dourado',
  'teal': 'verde-azulado',
  'error': 'terracota',
  'bone': 'claro',
};

/// Decodifica um id de opção no formato "forma_preenchimento_cor_índice"
/// (o índice só garante strings únicas por desafio, nunca é exibido).
/// Retorna null se o id não seguir o formato esperado — quem chama deve
/// tratar isso como conteúdo mal formado, nunca travar a tela.
VisualOptionSpec? parseVisualOption(String optionId) {
  final parts = optionId.split('_');
  if (parts.length != 4) return null;
  final shape = parts[0];
  final fill = parts[1];
  final color = parts[2];

  final iconMap = fill == 'outline' ? _kShapeOutline : _kShapeFilled;
  final icon = iconMap[shape];
  final resolvedColor = _kColorValue[color];
  final shapeName = _kShapeName[shape];
  final colorName = _kColorName[color];
  if (icon == null || resolvedColor == null || shapeName == null || colorName == null) return null;

  final fillName = fill == 'outline' ? 'contorno' : 'preenchido';
  return VisualOptionSpec(
    icon: icon,
    color: resolvedColor,
    description: '$shapeName $colorName, $fillName',
  );
}
