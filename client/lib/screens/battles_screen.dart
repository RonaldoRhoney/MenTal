import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../widgets/profile_photo.dart';
import '../l10n/generated/app_localizations.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import 'challenge_screen.dart';

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
      appBar: AppBar(title: Text(l10n.battlesScreenTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                : _battles.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(l10n.battlesEmptyMessage, textAlign: TextAlign.center),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _battles.length,
                        itemBuilder: (context, index) {
                          final battle = _battles[index];
                          final canAnswer = battle['status'] == 'pending' && battle['i_answered'] == false;
                          final opponentRealName = battle['opponent_real_name'] as String?;
                          final opponentLabel = opponentRealName != null && opponentRealName.isNotEmpty
                              ? '${battle['opponent_nickname']} · $opponentRealName'
                              : battle['opponent_nickname'];
                          return ListTile(
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
    );
  }
}
