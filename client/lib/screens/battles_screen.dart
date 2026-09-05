import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../widgets/profile_photo.dart';
import '../l10n/generated/app_localizations.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import '../widgets/help_sheet.dart';
import 'challenge_screen.dart';
import 'public_profile_screen.dart';

/// V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md). Lista batalhas
/// enviadas/recebidas via GET /battles — backend é a única autoridade
/// sobre status/vencedor, esta tela só exibe. Responder reaproveita
/// ChallengeScreen em modo battle (busca o desafio específico da
/// batalha, submete via POST /challenges/{id}/answer normal).
class BattlesScreen extends StatefulWidget {
  const BattlesScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<BattlesScreen> createState() => _BattlesScreenState();
}

class _BattlesScreenState extends State<BattlesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _battles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await widget.client.listBattles();
      if (mounted) {
        setState(() => _battles = (result['battles'] as List).cast<Map<String, dynamic>>());
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _answer(Map<String, dynamic> battle) async {
    final l10n = AppLocalizations.of(context)!;
    final territoryId = battle['territory_id'] as String;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeScreen(
          client: widget.client,
          territoryId: territoryId,
          territoryLabel: territoryLabel(l10n, territoryId),
          battleId: battle['battle_id'] as String,
        ),
      ),
    );
    _load();
  }

  void _showHelp() {
    final l10n = AppLocalizations.of(context)!;
    showHelpSheet(
      context,
      title: l10n.battlesHelpTitle,
      steps: [
        HelpStep(icon: Icons.people_outline, title: l10n.battlesHelpStep1Title, description: l10n.battlesHelpStep1Body),
        HelpStep(icon: Icons.tune, title: l10n.battlesHelpStep2Title, description: l10n.battlesHelpStep2Body),
        HelpStep(icon: Icons.schedule_outlined, title: l10n.battlesHelpStep3Title, description: l10n.battlesHelpStep3Body),
        HelpStep(icon: Icons.emoji_events_outlined, title: l10n.battlesHelpStep4Title, description: l10n.battlesHelpStep4Body),
        HelpStep(icon: Icons.bolt_outlined, title: l10n.battlesHelpStep5Title, description: l10n.battlesHelpStep5Body),
      ],
    );
  }

  Widget _statusLine(AppLocalizations l10n, Map<String, dynamic> battle) {
    final status = battle['status'] as String;
    final iAnswered = battle['i_answered'] as bool;
    final winner = battle['winner'] as String?;
    final nickname = battle['opponent_nickname'] as String;

    if (status == 'resolved') {
      return Text(
        switch (winner) {
          'me' => l10n.battleStatusWon(battle['win_bonus_xp'] as int),
          'tie' => l10n.battleStatusTie,
          _ => l10n.battleStatusLost(nickname),
        },
        style: TextStyle(color: winner == 'me' ? AppColors.gold : AppColors.muted),
      );
    }
    return Text(
      iAnswered ? l10n.battleStatusPendingWaitingOpponent(nickname) : l10n.battleStatusPendingWaitingMe,
      style: TextStyle(color: iAnswered ? AppColors.muted : AppColors.teal, fontWeight: iAnswered ? null : FontWeight.w600),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.battlesScreenTitle),
        actions: [
          IconButton(
            tooltip: l10n.battlesHelpTooltip,
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: TextStyle(color: AppColors.error)))
                : _battles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(l10n.battlesEmptyMessage, textAlign: TextAlign.center),
                        ),
                      )
                    // Pedido de Rhoney (04/09/2026): pull-to-refresh em
                    // qualquer tela do app.
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.gold,
                        child: ListView.builder(
                        itemCount: _battles.length,
                        itemBuilder: (context, index) {
                          final battle = _battles[index];
                          final canAnswer = battle['status'] == 'pending' && battle['i_answered'] == false;
                          // Nome real substitui o apelido gerado pelo
                          // sistema assim que existir (29/08/2026,
                          // pedido de Rhoney).
                          final opponentRealName = battle['opponent_real_name'] as String?;
                          final opponentLabel = opponentRealName != null && opponentRealName.isNotEmpty
                              ? opponentRealName
                              : battle['opponent_nickname'];
                          return ListTile(
                            // V4 item 1 — Perfil Público: só quando a
                            // batalha NÃO exige resposta agora (senão o
                            // toque na linha continuaria sendo a ação
                            // principal de responder, via botão em
                            // trailing) — PERFIL_PUBLICO_E_TORCIDA_V1.md
                            // §3, Batalha é ponto de entrada aprovado.
                            onTap: canAnswer
                                ? null
                                : () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => PublicProfileScreen(client: widget.client, userId: battle['opponent_user_id'] as String)),
                                    ),
                            leading: ProfilePhotoCircle(photoUrl: battle['opponent_photo_url'] as String?),
                            title: Text(
                              '${territoryLabel(l10n, battle['territory_id'] as String)} · $opponentLabel',
                            ),
                            subtitle: _statusLine(l10n, battle),
                            // AppTheme define minimumSize: Size.fromHeight(48)
                            // (largura infinita) pro FilledButton — dentro de
                            // ListTile.trailing isso quebra o layout do
                            // tile inteiro (achado já documentado em
                            // friends_screen.dart), corrigido reduzindo o
                            // mínimo em vez de usar Flexible/Expanded (que
                            // não existem aqui, é ListTile, não Row).
                            trailing: canAnswer
                                ? FilledButton(
                                    style: FilledButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                    onPressed: () => _answer(battle),
                                    child: Text(l10n.battleAnswerButton),
                                  )
                                : null,
                          );
                        },
                      ),
                    ),
      ),
    );
  }
}
