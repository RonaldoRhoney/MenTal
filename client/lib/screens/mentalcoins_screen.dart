import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/mentalcoin.dart';

/// Tela de MentalCoins (U.I/MENTALCOINS_V1.md) — moeda de prestígio
/// semanal, sem valor monetário, não compravel com dinheiro real (§1).
/// Saldo/Hall da Fama/catálogo vêm 100% prontos do backend — esta tela
/// só exibe, nunca calcula (mesmo princípio de autoridade única já
/// aplicado a XP/score no resto do app).
class MentalCoinsScreen extends StatefulWidget {
  const MentalCoinsScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<MentalCoinsScreen> createState() => _MentalCoinsScreenState();
}

class _MentalCoinsScreenState extends State<MentalCoinsScreen> {
  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>>? _hallOfFame;
  List<Map<String, dynamic>>? _catalog;
  String? _error;
  String? _redeemingItemId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        widget.client.getMentalCoinsBalance(),
        widget.client.getMentalCoinsHallOfFame(),
        widget.client.getMentalCoinsCatalog(),
      ]);
      if (!mounted) return;
      setState(() {
        _balance = results[0];
        _hallOfFame = (results[1]['entries'] as List).cast<Map<String, dynamic>>();
        _catalog = (results[2]['items'] as List).cast<Map<String, dynamic>>();
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _redeem(String itemId) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _redeemingItemId = itemId);
    try {
      final balance = await widget.client.redeemMentalCoinsItem(itemId);
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _catalog = _catalog!
            .map((item) => item['id'] == itemId ? {...item, 'redeemed': true} : item)
            .toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.mentalCoinsRedeemSuccessMessage)));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'INSUFFICIENT_BALANCE' ? l10n.mentalCoinsInsufficientBalanceError : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _redeemingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final balance = _balance;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mentalCoinsScreenTitle)),
      body: SafeArea(
        child: balance == null
            ? Center(
                child: _error != null
                    ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                    : const CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BalanceCard(balance: balance['balance'] as int, cycleStart: balance['cycle_start'] as String, cycleEnd: balance['cycle_end'] as String),
                  const SizedBox(height: 24),
                  Text(l10n.mentalCoinsHowToEarnTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  _RewardTrackCard(icon: Icons.bolt_rounded, color: AppColors.gold, label: l10n.mentalCoinsXpDailyLabel, value: l10n.mentalCoinsXpDailyValue),
                  const SizedBox(height: 8),
                  _RewardTrackCard(icon: Icons.directions_walk_rounded, color: AppColors.victory, label: l10n.mentalCoinsStepsWeekLabel, value: l10n.mentalCoinsStepsWeekValue),
                  const SizedBox(height: 8),
                  _RewardTrackCard(icon: Icons.local_fire_department_rounded, color: AppColors.purple, label: l10n.mentalCoinsStepsDayLabel, value: l10n.mentalCoinsStepsDayValue),
                  const SizedBox(height: 24),
                  Text(l10n.mentalCoinsHallOfFameTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if ((_hallOfFame ?? []).isEmpty)
                    Text(l10n.mentalCoinsHallOfFameEmpty, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 13))
                  else
                    ..._hallOfFame!.map((entry) => _HallOfFameTile(entry: entry)),
                  const SizedBox(height: 24),
                  Text(l10n.mentalCoinsRedeemTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...(_catalog ?? []).map(
                    (item) => _CatalogTile(
                      item: item,
                      redeeming: _redeemingItemId == item['id'],
                      currentBalance: balance['balance'] as int,
                      onRedeem: () => _redeem(item['id'] as String),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance, required this.cycleStart, required this.cycleEnd});

  final int balance;
  final String cycleStart;
  final String cycleEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.bg2, Color.lerp(AppColors.bg2, AppColors.gold, 0.1)!]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const MentalCoin(size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$balance', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(l10n.mentalCoinsCycleNote(cycleEnd, cycleStart), style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardTrackCard extends StatelessWidget {
  const _RewardTrackCard({required this.icon, required this.color, required this.label, required this.value});

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Text(value, style: AppTheme.technicalStyle(color: color, fontSize: 13).copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _HallOfFameTile extends StatelessWidget {
  const _HallOfFameTile({required this.entry});

  final Map<String, dynamic> entry;

  String _categoryLabel(String category, int? rank) {
    switch (category) {
      case 'xp_daily':
        return '$rankº · XP do dia';
      case 'steps_week':
        return 'Campeão da semana';
      case 'steps_day':
        return 'Recordista do dia';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rank = entry['rank'] as int?;
    final isFirst = rank == 1 || entry['category'] != 'xp_daily';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(14),
          border: isFirst ? Border.all(color: AppColors.gold.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: isFirst ? AppColors.gold : AppColors.muted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry['nickname'] as String, style: Theme.of(context).textTheme.bodyMedium),
                  Text(_categoryLabel(entry['category'] as String, rank), style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            Text('+${entry['amount']}', style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 13).copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _CatalogTile extends StatelessWidget {
  const _CatalogTile({required this.item, required this.redeeming, required this.currentBalance, required this.onRedeem});

  final Map<String, dynamic> item;
  final bool redeeming;
  final int currentBalance;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final redeemed = item['redeemed'] as bool;
    final cost = item['cost'] as int;
    final canAfford = currentBalance >= cost;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const MentalCoin(size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'] as String, style: Theme.of(context).textTheme.bodyLarge),
                  Text(item['description'] as String, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 4),
                  Text('$cost MentalCoins', style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 12)),
                ],
              ),
            ),
            if (redeemed)
              Text(l10n.mentalCoinsRedeemedLabel, style: AppTheme.technicalStyle(color: AppColors.victory, fontSize: 12))
            else
              FilledButton(
                onPressed: (redeeming || !canAfford) ? null : onRedeem,
                child: redeeming
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.mentalCoinsRedeemButton),
              ),
          ],
        ),
      ),
    );
  }
}
