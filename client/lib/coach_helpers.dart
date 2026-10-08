import 'package:flutter/material.dart';

import 'api/api_client.dart';
import 'l10n/generated/app_localizations.dart';
import 'screens/challenge_screen.dart';
import 'screens/friends_screen.dart';
import 'screens/mentalcoins_screen.dart';
import 'screens/movement_screen.dart';
import 'screens/ranking_screen.dart';
import 'territories.dart';

/// Lógica pura de GET /coach e GET /coach/world/{id} (análise por regras do
/// desempenho do próprio usuário, custo zero — backend/app/coach.py), antes
/// dividida entre a tela própria CoachScreen e o cartão MyMentalAiWorldCard
/// (ambos removidos, pedido de Rhoney 08/10/2026: "My_Mental_AI deve ser
/// removido e o agente flutuante assume seu lugar com todas suas
/// características"). Usado hoje só por floating_mental_overlay.dart.

/// Resolve o `{territory}` dos textos do servidor com o nome do território (que vive no l10n do app).
String coachText(AppLocalizations l10n, String text, String? territoryId) {
  if (territoryId == null) return text;
  return text.replaceAll('{territory}', territoryLabel(l10n, territoryId));
}

IconData coachIcon(String cardId) {
  switch (cardId) {
    case 'streak_repair':
    case 'streak':
      return Icons.local_fire_department_rounded;
    case 'daily_cap':
      return Icons.speed_rounded;
    case 'close_to_conquest':
    case 'world_close_to_conquest':
      return Icons.flag_rounded;
    case 'world_closest':
    case 'world_progress':
    case 'world_completed':
    case 'world_generic':
      return Icons.public_rounded;
    case 'weakest':
    case 'world_weakest':
      return Icons.trending_up_rounded;
    case 'strongest':
    case 'world_strongest':
      return Icons.star_rounded;
    case 'world_newcomer':
      return Icons.waving_hand_rounded;
    case 'world_hints':
      return Icons.lightbulb_outline_rounded;
    case 'world_unexplored':
      return Icons.explore_rounded;
    case 'world_idle':
      return Icons.schedule_rounded;
    case 'ranking':
      return Icons.leaderboard_rounded;
    case 'boost':
      return Icons.bolt_rounded;
    case 'hints':
      return Icons.lightbulb_outline_rounded;
    case 'explore_movement':
      return Icons.directions_walk_rounded;
    case 'explore_friends':
      return Icons.group_add_rounded;
    case 'newcomer':
      return Icons.waving_hand_rounded;
    default:
      return Icons.tips_and_updates_rounded;
  }
}

/// Abre o destino indicado pelo servidor num cartão de dica.
Future<void> openCoachAction(BuildContext context, ApiClient client, Map<String, dynamic>? action) async {
  if (action == null) return;
  final l10n = AppLocalizations.of(context)!;
  final navigator = Navigator.of(context);
  switch (action['type']) {
    case 'territory':
      final id = action['territory_id'] as String;
      await navigator.push(MaterialPageRoute(
        builder: (_) => ChallengeScreen(
          client: client,
          territoryId: id,
          territoryLabel: territoryLabel(l10n, id),
          relampago: action['relampago'] == true,
        ),
      ));
    case 'movement':
      await navigator.push(MaterialPageRoute(builder: (_) => MovementScreen(client: client)));
    case 'mentalcoins':
      await navigator.push(MaterialPageRoute(builder: (_) => MentalCoinsScreen(client: client)));
    case 'ranking':
      await navigator.push(MaterialPageRoute(builder: (_) => RankingScreen(client: client)));
    case 'friends':
      await navigator.push(MaterialPageRoute(builder: (_) => FriendsScreen(client: client)));
  }
}
