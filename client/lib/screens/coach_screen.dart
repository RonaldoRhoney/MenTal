import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../territories.dart';
import '../theme/agent_neon.dart';
import '../theme/app_theme.dart';
import 'challenge_screen.dart';
import 'friends_screen.dart';
import 'mentalcoins_screen.dart';
import 'movement_screen.dart';
import 'ranking_screen.dart';

/// Nome do agente do usuário (pedido de Rhoney, 21/09/2026).
const String kCoachName = 'My_Mental_AI';

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

/// Abre o destino indicado pelo servidor num cartão do My_Mental_AI.
Future<void> openCoachAction(BuildContext context, ApiClient client,
    Map<String, dynamic>? action) async {
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
      await navigator.push(
          MaterialPageRoute(builder: (_) => MovementScreen(client: client)));
    case 'mentalcoins':
      await navigator.push(
          MaterialPageRoute(builder: (_) => MentalCoinsScreen(client: client)));
    case 'ranking':
      await navigator.push(
          MaterialPageRoute(builder: (_) => RankingScreen(client: client)));
    case 'friends':
      await navigator.push(
          MaterialPageRoute(builder: (_) => FriendsScreen(client: client)));
  }
}

/// Tela do My_Mental_AI: análise automática (por regras) do desempenho do próprio usuário — onde vai
/// melhor, onde focar, o que falta para conquistar territórios/Mundos, ranking, XP e como usar o app.
class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  Map<String, dynamic>? _data;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.client.getCoach();
      if (mounted) {
        setState(() {
          _data = data;
          _failed = false;
        });
      }
    } on ApiException {
      if (mounted && _data == null) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text(kCoachName)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.gold,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(l10n.coachSubtitle,
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 14),
              if (data == null && !_failed)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()))
              else if (_failed)
                Column(children: [
                  Icon(Icons.cloud_off_rounded,
                      size: 40, color: AppColors.muted),
                  const SizedBox(height: 8),
                  Text(l10n.coachLoadError, textAlign: TextAlign.center),
                  TextButton(
                      onPressed: _load, child: Text(l10n.feedbackReloadButton)),
                ])
              else ...[
                _SummaryRow(summary: data!['summary'] as Map<String, dynamic>),
                const SizedBox(height: 16),
                for (final c
                    in (data['cards'] as List).cast<Map<String, dynamic>>())
                  _CoachCard(card: c, client: widget.client, onReturned: _load),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final accuracy = ((summary['accuracy'] as num) * 100).round();
    final rank = summary['weekly_rank'];
    Widget chip(IconData icon, String label) => Chip(
          avatar: Icon(icon, size: 16, color: AppColors.gold),
          label: Text(label, style: const TextStyle(fontSize: 12)),
        );
    return Wrap(
      key: const Key('coach_summary'),
      spacing: 8,
      runSpacing: 4,
      children: [
        chip(Icons.check_circle_outline_rounded,
            l10n.coachSummaryAnswers(summary['total_answers'] as int)),
        if ((summary['total_answers'] as int) > 0)
          chip(Icons.percent_rounded, l10n.coachSummaryAccuracy(accuracy)),
        chip(Icons.bolt_rounded,
            l10n.coachSummaryWeekXp(summary['weekly_xp'] as int)),
        if (rank != null)
          chip(Icons.leaderboard_rounded, l10n.coachSummaryRank(rank as int)),
      ],
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard(
      {required this.card, required this.client, required this.onReturned});

  final Map<String, dynamic> card;
  final ApiClient client;
  final VoidCallback onReturned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final territoryId = card['territory_id'] as String?;
    final action = card['action'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        key: Key('coach_card_${card['id']}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(coachIcon(card['id'] as String),
                    color: AppColors.gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(
                        coachText(l10n, card['title'] as String, territoryId),
                        style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            Text(coachText(l10n, card['body'] as String, territoryId),
                style: Theme.of(context).textTheme.bodyMedium),
            if (action != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  key: Key('coach_action_${card['id']}'),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 16)),
                  onPressed: () async {
                    await openCoachAction(context, client, action);
                    onReturned();
                  },
                  child: Text(l10n.coachGoButton),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Nome do agente no padrão neon ("My_Mental_" branco + "AI" ciano).
class AgentNameText extends StatelessWidget {
  const AgentNameText({super.key, this.fontSize = 13});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, letterSpacing: 0.2),
        children: const [
          TextSpan(text: 'My_Mental_', style: TextStyle(color: Colors.white)),
          TextSpan(text: 'AI', style: TextStyle(color: kAgentCyan)),
        ],
      ),
    );
  }
}

/// Cartão do My_Mental_AI dentro de cada Mundo, no padrão neon do banner do
/// MENTAL LINGO (pedido de Rhoney, 25/09/2026). SEMPRE clicável: com ação
/// (território etc.) leva ao destino; sem ação abre a tela geral de dicas.
/// Texto completo, sem reticências — o cartão cresce com o conteúdo.
class MyMentalAiWorldCard extends StatelessWidget {
  const MyMentalAiWorldCard({super.key, required this.card, required this.client, required this.onReturned});

  final Map<String, dynamic> card;
  final ApiClient client;
  final VoidCallback onReturned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final territoryId = card['territory_id'] as String?;
    final action = card['action'] as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const Key('world_coach_card'),
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            if (action != null) {
              await openCoachAction(context, client, action);
            } else {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CoachScreen(client: client)));
            }
            onReturned();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: agentNeonDecoration(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kAgentNavy,
                    border: Border.all(color: kAgentCyan, width: 2),
                    boxShadow: [BoxShadow(color: kAgentCyan.withValues(alpha: 0.35), blurRadius: 12)],
                  ),
                  child: Icon(coachIcon(card['id'] as String), color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AgentNameText(),
                      const SizedBox(height: 4),
                      Text(coachText(l10n, card['title'] as String, territoryId),
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(coachText(l10n, card['body'] as String, territoryId),
                          style: const TextStyle(color: kAgentSoftText, fontSize: 12.5, height: 1.3)),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [kAgentBlue, kAgentIndigo]),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1.2),
                          ),
                          child: Text(action != null ? l10n.coachGoButton : 'Ver mais dicas',
                              style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
