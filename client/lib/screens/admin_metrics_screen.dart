import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo.dart';

/// U.I/ADMIN_PAINEL_IN_APP_V1.md — painel administrativo leve, DENTRO
/// do app Flutter, só pra role=admin (autorização real fica 100% no
/// backend — GET /admin/metrics/summary já rejeita não-admin com 403;
/// esta tela só aparece na navegação pra quem já é admin, ver
/// settings_screen.dart). Somente leitura, layout mobile-first em
/// cards — versão mais enxuta do painel externo maior (ADMIN_DASHBOARD_
/// V1.md), que fica para uma etapa futura separada.
class AdminMetricsScreen extends StatefulWidget {
  const AdminMetricsScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<AdminMetricsScreen> createState() => _AdminMetricsScreenState();
}

class _AdminMetricsScreenState extends State<AdminMetricsScreen> {
  bool _loading = true;
  String? _error;
  String _period = '7d';
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await widget.client.getAdminMetricsSummary(period: _period);
      if (mounted) setState(() => _summary = summary);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel Admin')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PeriodSelector(
          period: _period,
          onChanged: (p) {
            setState(() => _period = p);
            _load();
          },
        ),
        const SizedBox(height: 12),
        if (_error != null) Text(_error!, style: TextStyle(color: AppColors.error)),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _summary == null
                  ? const SizedBox.shrink()
                  : ListView(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _KpiCard(label: 'Ativos hoje', value: '${_summary!['active_users_today']}')),
                            const SizedBox(width: 10),
                            Expanded(child: _KpiCard(label: 'Ativos na semana', value: '${_summary!['active_users_week']}')),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: _KpiCard(label: 'Novos cadastros', value: '${_summary!['new_signups_in_period']}')),
                            const SizedBox(width: 10),
                            Expanded(child: _KpiCard(label: 'Streak médio', value: '${_summary!['average_streak_active_users']}')),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const _SectionTitle('Quem mais progrediu'),
                        const SizedBox(height: 8),
                        ...(_summary!['top_progressors'] as List).cast<Map<String, dynamic>>().map(
                              (p) => _TopProgressorTile(progressor: p),
                            ),
                        if ((_summary!['top_progressors'] as List).isEmpty) const _EmptyRow(),
                        const SizedBox(height: 20),
                        const _SectionTitle('Taxa de acerto por território'),
                        const SizedBox(height: 8),
                        ...(_summary!['accuracy_by_territory'] as List).cast<Map<String, dynamic>>().map(
                              (t) => _AccuracyRow(entry: t),
                            ),
                        if ((_summary!['accuracy_by_territory'] as List).isEmpty) const _EmptyRow(),
                        const SizedBox(height: 20),
                        const _SectionTitle('Feedback pós-nível'),
                        const SizedBox(height: 8),
                        _FeedbackDistributionRow(distribution: _summary!['feedback_distribution'] as Map<String, dynamic>),
                        const SizedBox(height: 20),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.period, required this.onChanged});

  final String period;
  final ValueChanged<String> onChanged;

  static const _options = [('today', 'Hoje'), ('7d', '7 dias'), ('30d', '30 dias')];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (value, label) in _options) ...[
          Expanded(
            child: ChoiceChip(
              label: Text(label),
              selected: period == value,
              onSelected: (_) => onChanged(value),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 4),
          Text(value, style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 22).copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: Theme.of(context).textTheme.titleLarge);
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) => Text('Sem dados no período.', style: TextStyle(color: AppColors.muted));
}

class _TopProgressorTile extends StatelessWidget {
  const _TopProgressorTile({required this.progressor});

  final Map<String, dynamic> progressor;

  @override
  Widget build(BuildContext context) {
    final realName = progressor['real_name'] as String?;
    final displayName = realName != null && realName.isNotEmpty ? realName : progressor['nickname'] as String;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ProfilePhotoCircle(photoUrl: progressor['photo_url'] as String?, size: 36),
      title: Text(displayName),
      subtitle: Text('Nível ${progressor['level']} · streak ${progressor['current_streak']}'),
      trailing: Text('+${progressor['xp_gained']} XP', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
    );
  }
}

class _AccuracyRow extends StatelessWidget {
  const _AccuracyRow({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(entry['territory_id'] as String)),
          Text('${entry['accuracy_percent']}% (${entry['total_attempts']})', style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 13)),
        ],
      ),
    );
  }
}

class _FeedbackDistributionRow extends StatelessWidget {
  const _FeedbackDistributionRow({required this.distribution});

  final Map<String, dynamic> distribution;

  @override
  Widget build(BuildContext context) {
    final total = (distribution['facil'] as int) +
        (distribution['medio'] as int) +
        (distribution['dificil'] as int) +
        (distribution['muito_dificil'] as int);
    if (total == 0) return const _EmptyRow();
    String pct(String key) => '${((distribution[key] as int) * 100 / total).round()}%';
    return Row(
      children: [
        Expanded(child: Column(children: [Text(pct('facil')), const Text('Fácil', style: TextStyle(fontSize: 11))])),
        Expanded(child: Column(children: [Text(pct('medio')), const Text('Médio', style: TextStyle(fontSize: 11))])),
        Expanded(child: Column(children: [Text(pct('dificil')), const Text('Difícil', style: TextStyle(fontSize: 11))])),
        Expanded(child: Column(children: [Text(pct('muito_dificil')), const Text('Muito difícil', style: TextStyle(fontSize: 11))])),
      ],
    );
  }
}
