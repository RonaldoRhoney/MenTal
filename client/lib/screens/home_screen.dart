import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/movement_service.dart';
import '../services/theme_mode_service.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import '../widgets/mentalcoin.dart';
import '../widgets/profile_photo.dart';
import '../widgets/pulse_in.dart';
import 'battles_screen.dart';
import 'profile_screen.dart';
import 'challenge_screen.dart';
import 'feedback_screen.dart';
import 'friends_screen.dart';
import 'mentalcoins_screen.dart';
import 'movement_screen.dart';
import 'progress_screen.dart';
import 'ranking_screen.dart';
import 'settings_screen.dart';
import 'word_search_screen.dart';

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

  // MentalCoins (U.I/MENTALCOINS_V1.md) — reforço visual de gamificação
  // pedido junto do redesign da Home. Falha silenciosa igual ao resto
  // dos indicadores secundários: nunca bloqueia a Home carregar.
  int? _mentalCoinsBalance;

  Future<void> _loadMentalCoinsBalance() async {
    try {
      final balance = await widget.client.getMentalCoinsBalance();
      if (mounted) setState(() => _mentalCoinsBalance = balance['balance'] as int);
    } on ApiException catch (_) {}
  }

  Future<void> _openMentalCoins() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MentalCoinsScreen(client: widget.client)),
    );
    _loadMentalCoinsBalance();
  }

  // V2 item 9 — badge de passos ainda não coletados junto ao ícone de
  // Movimento (decisão de Rhoney, 2026-08-21: "catch-up ao reabrir o
  // app", nunca serviço em segundo plano com notificação fixa). Mostra
  // o valor certo assim que a Home carrega, usando a última leitura
  // conhecida do sensor de QUALQUER sessão — não espera um evento novo.
  int? _movementPendingSteps;
  String? _movementCycleId;
  StreamSubscription<int>? _movementStepSub;
  // Alerta sutil de bônus acumulado (29/08/2026, pedido de Rhoney):
  // nada se perde enquanto não coletado — passos do ciclo atual ficam
  // guardados localmente (MovementService) e o ciclo anterior fica
  // reservado dentro da janela de graça (MOVEMENT_COLLECTION_GRACE_
  // HOURS, backend) — isso só formaliza um convite visual pra vir
  // coletar, sem mudar nenhuma regra de acúmulo que já existia.
  bool _movementHasPendingCycle = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadMovementBadge();
    _loadProfileHeader();
    _loadMentalCoinsBalance();
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
      final hasPendingCycle = status['pending_report_cycle'] != null;
      if (mounted) setState(() => _movementHasPendingCycle = hasPendingCycle);
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
              // splash/login (BRAND.md). Único ícone de utilidade
              // permitido aqui (29/08/2026, pedido de Rhoney): alternar
              // claro/escuro — fica no canto pra não competir com o
              // wordmark centralizado.
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      Text(l10n.homeTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.displaySmall),
                      const SizedBox(height: 4),
                      Text(
                        l10n.loginSlogan,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: _ThemeModeToggleButton(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if ((_movementPendingSteps ?? 0) > 0 || _movementHasPendingCycle) ...[
                _MovementBonusAlert(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => MovementScreen(client: widget.client)),
                    );
                    _loadMovementBadge();
                  },
                ),
                const SizedBox(height: 12),
              ],
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
                  mentalCoinsBalance: _mentalCoinsBalance,
                  l10n: l10n,
                  onTapPhoto: _openProfile,
                  onTapMentalCoins: _openMentalCoins,
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 16),
              Expanded(
                // Achado real (29/08/2026, pedido de Rhoney: "há um
                // estouro de todo conteúdo na tela e depois a tela
                // aparece como deve ser"): antes de `_progress` chegar,
                // _buildWorldSections caía no fallback de "sem mundos"
                // e desenhava os 10 territórios soltos, sem agrupar nem
                // colapsar — um frame inteiro de conteúdo bruto antes
                // do layout final (Mundos colapsados) assumir. Mostrar
                // o spinner enquanto progress==null evita esse flash.
                child: progress == null
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(children: _buildWorldSections(l10n)),
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

/// Alerta sutil de bônus acumulado (29/08/2026, pedido de Rhoney):
/// "colete seus bônus..." — nunca bloqueia nem perde nada (o acúmulo já
/// existia: passos do ciclo atual ficam guardados localmente, o ciclo
/// anterior fica reservado dentro da janela de graça no backend), só
/// avisa visualmente que existe algo esperando. PulseIn com
/// intensidade baixa (0.15, mesma usada em outros reforços "sutis" do
/// app) em vez de qualquer animação chamativa.
class _MovementBonusAlert extends StatelessWidget {
  const _MovementBonusAlert({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PulseIn(
      intensity: 0.15,
      child: Material(
        color: AppColors.gold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.gold.withValues(alpha: 0.35))),
            child: Row(
              children: [
                Icon(Icons.redeem_rounded, color: AppColors.gold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.movementBonusAlertMessage,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.gold.withValues(alpha: 0.7), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de alternância claro/escuro (29/08/2026, pedido de Rhoney: "na
/// parte superior") — ListenableBuilder próprio, isolado do resto da
/// Home: só este ícone precisa saber o tom atual pra escolher sol/lua,
/// o resto da tela já reconstrói sozinho via main.dart quando o toggle
/// dispara (ThemeModeService.instance).
class _ThemeModeToggleButton extends StatelessWidget {
  const _ThemeModeToggleButton();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeModeService.instance,
      builder: (context, _) {
        final isDark = ThemeModeService.instance.isDark;
        return IconButton(
          tooltip: isDark ? 'Ativar tom claro' : 'Ativar tom escuro',
          onPressed: () => ThemeModeService.instance.toggle(),
          icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded, color: AppColors.gold),
        );
      },
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          // Destaque de borda na cor do ícone (29/08/2026, pedido de
          // Rhoney: "estão dimidamente quase na mesma tonalidade do
          // fundo") — o card sozinho (bg2) quase não se distinguia do
          // fundo da tela (bg); a borda colorida dá contorno próprio.
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.4))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: (badgeCount ?? 0) > 0,
                label: Text('$badgeCount'),
                child: Icon(icon, color: color, size: 28),
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
                // Cor clara (bone) em vez do "muted" padrão do
                // bodySmall (29/08/2026) — o cinza discreto ficava
                // quase invisível contra o fundo escuro.
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.bone, fontWeight: FontWeight.w600, fontSize: 12, height: 1.15),
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
    // Destaque leve quando o Mundo está 100% concluído (29/08/2026,
    // pedido de Rhoney) — só decorativo, nunca trava: o jogador pode
    // refazer os territórios do Mundo quantas vezes quiser, o card
    // simplesmente reflete "já bati esse Mundo" com uma borda dourada
    // sutil, além do check que já existia no título.
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.bg2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: completed ? AppColors.gold.withValues(alpha: 0.35) : Colors.transparent),
        ),
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
                        Icon(Icons.check_circle, color: AppColors.gold, size: 20),
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
    // Cor de progresso do território (29/08/2026, pedido de Rhoney): em
    // vez de um check quando "conquistado", card e botão Relâmpago vão
    // de vermelho suave (recém-começado) a verde (100% da conquista) —
    // mesma métrica de xp_in_territory/conquest_threshold já usada em
    // progress_screen.dart. AppColors.error já é terracota, não vermelho
    // vivo (Princípio de Não-Humilhação, DESIGN_SYSTEM.md §1), então o
    // "vermelho leve" pedido já é o próprio tom padrão de erro do app.
    final xpInTerritory = progress?['xp_in_territory'] as int? ?? 0;
    final conquestThreshold = progress?['conquest_threshold'] as int? ?? 200;
    final progressFraction = (xpInTerritory / conquestThreshold).clamp(0.0, 1.0);
    final progressColor = Color.lerp(AppColors.error, AppColors.victory, progressFraction)!;
    // V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md). Sempre
    // relativo a você + amigos confirmados (nunca global) — o backend
    // já filtra isso, a Home só exibe o que vem pronto.
    final detentorNickname = progress?['detentor_nickname'] as String?;
    final isDetentor = progress?['is_detentor'] as bool? ?? false;

    // V3.3 §6 (Jogos de Palavras — Fase 1: Caça-palavras). Estrutura de
    // jogo própria (grade, não pergunta+alternativas) — nunca abre
    // ChallengeScreen, e não tem modo Relâmpago (não existe timer/nível
    // adaptativo por resposta individual nesse formato).
    if (territoryId == 'caca_palavras') {
      return Material(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => WordSearchScreen(client: client, territoryId: territoryId, territoryLabel: label)),
            );
            onReturned();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: progressColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    l10n.newChallengeButton(label),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pedido de Rhoney (29/08/2026): "eles devem seguir as mesmas
        // formatação do menu pai" — antes era um FilledButton dourado
        // sólido, visualmente destoante do card do Mundo (fundo bg2 +
        // borda sutil). Agora usa a MESMA linguagem visual (fundo bg2,
        // cantos arredondados, borda com destaque suave — mais forte em
        // dourado quando já conquistado), consistente também com os
        // cards de recompensa do MentalCoins.
        Material(
          color: AppColors.bg2,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChallengeScreen(client: client, territoryId: territoryId, territoryLabel: label),
                ),
              );
              onReturned();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: progressColor.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pedido de Rhoney (29/08/2026): "Desafio X" numa linha
                  // só, nunca quebrando a palavra — FittedBox encolhe a
                  // fonte automaticamente quando o nome do território é
                  // mais longo (ex.: "Cultura Pop"), em vez de arriscar
                  // uma quebra de linha no meio da palavra.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      l10n.newChallengeButton(label),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
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
        // V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md),
        // generalizado pra todos os territórios (29/08/2026, pedido de
        // Rhoney: "em todos os módulos tem que haver um relâmpago") —
        // backend já aceita mode=relampago em qualquer território
        // (routers/challenges.py), nunca mais restrito a "palavras".
        const SizedBox(height: 8),
        OutlinedButton(
          style: OutlinedButton.styleFrom(side: BorderSide(color: progressColor.withValues(alpha: 0.6))),
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
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.relampagoModeLabel, textAlign: TextAlign.center, maxLines: 1),
          ),
        ),
      ],
    );
  }
}

/// Card de identidade do usuário (U.I/HOME_REDESIGN_V1.md §3, reajustado
/// 29/08/2026 a pedido de Rhoney: "está tomando muito espaço, diminua de
/// forma a aproveitar todo o card de forma estruturada"). Substitui o
/// avatar grande + XpBar completa + chips separados por uma estrutura de
/// 3 linhas compactas dentro do MESMO card, sem nenhuma informação
/// duplicada: nível vira badge sobre o avatar (não repetido em texto),
/// XP ganha uma linha própria fina, e XP total/Mundos/Streak dividem uma
/// única linha de metadados em vez de cards separados.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.photoUrl,
    required this.realName,
    required this.mentalCoinsBalance,
    required this.l10n,
    required this.onTapPhoto,
    required this.onTapMentalCoins,
  });

  final Map<String, dynamic> progress;
  final String? photoUrl;
  final String? realName;
  final int? mentalCoinsBalance;
  final AppLocalizations l10n;
  final VoidCallback onTapPhoto;
  final VoidCallback onTapMentalCoins;

  static const _xpPerLevel = 100;

  @override
  Widget build(BuildContext context) {
    final level = progress['level'] as int;
    final xpTotal = progress['xp_total'] as int;
    final streakDays = progress['streak']['current_streak'] as int;
    final xpIntoLevel = xpTotal % _xpPerLevel;
    final fraction = (xpIntoLevel / _xpPerLevel).clamp(0.0, 1.0);
    final worlds = (progress['worlds'] as List?)?.cast<Map<String, dynamic>>();
    final worldsCompleted = worlds?.where((w) => w['completed'] as bool).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bg2, Color.lerp(AppColors.bg2, AppColors.purple, 0.08)!],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTapPhoto,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProfilePhotoCircle(photoUrl: photoUrl, size: 44, highlighted: true),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.teal,
                          border: Border.all(color: AppColors.bg2, width: 2),
                        ),
                        child: Text('$level', style: AppTheme.technicalStyle(color: AppColors.bg, fontSize: 10).copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (realName != null && realName!.isNotEmpty)
                      Text(realName!, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis, maxLines: 1),
                    Text('Nível $level', style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTapMentalCoins,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MentalCoin(size: 18),
                      const SizedBox(width: 6),
                      Text('${mentalCoinsBalance ?? 0}', style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 13).copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 8,
                    child: Stack(
                      children: [
                        Container(color: AppColors.bg),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: fraction),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => FractionallySizedBox(
                            widthFactor: value,
                            child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.victory, AppColors.purple, AppColors.gold]))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$xpIntoLevel/$_xpPerLevel XP', style: AppTheme.technicalStyle(color: AppColors.muted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _MetaStat(icon: Icons.bolt_rounded, color: AppColors.gold, value: '$xpTotal', label: 'XP total')),
              Expanded(child: _MetaStat(icon: Icons.public_rounded, color: AppColors.purple, value: worldsCompleted != null ? '$worldsCompleted/${worlds!.length}' : '—', label: 'Mundos')),
              Expanded(child: _MetaStat(icon: Icons.local_fire_department_rounded, color: AppColors.victory, value: '$streakDays', label: l10n.streakSectionTitle)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Uma coluna da linha de metadados (XP total / Mundos / Streak) — pedido
/// de Rhoney (29/08/2026): "estão muito sóbrios e sem vida, o app precisa
/// passar uma sensação de emoção" — cada métrica ganha ícone + cor própria
/// (dourado/roxo/verde-vitória, mesma paleta de gamificação já usada no
/// resto do card) e o valor cresce de tamanho, em vez de tudo em
/// texto monocromático neutro.
class _MetaStat extends StatelessWidget {
  const _MetaStat({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    // Centralizado (29/08/2026, pedido de Rhoney: "os números abaixo de
    // XP TOTAL, MUNDOS E SEQUÊNCIA devem ficar bem no centro de cada
    // palavra") — antes cada linha (label e valor) só encolhia pro
    // próprio conteúdo (mainAxisSize.min + crossAxisAlignment.start),
    // então o valor nunca alinhava embaixo do centro do rótulo quando os
    // dois tinham larguras diferentes.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 3),
            // Bone em vez de muted (29/08/2026, pedido de Rhoney: "estão
            // dimidamente quase na mesma tonalidade do fundo") — rótulo
            // pequeno já era proposital, mas precisa de contraste real
            // pra ser lido, não só tamanho reduzido.
            Text(label.toUpperCase(), style: AppTheme.technicalStyle(color: AppColors.bone, fontSize: 10).copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        Text(value, style: AppTheme.technicalStyle(color: color, fontSize: 17).copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
