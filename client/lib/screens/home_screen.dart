import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/movement_service.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo.dart';
import '../widgets/xp_bar.dart';
import 'battles_screen.dart';
import 'profile_screen.dart';
import 'challenge_screen.dart';
import 'feedback_screen.dart';
import 'friends_screen.dart';
import 'movement_screen.dart';
import 'progress_screen.dart';
import 'ranking_screen.dart';
import 'settings_screen.dart';

/// Home: um CTA primário claro por território, conforme Princípio de
/// Clareza Imediata (PRODUCT_PRINCIPLES.md §1) — nada compete visualmente
/// com "escolher território e jogar". Os indicadores de conquista/XP por
/// território (V1.1) são status secundário, não uma segunda ação.
///
/// Redesign estrutural (26/08/2026, pedido de Rhoney): antes, 8 ícones de
/// utilidade (Progresso/Ranking/Amigos/Batalhas/Movimento/Perfil/Config/
/// Feedback) amontoados na AppBar competiam com o título "MENTAL", e os
/// territórios apareciam como uma pilha vertical contínua e visualmente
/// idêntica, sem hierarquia entre o card de progresso e os territórios.
/// Não muda XP/conquista/dado nenhum — só reorganização visual:
/// - Navegação de utilidade desceu pra uma bottom nav fixa (4 destinos +
///   "Mais", que abre os itens menos usados no dia a dia num bottom sheet).
/// - O topo virou identidade de marca (wordmark + slogan, mesma
///   linguagem visual do splash/login), sem nenhum ícone de ação.
/// - Territórios agora em cards com grid de 2 colunas dentro de cada
///   Mundo, com o card de progresso do usuário visualmente destacado
///   (fundo elevado + borda) do resto da lista.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _progress;
  String? _error;
  // Foto real + nome real do usuário ao lado do Nível (pedido de Rhoney,
  // 26/08 e 27/08/2026), clicável pra editar — GET /progress não traz
  // esses campos, então carrega separado via GET /profile.
  String? _photoUrl;
  String? _realName;

  // V2 item 9 — badge de passos ainda não coletados junto ao ícone de
  // Movimento (decisão de Rhoney, 2026-08-21: "catch-up ao reabrir o
  // app", nunca serviço em segundo plano com notificação fixa). Mostra
  // o valor certo assim que a Home carrega, usando a última leitura
  // conhecida do sensor de QUALQUER sessão — não espera um evento novo.
  int? _movementPendingSteps;
  String? _movementCycleId;
  StreamSubscription<int>? _movementStepSub;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadMovementBadge();
    _loadProfileHeader();
  }

  Future<void> _loadProfileHeader() async {
    try {
      final profile = await widget.client.getProfile();
      if (mounted) {
        setState(() {
          _photoUrl = profile['photo_url'] as String?;
          _realName = profile['real_name'] as String?;
        });
      }
    } on ApiException catch (_) {
      // Foto/nome são reforço visual, nunca bloqueiam a Home por causa disso.
    }
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProfileScreen(client: widget.client)),
    );
    _loadProfileHeader();
  }

  @override
  void dispose() {
    _movementStepSub?.cancel();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await widget.client.progress();
      if (mounted) setState(() => _progress = progress);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _loadMovementBadge() async {
    try {
      final status = await widget.client.movementStatus();
      final enabled = status['movement_enabled'] as bool;
      final cycle = status['current_cycle'] as Map<String, dynamic>?;
      if (!enabled || cycle == null) {
        _movementStepSub?.cancel();
        _movementCycleId = null;
        if (mounted) setState(() => _movementPendingSteps = null);
        return;
      }

      final cycleId = cycle['id'] as String;
      await MovementService.instance.ensureBaselineFor(cycleId);
      final cachedLast = await MovementService.instance.lastKnownRawSteps();
      if (cachedLast != null) {
        final delta = await MovementService.instance.pendingDeltaFor(cycleId, cachedLast);
        if (mounted) setState(() => _movementPendingSteps = delta.uncollectedSteps);
      }

      if (_movementCycleId != cycleId) {
        _movementCycleId = cycleId;
        _movementStepSub?.cancel();
        _movementStepSub = MovementService.instance.stepCountStream().listen((steps) async {
          final delta = await MovementService.instance.pendingDeltaFor(cycleId, steps);
          if (mounted) setState(() => _movementPendingSteps = delta.uncollectedSteps);
        });
      }
    } on ApiException catch (_) {
      // Badge é reforço visual (mesmo princípio de AUDIO_FEEDBACK.md §4
      // aplicado aqui) — nunca bloqueia ou quebra a Home por causa disso.
    }
  }

  Map<String, dynamic>? _territoryProgress(String territoryId) {
    final territories = _progress?['territories'] as List?;
    if (territories == null) return null;
    for (final t in territories) {
      if ((t as Map<String, dynamic>)['territory_id'] == territoryId) return t;
    }
    return null;
  }

  // BLOCOS_MENUS.md (aprovado 2026-08-23): Bloco é organização de menu
  // dentro de um Mundo — puramente visual, sem afetar XP/conquista.
  // Territórios sem bloco (block_id null) continuam soltos direto no
  // Mundo, sem sub-cabeçalho, como sempre foram.
  Map<String, String> _blockNameByTerritory() {
    final blocks = (_progress?['blocks'] as List?)?.cast<Map<String, dynamic>>();
    if (blocks == null) return const {};
    final map = <String, String>{};
    for (final block in blocks) {
      final name = block['name'] as String;
      for (final territoryId in (block['territory_ids'] as List).cast<String>()) {
        map[territoryId] = name;
      }
    }
    return map;
  }

  // V2 item 10 — Mundos completos. O backend é a autoridade sobre o
  // agrupamento (GET /progress já devolve os territórios de cada mundo
  // e se está completo) — a Home só organiza visualmente, nunca decide
  // sozinha quais territórios pertencem a qual mundo.
  List<Widget> _buildWorldSections(AppLocalizations l10n) {
    final worlds = (_progress?['worlds'] as List?)?.cast<Map<String, dynamic>>();
    if (worlds == null || worlds.isEmpty) {
      return [_WorldSection(children: _territoryGroups(l10n, kTerritoryIds, const {}))];
    }

    final blockNameByTerritory = _blockNameByTerritory();
    final sections = <Widget>[];
    for (final world in worlds) {
      final territoryIds = (world['territory_ids'] as List).cast<String>();
      final completed = world['completed'] as bool;
      sections.add(
        _WorldSection(
          title: world['name'] as String,
          completed: completed,
          children: _territoryGroups(l10n, territoryIds, blockNameByTerritory),
        ),
      );
    }
    return sections;
  }

  /// Agrupa territórios consecutivos do mesmo bloco (ou sem bloco) numa
  /// mesma "linha" de grid — cada grupo vira um título opcional (nome do
  /// bloco) seguido de um Wrap em 2 colunas com os cards de território
  /// daquele grupo.
  List<Widget> _territoryGroups(
    AppLocalizations l10n,
    List<String> territoryIds,
    Map<String, String> blockNameByTerritory,
  ) {
    final groups = <Widget>[];
    String? currentBlock;
    List<String> currentIds = [];

    void flush() {
      if (currentIds.isEmpty) return;
      groups.add(
        _TerritoryGroup(
          blockName: currentBlock,
          territoryIds: List.of(currentIds),
          l10n: l10n,
          territoryProgressOf: _territoryProgress,
          client: widget.client,
          onReturned: _loadProgress,
        ),
      );
      currentIds = [];
    }

    for (final territoryId in territoryIds) {
      final blockName = blockNameByTerritory[territoryId];
      if (blockName != currentBlock) {
        flush();
        currentBlock = blockName;
      }
      currentIds.add(territoryId);
    }
    flush();
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Identidade de marca no topo — mesma linguagem visual do
              // splash/login (BRAND.md), sem nenhum ícone de utilidade
              // competindo com o wordmark.
              const SizedBox(height: 16),
              Text(l10n.homeTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 4),
              Text(
                l10n.loginSlogan,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              // Acessos dinâmicos (pedido de Rhoney, 2026-08-26): Progresso/
              // Ranking/Amigos/Movimento como cards de atalho logo abaixo da
              // marca, em vez de ícones pequenos disputando espaço.
              _QuickActionsRow(
                client: widget.client,
                movementPendingSteps: _movementPendingSteps,
                onReturnFromProgress: _loadProgress,
                onReturnFromMovement: _loadMovementBadge,
              ),
              const SizedBox(height: 20),
              if (progress != null)
                _ProgressCard(
                  progress: progress,
                  photoUrl: _photoUrl,
                  realName: _realName,
                  l10n: l10n,
                  onTapPhoto: _openProfile,
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              Expanded(
                child: ListView(children: _buildWorldSections(l10n)),
              ),
            ],
          ),
        ),
      ),
      // Bottom nav (pedido de Rhoney, 2026-08-26): Home/Perfil/Config/
      // Batalhas/Feedback — os itens de acesso mais frequente no dia a
      // dia sobem pra _QuickActionsRow acima.
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) async {
          switch (index) {
            case 0:
              return; // Início — já estamos aqui.
            case 1:
              await _openProfile();
            case 2:
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => SettingsScreen(client: widget.client)),
              );
            case 3:
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BattlesScreen(client: widget.client)),
              );
            case 4:
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FeedbackScreen(client: widget.client)),
              );
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_rounded), label: l10n.homeNavLabel),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), label: l10n.profileTooltip),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), label: l10n.settingsTooltip),
          NavigationDestination(icon: const Icon(Icons.sports_martial_arts_outlined), label: l10n.battlesTooltip),
          NavigationDestination(icon: const Icon(Icons.feedback_outlined), label: l10n.feedbackMenuTooltip),
        ],
      ),
    );
  }
}

/// Acessos rápidos a Progresso/Ranking/Amigos/Movimento — pedido de
/// Rhoney (2026-08-26): "de forma mais dinâmica e com melhor
/// usabilidade" do que ícones pequenos de bottom nav. Cards quadrados
/// com ícone + label, cor de destaque própria por ação (evita o "tudo
/// igual" que motivou o redesign inteiro).
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.client,
    required this.movementPendingSteps,
    required this.onReturnFromProgress,
    required this.onReturnFromMovement,
  });

  final ApiClient client;
  final int? movementPendingSteps;
  final VoidCallback onReturnFromProgress;
  final VoidCallback onReturnFromMovement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: Icons.bar_chart_rounded,
            label: l10n.progressTooltip,
            color: AppColors.teal,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProgressScreen(client: client)),
              );
              onReturnFromProgress();
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.leaderboard_rounded,
            label: l10n.rankingTooltip,
            color: AppColors.gold,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RankingScreen(client: client)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.people_outline_rounded,
            label: l10n.friendsTooltip,
            color: AppColors.teal,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => FriendsScreen(client: client)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.directions_walk_rounded,
            label: l10n.movementTooltip,
            color: AppColors.gold,
            badgeCount: movementPendingSteps,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => MovementScreen(client: client)),
              );
              onReturnFromMovement();
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: (badgeCount ?? 0) > 0,
                label: Text('$badgeCount'),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                // Achado real de validação em dispositivo (26/08/2026):
                // com maxLines: 1 + a largura estreita de 4 colunas,
                // labels como "Progresso"/"Movimento" truncavam
                // ("Progres...", "Movime..."). fontSize menor + 2 linhas
                // resolve sem precisar encurtar o texto em si.
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12, height: 1.15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seção de um Mundo — colapsável (pedido de Rhoney, 2026-08-26: "não
/// quero tudo na tela"): só o cabeçalho fica visível por padrão, os
/// territórios daquele Mundo (grid 2 colunas) só aparecem ao tocar nele
/// e expandir. Cada Mundo é visualmente separado do próximo por um card
/// com fundo levemente elevado.
class _WorldSection extends StatelessWidget {
  const _WorldSection({this.title, this.completed = false, required this.children});

  final String? title;
  final bool completed;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: title == null
            ? Padding(padding: const EdgeInsets.all(16), child: Column(children: children))
            : Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  iconColor: AppColors.gold,
                  collapsedIconColor: AppColors.muted,
                  title: Row(
                    children: [
                      Expanded(child: Text(title!, style: Theme.of(context).textTheme.titleLarge)),
                      if (completed) ...[
                        const Icon(Icons.check_circle, color: AppColors.gold, size: 20),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  children: children,
                ),
              ),
      ),
    );
  }
}

/// Um grupo de territórios (mesmo bloco, ou soltos sem bloco) — título
/// opcional do bloco + os cards em grid de 2 colunas (Wrap), reduzindo a
/// sensação de "pilha infinita" à medida que mais territórios/Blocos
/// forem adicionados na V3.
class _TerritoryGroup extends StatelessWidget {
  const _TerritoryGroup({
    required this.blockName,
    required this.territoryIds,
    required this.l10n,
    required this.territoryProgressOf,
    required this.client,
    required this.onReturned,
  });

  final String? blockName;
  final List<String> territoryIds;
  final AppLocalizations l10n;
  final Map<String, dynamic>? Function(String) territoryProgressOf;
  final ApiClient client;
  final VoidCallback onReturned;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (blockName != null) ...[
            Text(blockName!, style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 8),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final cardWidth = (constraints.maxWidth - spacing) / 2;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final territoryId in territoryIds)
                    SizedBox(
                      width: cardWidth,
                      child: _TerritoryCard(
                        territoryId: territoryId,
                        label: territoryLabel(l10n, territoryId),
                        progress: territoryProgressOf(territoryId),
                        l10n: l10n,
                        client: client,
                        onReturned: onReturned,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TerritoryCard extends StatelessWidget {
  const _TerritoryCard({
    required this.territoryId,
    required this.label,
    required this.progress,
    required this.l10n,
    required this.client,
    required this.onReturned,
  });

  final String territoryId;
  final String label;
  final Map<String, dynamic>? progress;
  final AppLocalizations l10n;
  final ApiClient client;
  final VoidCallback onReturned;

  @override
  Widget build(BuildContext context) {
    final conquered = progress?['conquered'] as bool? ?? false;
    // V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md). Sempre
    // relativo a você + amigos confirmados (nunca global) — o backend
    // já filtra isso, a Home só exibe o que vem pronto.
    final detentorNickname = progress?['detentor_nickname'] as String?;
    final isDetentor = progress?['is_detentor'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8)),
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChallengeScreen(client: client, territoryId: territoryId, territoryLabel: label),
              ),
            );
            onReturned();
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.newChallengeButton(label), textAlign: TextAlign.center, maxLines: 2),
              if (conquered) ...[
                const SizedBox(height: 4),
                const Icon(Icons.check_circle, size: 18),
              ],
            ],
          ),
        ),
        if (detentorNickname != null) ...[
          const SizedBox(height: 4),
          Text(
            isDetentor ? l10n.territoryDetentorIsMeLabel : l10n.territoryDetentorLabel(detentorNickname),
            textAlign: TextAlign.center,
            style: AppTheme.technicalStyle(
              color: isDetentor ? AppColors.gold : AppColors.muted,
              fontSize: 11,
            ),
          ),
        ],
        // V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md). Modo
        // extra só pra "palavras", nunca substitui o modo normal.
        if (territoryId == 'palavras') ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChallengeScreen(
                    client: client,
                    territoryId: territoryId,
                    territoryLabel: label,
                    relampago: true,
                  ),
                ),
              );
              onReturned();
            },
            child: Text(l10n.relampagoModeLabel, textAlign: TextAlign.center, maxLines: 2),
          ),
        ],
      ],
    );
  }
}

/// Card de progresso do usuário, visualmente destacado (fundo elevado +
/// borda dourada sutil) do restante da lista de territórios — achado
/// real do redesign: antes tudo tinha o mesmo peso visual, sem
/// hierarquia de importância entre "seu progresso" e "os territórios".
/// Foto de perfil clicável ao lado do nome (pedido de Rhoney, 26/08 e
/// 27/08/2026) — abre o Perfil pra editar, mesmo lugar visual onde o
/// nome/foto já aparecem em Amigos/Ranking/Batalhas (USER_PROFILE.md §4).
///
/// O nível NÃO é repetido aqui — `XpBar` abaixo já renderiza "Nível $level"
/// internamente; um `Text(l10n.levelLabel(level))` extra neste Row
/// duplicava o texto (achado real de validação em dispositivo, 26/08/2026).
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.photoUrl,
    required this.realName,
    required this.l10n,
    required this.onTapPhoto,
  });

  final Map<String, dynamic> progress;
  final String? photoUrl;
  final String? realName;
  final AppLocalizations l10n;
  final VoidCallback onTapPhoto;

  @override
  Widget build(BuildContext context) {
    final level = progress['level'] as int;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: onTapPhoto,
                child: ProfilePhotoCircle(photoUrl: photoUrl, size: 48),
              ),
              const SizedBox(width: 12),
              if (realName != null && realName!.isNotEmpty)
                Expanded(
                  child: Text(
                    realName!,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          XpBar(xpTotal: progress['xp_total'] as int, level: level),
          const SizedBox(height: 12),
          Text(
            l10n.progressSummary(
              progress['xp_total'] as int,
              level,
              progress['streak']['current_streak'] as int,
            ),
            style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
