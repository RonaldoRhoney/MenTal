import 'package:flutter/material.dart';

/// Extraído de home_screen.dart (_worldIcon) pra ser reaproveitado pelo
/// seletor de Mundo do fluxo guest (MENTAL_FLUXO_GUEST_3_QUESTOES_
/// DIAGNOSTICO_TECNICO_V1.md) sem duplicar o mapeamento — mesma
/// identidade visual de ícone por Mundo em ambos os lugares.
IconData worldIcon(String worldId) {
  switch (worldId) {
    case 'linguagem':
      return Icons.menu_book_rounded;
    case 'mente_logica':
      return Icons.psychology_rounded;
    case 'cultura_geral':
      return Icons.public_rounded;
    case 'descoberta':
      return Icons.explore_rounded;
    case 'idiomas':
      return Icons.translate_rounded;
    case 'valores':
      return Icons.volunteer_activism_rounded;
    case 'transito':
      return Icons.traffic_rounded;
    case 'esportes':
      return Icons.sports_soccer_rounded;
    case 'mitologia':
      return Icons.castle_rounded;
    case 'enem':
      return Icons.school_rounded;
    case 'concursos':
      return Icons.gavel_rounded;
    case 'tecnologia':
      return Icons.memory_rounded;
    case 'regioes_brasil':
      return Icons.map_rounded;
    case 'gastronomia':
      return Icons.restaurant_rounded;
    case 'oceanos':
      return Icons.waves_rounded;
    case 'espaco':
      return Icons.rocket_launch_rounded;
    default:
      return Icons.travel_explore_rounded;
  }
}
