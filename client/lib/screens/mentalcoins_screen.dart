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
///
/// Reajuste visual (29/08/2026, pedido de Rhoney: "melhore a organização
/// dos elementos, fontes e letras, torne tudo mais elegante"): seções
/// mais compactas (menos espaço vertical entre blocos), cabeçalho de
/// seção com "eyebrow" pequeno em vez de título grande repetido a cada
/// bloco, e cada reward track com valor abaixo do label (não mais ao
/// lado, que quebrava em telas estreitas) — achado real de validação em
/// dispositivo.
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
        _catalog = _catalog!.map((item) => item['id'] == itemId ? {...item, 'redeemed': true} : item).toList();
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _BalanceCard(balance: balance['balance'] as int, cycleStart: balance['cycle_start'] as String, cycleEnd: balance['cycle_end'] as String),
                  const SizedBox(height: 20),
                  _SectionHeader(title: l10n.mentalCoinsHowToEarnTitle),
                  const SizedBox(height: 10),
                  _RewardTrackCard(icon: Icons.bolt_rounded, color: AppColors.gold, label: l10n.mentalCoinsXpDailyLabel, value: l10n.mentalCoinsXpDailyValue),
                  const SizedBox(height: 8),
                  _RewardTrackCard(icon: Icons.directions_walk_rounded, color: AppColors.victory, label: l10n.mentalCoinsStepsWeekLabel, value: l10n.mentalCoinsStepsWeekValue),
                  const SizedBox(height: 8),
                  _RewardTrackCard(icon: Icons.local_fire_department_rounded, color: AppColors.purple, label: l10n.mentalCoinsStepsDayLabel, value: l10n.mentalCoinsStepsDayValue),
                  const SizedBox(height: 20),
                  _SectionHeader(title: l10n.mentalCoinsHallOfFameTitle),
                  const SizedBox(height: 10),
                  if ((_hallOfFame ?? []).isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(l10n.mentalCoinsHallOfFameEmpty, style: Theme.of(context).textTheme.bodySmall),
                    )
                  else
                    ..._hallOfFame!.map((entry) => _HallOfFameTile(entry: entry)),
                  const SizedBox(height: 20),
                  _SectionHeader(title: l10n.mentalCoinsRedeemTitle),
                  const SizedBox(height: 10),
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

/// Cabeçalho de seção compacto — "eyebrow" pequeno dourado + título serif,
/// substitui o Text solto em titleLarge repetido a cada bloco (ocupava
/// espaço vertical demais e não diferenciava seções na rolagem).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 17)),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.bg2, Color.lerp(AppColors.bg2, AppColors.gold, 0.1)!]),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const MentalCoin(size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$balance', style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.1)),
                const SizedBox(height: 2),
                Text(
                  l10n.mentalCoinsCycleNote(cycleEnd, cycleStart),
                  style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.14)),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          Text(value, style: AppTheme.technicalStyle(color: color, fontSize: 13).copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.right),
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry['nickname'] as String, style: Theme.of(context).textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                  Text(_categoryLabel(entry['category'] as String, rank), style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            const MentalCoin(size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item['name'] as String, style: Theme.of(context).textTheme.bodyLarge, overflow: TextOverflow.ellipsis),
                  Text(item['description'] as String, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text('$cost MentalCoins', style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (redeemed)
              Text(l10n.mentalCoinsRedeemedLabel, style: AppTheme.technicalStyle(color: AppColors.victory, fontSize: 12))
            else
              // Achado real em dispositivo (29/08/2026): o ThemeData global
              // dá minimumSize: Size.fromHeight(48) a todo FilledButton (ou
              // seja, largura MÍNIMA infinita) — dentro de um Row sem
              // Expanded isso gera "RenderBox was not laid out" (conflito
              // de constraints), um erro de LAYOUT silencioso que trava a
              // pintura de toda a lista acima sem mostrar nada na tela (não
              // é erro de build, não aparece o retângulo vermelho padrão).
              // Sobrescrever minimumSize aqui remove a exigência de largura
              // infinita só neste botão compacto.
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 38), padding: const EdgeInsets.symmetric(horizontal: 14)),
                onPressed: (redeeming || !canAfford) ? null : onRedeem,
                child: redeeming
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.mentalCoinsRedeemButton, style: const TextStyle(fontSize: 13)),
              ),
          ],
        ),
      ),
    );
  }
}
