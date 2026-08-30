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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Painel Admin'),
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.bone,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.gold,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: _buildBody(),
          ),
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
        const SizedBox(height: 14),
        if (_error != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
            ),
            child: Text(_error!, style: TextStyle(color: AppColors.error)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _summary == null
                  ? const SizedBox.shrink()
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        _SectionTitle('Visão geral', icon: Icons.insights_rounded),
                        const SizedBox(height: 10),
                        _KpiGrid(
                          items: [
                            _KpiData('Ativos hoje', '${_summary!['active_users_today']}', Icons.today_rounded, AppColors.teal),
                            _KpiData('Ativos na semana', '${_summary!['active_users_week']}', Icons.date_range_rounded, AppColors.gold),
                            _KpiData('Fizeram alguma ação', '${_summary!['engaged_users_in_period']}', Icons.bolt_rounded, AppColors.victory),
                            _KpiData('Novos cadastros', '${_summary!['new_signups_in_period']}', Icons.person_add_alt_1_rounded, AppColors.purple),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _StreakBanner(value: '${_summary!['average_streak_active_users']}'),
                        const SizedBox(height: 24),
                        _SectionTitle('Quem mais progrediu', icon: Icons.emoji_events_rounded),
                        const SizedBox(height: 10),
                        _Card(
                          child: Column(
                            children: [
                              for (final p in (_summary!['top_progressors'] as List).cast<Map<String, dynamic>>())
                                _TopProgressorTile(progressor: p),
                              if ((_summary!['top_progressors'] as List).isEmpty) const _EmptyRow(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle('Taxa de acerto por território', icon: Icons.track_changes_rounded),
                        const SizedBox(height: 10),
                        _Card(
                          child: Column(
                            children: [
                              for (final t in (_summary!['accuracy_by_territory'] as List).cast<Map<String, dynamic>>())
                                _AccuracyRow(entry: t),
                              if ((_summary!['accuracy_by_territory'] as List).isEmpty) const _EmptyRow(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle('Feedback pós-nível', icon: Icons.reviews_rounded),
                        const SizedBox(height: 10),
                        _Card(
                          child: _FeedbackDistributionRow(distribution: _summary!['feedback_distribution'] as Map<String, dynamic>),
                        ),
                        const SizedBox(height: 24),
                        _SectionTitle('Movimento', icon: Icons.directions_walk_rounded),
                        const SizedBox(height: 10),
                        _MovementSection(movement: _summary!['movement'] as Map<String, dynamic>),
                        const SizedBox(height: 24),
                        _SectionTitle('Quem está usando o app', icon: Icons.groups_rounded),
                        const SizedBox(height: 4),
                        Text(
                          'Distribuição sobre a base total de cadastros — não muda com o período acima.',
                          style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 10),
                        _DemographicsSection(demographics: _summary!['demographics'] as Map<String, dynamic>),
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.bg2, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          for (final (value, label) in _options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: period == value ? AppColors.gold : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: AppTheme.technicalStyle(
                      color: period == value ? AppColors.bg : AppColors.bone,
                      fontSize: 13,
                    ).copyWith(fontWeight: period == value ? FontWeight.w800 : FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiData {
  const _KpiData(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.items});

  final List<_KpiData> items;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [for (final item in items) _KpiCard(data: item)],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: data.color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(data.icon, color: data.color, size: 18),
          Text(data.value, style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 24).copyWith(fontWeight: FontWeight.w800)),
          Text(data.label, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StreakBanner extends StatelessWidget {
  const _StreakBanner({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withValues(alpha: 0.18), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text('Streak médio dos ativos: ', style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 13)),
          Text(value, style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 15).copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.bone.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.icon});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gold.withValues(alpha: 0.20), AppColors.gold.withValues(alpha: 0.05)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 15).copyWith(fontWeight: FontWeight.w800, letterSpacing: 1.1),
          ),
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text('Sem dados no período.', style: TextStyle(color: AppColors.muted)),
      );
}

class _TopProgressorTile extends StatelessWidget {
  const _TopProgressorTile({required this.progressor});

  final Map<String, dynamic> progressor;

  @override
  Widget build(BuildContext context) {
    final realName = progressor['real_name'] as String?;
    final displayName = realName != null && realName.isNotEmpty ? realName : progressor['nickname'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ProfilePhotoCircle(photoUrl: progressor['photo_url'] as String?, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.w600)),
                Text('Nível ${progressor['level']} · streak ${progressor['current_streak']}', style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Text('+${progressor['xp_gained']} XP', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AccuracyRow extends StatelessWidget {
  const _AccuracyRow({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final percent = (entry['accuracy_percent'] as num).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(entry['territory_id'] as String, style: TextStyle(color: AppColors.bone))),
              Text('$percent% (${entry['total_attempts']})', style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: AppColors.bg,
              valueColor: AlwaysStoppedAnimation(AppColors.teal),
            ),
          ),
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
    double frac(String key) => (distribution[key] as int) / total;
    String pct(String key) => '${(frac(key) * 100).round()}%';
    final entries = [
      ('Fácil', pct('facil'), AppColors.victory),
      ('Médio', pct('medio'), AppColors.gold),
      ('Difícil', pct('dificil'), AppColors.error),
      ('Muito difícil', pct('muito_dificil'), AppColors.purple),
    ];
    return Row(
      children: [
        for (final (label, value, color) in entries)
          Expanded(
            child: Column(
              children: [
                Text(value, style: AppTheme.technicalStyle(color: color, fontSize: 16).copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(label, style: TextStyle(color: AppColors.muted, fontSize: 11), textAlign: TextAlign.center),
              ],
            ),
          ),
      ],
    );
  }
}

class _DemographicsSection extends StatelessWidget {
  const _DemographicsSection({required this.demographics});

  final Map<String, dynamic> demographics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DemographicCard(title: 'Gênero', icon: Icons.wc_rounded, buckets: (demographics['gender'] as List).cast<Map<String, dynamic>>()),
        const SizedBox(height: 12),
        _DemographicCard(title: 'Faixa etária', icon: Icons.cake_rounded, buckets: (demographics['age_range'] as List).cast<Map<String, dynamic>>()),
        const SizedBox(height: 12),
        _DemographicCard(title: 'Estado', icon: Icons.map_rounded, buckets: (demographics['state'] as List).cast<Map<String, dynamic>>()),
        const SizedBox(height: 12),
        _DemographicCard(title: 'Cidade', icon: Icons.location_city_rounded, buckets: (demographics['city'] as List).cast<Map<String, dynamic>>()),
      ],
    );
  }
}

class _DemographicCard extends StatelessWidget {
  const _DemographicCard({required this.title, required this.icon, required this.buckets});

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> buckets;

  @override
  Widget build(BuildContext context) {
    final total = buckets.fold<int>(0, (sum, b) => sum + (b['count'] as int));
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.teal, size: 16),
              const SizedBox(width: 8),
              Text(title, style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 13).copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          if (buckets.isEmpty || total == 0) const _EmptyRow(),
          for (final bucket in buckets)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(bucket['label'] as String, style: TextStyle(color: AppColors.bone, fontSize: 13))),
                      Text(
                        '${bucket['count']} (${((bucket['count'] as int) * 100 / total).round()}%)',
                        style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (bucket['count'] as int) / total,
                      minHeight: 5,
                      backgroundColor: AppColors.bg,
                      valueColor: AlwaysStoppedAnimation(AppColors.teal),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MovementSection extends StatelessWidget {
  const _MovementSection({required this.movement});

  final Map<String, dynamic> movement;

  @override
  Widget build(BuildContext context) {
    final goalBuckets = (movement['goal_distribution'] as List).cast<Map<String, dynamic>>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _KpiCard(data: _KpiData('Já ativaram', '${movement['enabled_users']}', Icons.toggle_on_outlined, AppColors.teal)),
            _KpiCard(data: _KpiData('Ativos no período', '${movement['active_users_in_period']}', Icons.directions_walk_rounded, AppColors.victory)),
            _KpiCard(data: _KpiData('Passos no período', '${movement['total_steps_in_period']}', Icons.bar_chart_rounded, AppColors.gold)),
            _KpiCard(data: _KpiData('Média por ativo', '${movement['average_steps_per_active_user']}', Icons.trending_up_rounded, AppColors.purple)),
          ],
        ),
        const SizedBox(height: 10),
        _DemographicCard(title: 'Meta diária escolhida', icon: Icons.flag_outlined, buckets: goalBuckets),
      ],
    );
  }
}
