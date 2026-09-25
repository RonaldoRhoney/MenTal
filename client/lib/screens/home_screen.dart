import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_version_service.dart';
import '../services/feed_activity_service.dart';
import '../services/movement_service.dart';
import '../territories.dart';
import '../theme/agent_neon.dart';
import '../theme/app_theme.dart';
import '../widgets/mentalcoin.dart';
import '../widgets/profile_photo.dart';
import '../widgets/update_available_dialog.dart';
import 'battles_screen.dart';
import 'profile_screen.dart';
import 'challenge_screen.dart';
import 'coach_screen.dart';
import 'mental_lingo_screen.dart';
import 'feed_screen.dart';
import 'feedback_screen.dart';
import 'friends_screen.dart';
import 'mentalcoins_screen.dart';
import 'movement_screen.dart';
import 'notifications_screen.dart';
import 'trajectory_map_screen.dart';
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

  // MentalCoins (MentalCoins/MENTALCOINS_V1.md) — reforço visual de gamificação
  // pedido junto do redesign da Home. Falha silenciosa igual ao resto
  // dos indicadores secundários: nunca bloqueia a Home carregar.
  int? _mentalCoinsBalance;
  // Fase 3: oferta de reparo de sequência + boost ativo. Reforço visual,
  // falha silenciosa como os demais indicadores secundários.
  Map<String, dynamic>? _economy;
  Future<void> _loadEconomy() async {
    try {
      final economy = await widget.client.getEconomyStatus();
      if (mounted) setState(() => _economy = economy);
    } on ApiException {
      // banner simplesmente não aparece
    }
  }

  Future<void> _loadMentalCoinsBalance() async {
    try {
      final balance = await widget.client.getMentalCoinsBalance();
      if (mounted)
        setState(() => _mentalCoinsBalance = balance['balance'] as int);
    } on ApiException catch (_) {}
  }

  Future<void> _openMentalCoins() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => MentalCoinsScreen(client: widget.client)),
    );
    _loadMentalCoinsBalance();
    _loadEconomy();
  }

  // MAPA_TRAJETORIA_MUNDOS_V1.md (18/09/2026, pedido de Rhoney): o acesso
  // ao mapa muda de um botão dentro de Progresso pra um ícone ao lado do
  // nome do usuário, direto na Home — mais visível, sem precisar entrar
  // em outra tela primeiro.
  void _openTrajectoryMap() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => TrajectoryMapScreen(client: widget.client)),
    );
  }

  // V2 item 9 — badge de passos ainda não coletados junto ao ícone de
  // Movimento (decisão de Rhoney, 2026-08-21: "catch-up ao reabrir o
  // app", nunca serviço em segundo plano com notificação fixa). Mostra
  // o valor certo assim que a Home carrega, usando a última leitura
  // conhecida do sensor de QUALQUER sessão — não espera um evento novo.
  int? _movementPendingSteps;
  String? _movementCycleId;
  StreamSubscription<int>? _movementStepSub;

  // FEED_SOCIAL_V1.md — badge discreto no card "Feed" do grid de
  // atalhos (REORGANIZACAO_MENUS_HOME_V1.md §3, 06/09/2026: Feed ganhou
  // entrada própria na posição liberada pelo card "Mais") — contagem de
  // eventos novos desde a última vez que o jogador abriu a tela de Feed.
  int? _feedUnseenCount;

  Future<void> _loadFeedBadge() async {
    final count = await FeedActivityService.unseenCount(widget.client);
    if (mounted) setState(() => _feedUnseenCount = count);
  }

  // CENTRAL_DE_NOTIFICACOES_HOME_V1.md — sino no canto superior da Home
  // (pedido de Rhoney, 14/09/2026), badge com a contagem de não lidas.
  // Endpoint dedicado e leve (GET /notifications/unread-count), mesmo
  // raciocínio de _loadFeedBadge/_loadBattlesBadge acima.
  int? _unreadNotificationCount;

  Future<void> _loadNotificationBadge() async {
    try {
      final count = await widget.client.getUnreadNotificationCount();
      if (mounted) setState(() => _unreadNotificationCount = count);
    } on ApiException catch (_) {}
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => NotificationsScreen(client: widget.client)),
    );
    _loadNotificationBadge();
  }

  // BATALHAS_INTUITIVAS_E_TEMPO_REAL_V1.md §2.2 — "indicador de 'é a sua
  // vez' bem destacado... na Home ou na barra inferior", pra reduzir a
  // chance de o usuário esquecer que tem uma Batalha pendente. Conta só
  // batalhas com status pending e i_answered==false (minha vez), mesmo
  // critério já usado por BattlesScreen._answer/canAnswer.
  int? _pendingBattlesCount;

  Future<void> _loadBattlesBadge() async {
    try {
      final result = await widget.client.listBattles();
      final battles = (result['battles'] as List).cast<Map<String, dynamic>>();
      final pending = battles
          .where((b) => b['status'] == 'pending' && b['i_answered'] == false)
          .length;
      if (mounted) setState(() => _pendingBattlesCount = pending);
    } on ApiException catch (_) {
      // Badge é reforço visual, mesmo princípio de _loadMovementBadge/
      // _loadFeedBadge acima — nunca bloqueia a Home por causa disso.
    }
  }

  // Busca na Home (pedido de Rhoney, 2026-09-03; estilo revisado
  // 2026-09-03 — "nível profissional", campo de sugestão em destaque em
  // vez de snackbar) — "tema, frase ou palavra" acima de Mundo da
  // Linguagem. _searching evita duplo envio enquanto a busca de frase/
  // palavra está em andamento no backend ("tema" é resolvido localmente,
  // sem rede — nunca passa por aqui). _notFoundQuery != null é o que
  // revela o card "não encontramos / sugerir" logo abaixo do campo;
  // _suggestionSent controla o estado de confirmação dentro do próprio
  // card, sem depender de SnackBar (que desaparece rápido demais pra
  // esse tipo de convite de ação).
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _searching = false;
  String? _notFoundQuery;
  bool _suggestionSending = false;
  bool _suggestionSent = false;

  Future<void> _handleSearch(String rawQuery) async {
    final query = rawQuery.trim();
    if (query.isEmpty || _searching) return;
    final l10n = AppLocalizations.of(context)!;
    FocusScope.of(context).unfocus();
    setState(() => _notFoundQuery = null);

    final themeMatch = findTerritoryIdByThemeQuery(l10n, query);
    if (themeMatch != null) {
      _searchController.clear();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChallengeScreen(
            client: widget.client,
            territoryId: themeMatch,
            territoryLabel: territoryLabel(l10n, themeMatch),
          ),
        ),
      );
      _loadProgress();
      return;
    }

    setState(() => _searching = true);
    try {
      final result = await widget.client.searchChallenges(query);
      if (result['found'] == true) {
        _searchController.clear();
        final challenge = result['challenge'] as Map<String, dynamic>;
        final territoryId = challenge['territory_id'] as String;
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ChallengeScreen(
              client: widget.client,
              territoryId: territoryId,
              territoryLabel: territoryLabel(l10n, territoryId),
              prefetchedChallenge: challenge,
            ),
          ),
        );
        _loadProgress();
        return;
      }
      if (mounted) {
        setState(() {
          _notFoundQuery = query;
          _suggestionSent = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _submitContentSuggestion(String query) async {
    setState(() => _suggestionSending = true);
    try {
      await widget.client.submitContentSuggestion(query);
      if (mounted) setState(() => _suggestionSent = true);
      // Pedido de Rhoney (2026-09-03): o card não deve ficar preso na
      // tela esperando um toque manual no X — some sozinho pouco depois
      // da confirmação, tempo suficiente só pra o texto "Sugestão
      // registrada!" ser lido.
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted && _notFoundQuery == query)
        setState(() => _notFoundQuery = null);
    } on ApiException catch (_) {
      // Sugestão é reforço opcional — falha ao registrar não pode
      // quebrar o fluxo de busca já concluído (mesmo princípio de
      // ShareService/_shareApp acima). O card simplesmente fecha, sem
      // culpar o usuário por um problema de rede que não é dele.
      if (mounted) setState(() => _notFoundQuery = null);
    } finally {
      if (mounted) setState(() => _suggestionSending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadMovementBadge();
    _loadProfileHeader();
    _loadMentalCoinsBalance();
    _loadEconomy();
    _loadFeedBadge();
    _loadBattlesBadge();
    _loadNotificationBadge();
    _checkAppVersion();
  }

  // SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md §2 (05/09/2026) — checado
  // uma vez por abertura do app (Home é a tela de entrada), nunca a
  // cada pull-to-refresh (não faz parte de _refreshAll de propósito,
  // pra não repetir o aviso toda vez que o usuário atualiza a tela).
  Future<void> _checkAppVersion() async {
    final result = await AppVersionService.check(widget.client);
    if (!mounted || result.status == AppUpdateStatus.upToDate) return;
    showUpdateAvailableDialog(context,
        required: result.status == AppUpdateStatus.updateRequired);
  }

  // Pedido de Rhoney (04/09/2026): "pull to refresh" em qualquer tela do
  // app — puxar a tela pra baixo atualiza o conteúdo. Home tem 4 fontes
  // de dado carregadas separadamente (progresso, badge de Movimento,
  // cabeçalho de perfil, saldo de MentalCoins); refresh combinado
  // dispara todas em paralelo, igual ao initState.
  Future<void> _refreshAll() {
    return Future.wait([
      _loadProgress(),
      _loadMovementBadge(),
      _loadProfileHeader(),
      _loadMentalCoinsBalance(),
      _loadEconomy(),
      _loadFeedBadge(),
      _loadBattlesBadge(),
      _loadNotificationBadge(),
    ]);
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
    _searchController.dispose();
    _searchFocusNode.dispose();
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
      unawaited(MovementService.instance.updateNotificationPreview(
        stepsCollected: cycle['steps_collected'] as int,
        xpAwarded: cycle['xp_awarded'] as int,
      ));
      await MovementService.instance.ensureBaselineFor(cycleId);
      final cachedLast = await MovementService.instance.lastKnownRawSteps();
      if (cachedLast != null) {
        final delta =
            await MovementService.instance.pendingDeltaFor(cycleId, cachedLast);
        if (mounted)
          setState(() => _movementPendingSteps = delta.uncollectedSteps);
      }

      if (_movementCycleId != cycleId) {
        _movementCycleId = cycleId;
        _movementStepSub?.cancel();
        _movementStepSub =
            MovementService.instance.stepCountStream().listen((steps) async {
          final delta =
              await MovementService.instance.pendingDeltaFor(cycleId, steps);
          if (mounted)
            setState(() => _movementPendingSteps = delta.uncollectedSteps);
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
  Map<String, ({String id, String name})> _blockNameByTerritory() {
    final blocks =
        (_progress?['blocks'] as List?)?.cast<Map<String, dynamic>>();
    if (blocks == null) return const {};
    final map = <String, ({String id, String name})>{};
    for (final block in blocks) {
      final id = block['block_id'] as String;
      final name = block['name'] as String;
      for (final territoryId
          in (block['territory_ids'] as List).cast<String>()) {
        map[territoryId] = (id: id, name: name);
      }
    }
    return map;
  }

  // V2 item 10 — Mundos completos. O backend é a autoridade sobre o
  // agrupamento (GET /progress já devolve os territórios de cada mundo
  // e se está completo) — a Home só organiza visualmente, nunca decide
  // sozinha quais territórios pertencem a qual mundo.
  //
  /// REORGANIZACAO_MENUS_HOME_V1.md §5/§7/§8 (06/09/2026): substitui a
  /// lista vertical de Mundos (ExpansionTile empilhados, exigia rolagem
  /// extensa) por um carrossel horizontal compacto — critério de aceite
  /// §8 explícito: "Lista de Mundos não obriga mais rolagem vertical
  /// extensa pra ser vista por completo". Cada card abre uma tela
  /// dedicada com os territórios daquele Mundo (_WorldDetailScreen),
  /// nunca expande in-place (decisão tomada com Rhoney: manter a Home
  /// enxuta, sem nada crescendo embaixo do carrossel).
  /// Fase 3: cartão de reparo de sequência (quando há). O chip de boost
  /// ativo saiu da Home (pedido de Rhoney, 23/09/2026: "remova o Boost da
  /// tela... deve aparecer como notificação, no botão notificação" — a
  /// Home estava poluída) e virou uma notificação na Central (sino),
  /// disparada no servidor em POST /economy/xp-boost (ver routers/economy.py).
  Widget _buildEconomyBanner(AppLocalizations l10n) {
    final e = _economy;
    if (e == null) return const SizedBox.shrink();
    final repair = e['repair'] as Map<String, dynamic>?;
    if (repair == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            key: const Key('home_repair_banner'),
            borderRadius: BorderRadius.circular(14),
            onTap: _openMentalCoins,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.5))),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: AppColors.gold),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.homeStreakRepairBanner(
                        repair['streak_to_restore'] as int,
                        repair['cost'] as int,
                        () {
                          final p = (repair['expires_on'] as String).split('-');
                          return '${p[2]}/${p[1]}';
                        }(),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(l10n.homeStreakRepairBannerAction,
                      style: TextStyle(
                          color: AppColors.gold, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldCarousel(AppLocalizations l10n) {
    final worlds =
        (_progress?['worlds'] as List?)?.cast<Map<String, dynamic>>();
    final blockNameByTerritory = _blockNameByTerritory();

    final items = worlds == null || worlds.isEmpty
        ? <_WorldCarouselItem>[
            (
              title: l10n.homeAllTerritoriesFallbackLabel,
              icon: Icons.travel_explore_rounded,
              completed: false,
              territoryIds: kTerritoryIds,
              worldId: null,
            ),
          ]
        : [
            for (final world in worlds)
              (
                title: world['name'] as String,
                icon: _worldIcon(world['world_id'] as String),
                completed: world['completed'] as bool,
                territoryIds: (world['territory_ids'] as List).cast<String>(),
                worldId: world['world_id'] as String?,
              ),
          ];

    return _WorldCarousel(
      items: items,
      shortTitle: _shortWorldTitle,
      onTapItem: (item) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _WorldDetailScreen(
              title: item.title,
              worldId: item.worldId,
              completed: item.completed,
              client: widget.client,
              refreshProgress: _loadProgress,
              buildChildren: (onReturned) => _territoryGroups(
                l10n,
                item.territoryIds,
                blockNameByTerritory,
                onReturned: onReturned,
              ),
            ),
          ),
        );
        _loadProgress();
      },
    );
  }

  /// Achado real testando no dispositivo (06/09/2026): o nome completo
  /// ("Mundo da Linguagem", "Mundo da Mente Lógica"...) não cabe em 2
  /// linhas num card de carrossel estreito — cortava no meio da palavra
  /// ("Mundo da Linguag..."). O prefixo "Mundo da/do/dos" é redundante
  /// dentro de um carrossel que já É a lista de Mundos, então só o card
  /// (nunca o nome usado em `_WorldDetailScreen`, Progresso ou qualquer
  /// outro lugar) mostra a versão curta.
  String _shortWorldTitle(String title) {
    // "Mundo Acima de Nós (Espaço)" (07/09/2026) não segue o padrão
    // "Mundo da/do/dos" — sem este caso especial, o card do carrossel
    // mostraria o nome completo, comprido demais pra caber sem
    // quebrar feio (mesmo achado real já documentado nos outros casos
    // abaixo).
    if (title == 'Mundo Acima de Nós (Espaço)') return 'Espaço';
    const prefixes = ['Mundo da ', 'Mundo do ', 'Mundo dos ', 'Mundo das '];
    for (final prefix in prefixes) {
      if (title.startsWith(prefix)) return title.substring(prefix.length);
    }
    return title;
  }

  /// Ícone de identidade por Mundo (novo no carrossel — a lista vertical
  /// anterior não precisava disso, só o nome). Mundo desconhecido (ainda
  /// não lançado no client, ex.: Gastronomia/Oceanos/Espaço em curadoria)
  /// cai num ícone genérico de "explorar", nunca quebra o carrossel.
  IconData _worldIcon(String worldId) {
    switch (worldId) {
      case 'linguagem':
        return Icons.menu_book_rounded;
      case 'mente_logica':
        return Icons.psychology_rounded;
      case 'cultura_geral':
        return Icons.public_rounded;
      case 'descoberta':
        return Icons.explore_rounded;
      case 'idiomas':
        return Icons.translate_rounded;
      case 'valores':
        return Icons.volunteer_activism_rounded;
      case 'transito':
        return Icons.traffic_rounded;
      // DESMEMBRAMENTO_CULTURA_GERAL_V1.md (07/09/2026).
      case 'esportes':
        return Icons.sports_soccer_rounded;
      case 'mitologia':
        return Icons.castle_rounded;
      case 'enem':
        return Icons.school_rounded;
      case 'concursos':
        return Icons.gavel_rounded;
      case 'tecnologia':
        return Icons.memory_rounded;
      case 'regioes_brasil':
        return Icons.map_rounded;
      case 'gastronomia':
        return Icons.restaurant_rounded;
      case 'oceanos':
        return Icons.waves_rounded;
      case 'espaco':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.travel_explore_rounded;
    }
  }

  /// Agrupa territórios consecutivos do mesmo bloco (ou sem bloco) numa
  /// mesma "linha" de grid — cada grupo vira um título opcional (nome do
  /// bloco) seguido de um Wrap em 2 colunas com os cards de território
  /// daquele grupo. `onReturned` sobrepõe o padrão (`_loadProgress`,
  /// que só atualiza o estado da Home) quando os cards são exibidos
  /// dentro de `_WorldDetailScreen` — lá o retorno de um desafio
  /// precisa, além de atualizar a Home por baixo, reconstruir a própria
  /// tela empilhada, senão a barra de progresso do território ficaria
  /// visualmente desatualizada até o jogador voltar pra Home e reabrir
  /// o Mundo.
  List<Widget> _territoryGroups(
    AppLocalizations l10n,
    List<String> territoryIds,
    Map<String, ({String id, String name})> blockNameByTerritory, {
    VoidCallback? onReturned,
  }) {
    final groups = <Widget>[];
    ({String id, String name})? currentBlock;
    List<String> currentIds = [];

    void flush() {
      if (currentIds.isEmpty) return;
      groups.add(
        _TerritoryGroup(
          blockId: currentBlock?.id,
          blockName: currentBlock?.name,
          territoryIds: List.of(currentIds),
          l10n: l10n,
          territoryProgressOf: _territoryProgress,
          client: widget.client,
          onReturned: onReturned ?? _loadProgress,
        ),
      );
      currentIds = [];
    }

    for (final territoryId in territoryIds) {
      final block = blockNameByTerritory[territoryId];
      if (block != currentBlock) {
        flush();
        currentBlock = block;
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
        child: Stack(
          children: [
            // HOME_REDESIGN_V2_MINIMALISMO.md §3.1 — "MENTAL" some como
            // bloco de texto de destaque (já aparece na Splash, repetir
            // aqui era redundância pura) e vira marca d'água: opacidade
            // muito baixa, camada de fundo, NUNCA recebe toque
            // (IgnorePointer) — os cards acima continuam 100% clicáveis.
            const Positioned.fill(child: _MentalWatermark()),
            // CENTRAL_DE_NOTIFICACOES_HOME_V1.md — "botão na Home... no
            // canto" (pedido de Rhoney, 14/09/2026): fixo no canto
            // superior direito, sempre visível independente da rolagem
            // (Positioned dentro do mesmo Stack do watermark, por cima
            // do conteúdo rolável).
            Positioned(
              top: 4,
              right: 8,
              child: IconButton(
                tooltip: l10n.notificationsBellTooltip,
                onPressed: _openNotifications,
                icon: Badge(
                  isLabelVisible: (_unreadNotificationCount ?? 0) > 0,
                  label: Text('$_unreadNotificationCount'),
                  child: const Icon(Icons.notifications_rounded),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              // REORGANIZACAO_MENUS_HOME_V1.md §5/§8 (06/09/2026): a
              // lista de Mundos virou um carrossel horizontal de altura
              // fixa (não mais Expanded+ListView próprio) — a página
              // inteira agora é UMA única área rolável (pull-to-refresh
              // continua funcionando, RefreshIndicator só precisa de
              // algum Scrollable descendente, não importa qual).
              //
              // Achado real testando no dispositivo (06/09/2026): sem o
              // Expanded de antes preenchendo o resto da tela, sobrava um
              // vão vazio grande entre o carrossel e a bottom nav em
              // telas altas. LayoutBuilder + ConstrainedBox(minHeight)
              // + Column centralizada resolve isso — quando o conteúdo é
              // mais baixo que a tela, distribui o espaço sobrando de
              // forma equilibrada (em vez de jogar tudo pro rodapé);
              // quando o conteúdo cresce (mais Mundos, erro visível
              // etc.) e passa da altura da tela, volta a rolar
              // normalmente, sem cortar nada.
              child: RefreshIndicator(
                onRefresh: _refreshAll,
                color: AppColors.gold,
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          // Pedido de Rhoney (06/09/2026): com a Home
                          // ganhando espaço vertical sobrando (§5/§8 do
                          // carrossel de Mundos), volta a mostrar o
                          // wordmark + slogan no topo — mesmo texto e
                          // estilo do Login (l10n.loginTitle/loginSlogan),
                          // pra manter uma única fonte de verdade da marca
                          // (BRAND.md §1: o nome nunca aparece sozinho, sem
                          // o slogan por perto). Diferente da marca d'água
                          // de fundo (_MentalWatermark, sempre presente,
                          // opacidade baixíssima), este é um bloco de
                          // texto normal, visível, no fluxo do conteúdo.
                          Text(
                            l10n.loginTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.loginSlogan,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: 10),
                          // Pedido de Rhoney (23/09/2026, revisado no mesmo
                          // dia: "deixe-o profissional, ajuste melhor o
                          // design"): a dica do My_Mental_AI saiu da Home
                          // como card (poluía a tela) — só o NOME fica no
                          // topo, clicável, abrindo a CoachScreen (dicas
                          // gerais). Selo compacto (não um botão genérico
                          // nem texto solto), mesma linguagem visual dos
                          // cartões do app (borda de acento sobre bg2), pra
                          // ler como identidade do agente, não como aviso.
                          // Dica focada por Mundo mora dentro de cada Mundo
                          // (_WorldDetailScreen).
                          Align(
                            alignment: Alignment.center,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                key: const Key('home_coach_name'),
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) => CoachScreen(
                                            client: widget.client))),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                      6, 6, 14, 6),
                                  decoration: agentNeonDecoration(radius: 24),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: kAgentNavy,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: kAgentCyan, width: 1.5),
                                        ),
                                        child: const Icon(
                                            Icons.auto_awesome_rounded,
                                            size: 12,
                                            color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      const AgentNameText(fontSize: 12.5),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.chevron_right_rounded,
                                          size: 16, color: kAgentCyan),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // §3.3 — grid de 5 cards (Progresso/Ranking/Amigos/
                          // Movimento/Feed), todos com o mesmo tamanho.
                          // REORGANIZACAO_MENUS_HOME_V1.md (06/09/2026): o 5º
                          // card era "Mais" (compartilhar+tema, agora dentro
                          // de Ajuste) — vira o Feed, que ganha entrada
                          // própria em vez de só um ícone dentro de Amigos.
                          _QuickActionsRow(
                            client: widget.client,
                            movementPendingSteps: _movementPendingSteps,
                            feedUnseenCount: _feedUnseenCount,
                            onReturnFromProgress: _loadProgress,
                            onReturnFromMovement: _loadMovementBadge,
                            onReturnFromFeed: _loadFeedBadge,
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
                              onTapTrajectoryMap: _openTrajectoryMap,
                            ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: TextStyle(color: AppColors.error)),
                          ],
                          const SizedBox(height: 16),
                          // Busca na Home (pedido de Rhoney, 2026-09-03; estilo
                          // revisado 2026-09-03 — "nível profissional, com o devido
                          // destaque") — "acima de Mundo da Linguagem", logo antes
                          // da lista de Mundos. Mesma linguagem visual dos cards de
                          // atalho (_QuickActionCard) abaixo: fundo bg2, cantos bem
                          // arredondados, borda de destaque na cor de acento — aqui
                          // dourado, por ser uma ação de "descobrir/encontrar algo
                          // novo", distinta do teal usado nos atalhos de navegação.
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.bg2.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color:
                                      AppColors.gold.withValues(alpha: 0.45)),
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: _handleSearch,
                              style: TextStyle(color: AppColors.bone),
                              decoration: InputDecoration(
                                hintText: l10n.homeSearchHint,
                                hintStyle: TextStyle(color: AppColors.muted),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                prefixIcon: Icon(Icons.search_rounded,
                                    color: AppColors.gold),
                                suffixIcon: _searching
                                    ? Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.gold),
                                        ),
                                      )
                                    : AnimatedBuilder(
                                        animation: _searchController,
                                        builder: (context, _) =>
                                            _searchController.text.isEmpty
                                                ? IconButton(
                                                    icon: Icon(
                                                        Icons
                                                            .arrow_forward_rounded,
                                                        color: AppColors.gold),
                                                    onPressed: () =>
                                                        _handleSearch(
                                                            _searchController
                                                                .text),
                                                  )
                                                : IconButton(
                                                    icon: Icon(
                                                        Icons.close_rounded,
                                                        color: AppColors.muted),
                                                    onPressed: () {
                                                      _searchController.clear();
                                                      setState(() =>
                                                          _notFoundQuery =
                                                              null);
                                                    },
                                                  ),
                                      ),
                              ),
                            ),
                          ),
                          // "Não encontramos / sugerir esse conteúdo" — card em
                          // destaque em vez de SnackBar (pedido de Rhoney, revisão
                          // 2026-09-03): um SnackBar some rápido demais pra um
                          // convite de ação que exige leitura + decisão; o card fica
                          // até o usuário decidir (sugerir, fechar, ou buscar de
                          // novo, que já limpa o estado em _handleSearch).
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: _notFoundQuery == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: _ContentSuggestionCard(
                                      query: _notFoundQuery!,
                                      sending: _suggestionSending,
                                      sent: _suggestionSent,
                                      onSuggest: () => _submitContentSuggestion(
                                          _notFoundQuery!),
                                      onDismiss: () =>
                                          setState(() => _notFoundQuery = null),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 16),
                          // Achado real (29/08/2026, pedido de Rhoney: "há um
                          // estouro de todo conteúdo na tela e depois a tela
                          // aparece como deve ser"): antes de `_progress` chegar,
                          // o carrossel cairia no fallback de "sem mundos" —
                          // mostrar o spinner enquanto progress==null evita esse
                          // flash de conteúdo bruto antes do layout final assumir.
                          progress == null
                              ? const Padding(
                                  padding: EdgeInsets.only(top: 40),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              : Column(
                                  children: [
                                    _buildEconomyBanner(l10n),
                                    _buildWorldCarousel(l10n),
                                  ],
                                ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                MaterialPageRoute(
                    builder: (_) => SettingsScreen(client: widget.client)),
              );
            case 3:
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => BattlesScreen(client: widget.client)),
              );
              _loadBattlesBadge();
            case 4:
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => FeedbackScreen(client: widget.client)),
              );
          }
        },
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_rounded), label: l10n.homeNavLabel),
          NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              label: l10n.profileTooltip),
          NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              label: l10n.settingsTooltip),
          NavigationDestination(
              icon: Badge(
                isLabelVisible: (_pendingBattlesCount ?? 0) > 0,
                label: Text('$_pendingBattlesCount'),
                child: const Icon(Icons.sports_martial_arts_outlined),
              ),
              label: l10n.battlesTooltip),
          NavigationDestination(
              icon: const Icon(Icons.feedback_outlined),
              label: l10n.feedbackMenuTooltip),
        ],
      ),
    );
  }
}

/// HOME_REDESIGN_V2_MINIMALISMO.md §3.1 — "MENTAL" como textura de
/// fundo em vez de bloco de texto de destaque (já redundante com a
/// Splash). IgnorePointer garante que esta camada NUNCA intercepta
/// toque, mesmo cobrindo a tela inteira (Positioned.fill no chamador) —
/// os cards acima continuam 100% clicáveis. Opacidade ~4.5% e rotação
/// leve, mesmos valores do protótipo validado (mental-home-v3-
/// watermark.html).
class _MentalWatermark extends StatelessWidget {
  const _MentalWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Center(
          child: Transform.rotate(
            angle: -12 * math.pi / 180,
            child: Text(
              'MENTAL',
              style: GoogleFonts.fraunces(
                fontSize: 96,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: AppColors.gold.withValues(alpha: 0.045),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// HOME_REDESIGN_V2_MINIMALISMO.md §3.2 — o banner "Colete seus bônus
/// de Movimento" saiu da Home (removido daqui, 03/09/2026): o badge
/// numérico no ícone de Movimento do grid de atalhos já sinaliza "há
/// algo pendente aqui", e a tela Movimento já tem seu próprio chip de
/// ciclo pendente (movement_screen.dart) — nenhum lugar fica sem aviso.

/// Acessos rápidos a Progresso/Ranking/Amigos/Movimento — pedido de
/// Rhoney (2026-08-26): "de forma mais dinâmica e com melhor
/// usabilidade" do que ícones pequenos de bottom nav. Cards quadrados
/// com ícone + label, cor de destaque própria por ação (evita o "tudo
/// igual" que motivou o redesign inteiro).
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.client,
    required this.movementPendingSteps,
    required this.feedUnseenCount,
    required this.onReturnFromProgress,
    required this.onReturnFromMovement,
    required this.onReturnFromFeed,
  });

  final ApiClient client;
  final int? movementPendingSteps;
  final int? feedUnseenCount;
  final VoidCallback onReturnFromProgress;
  final VoidCallback onReturnFromMovement;
  final VoidCallback onReturnFromFeed;

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
                MaterialPageRoute(
                    builder: (_) => ProgressScreen(client: client)),
              );
              onReturnFromProgress();
            },
          ),
        ),
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
        Expanded(
          child: _QuickActionCard(
            icon: Icons.directions_walk_rounded,
            label: l10n.movementTooltip,
            color: AppColors.gold,
            badgeCount: movementPendingSteps,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => MovementScreen(client: client)),
              );
              onReturnFromMovement();
            },
          ),
        ),
        const SizedBox(width: 8),
        // REORGANIZACAO_MENUS_HOME_V1.md §3 (06/09/2026): 5º card deixa
        // de ser "Mais" (compartilhar+tema, movidos pro Ajuste, §2) e
        // passa a ser o Feed — ganha entrada própria e visível na
        // navegação principal, sem precisar mais ser descoberto por
        // acaso (antes só existia como ícone dentro de Amigos).
        Expanded(
          child: _QuickActionCard(
            icon: Icons.dynamic_feed_rounded,
            label: l10n.feedScreenTitle,
            color: AppColors.purple,
            badgeCount: feedUnseenCount,
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => FeedScreen(client: client)),
              );
              onReturnFromFeed();
            },
          ),
        ),
      ],
    );
  }
}

/// Busca na Home — card de "não encontramos nada / sugerir conteúdo"
/// (revisão de estilo 2026-09-03, pedido de Rhoney: "nível
/// profissional... o campo que aparece quando o usuário não encontra o
/// tema"). Nunca usa tom de erro (Princípio de Não-Humilhação,
/// PRODUCT_PRINCIPLES.md §1) — "não encontramos" é neutro/convite, não
/// falha do usuário, por isso a moldura é dourada (mesma cor da própria
/// busca), nunca terracota/error.
class _ContentSuggestionCard extends StatelessWidget {
  const _ContentSuggestionCard({
    required this.query,
    required this.sending,
    required this.sent,
    required this.onSuggest,
    required this.onDismiss,
  });

  final String query;
  final bool sending;
  final bool sent;
  final VoidCallback onSuggest;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.travel_explore_rounded,
                  color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.homeSearchNotFoundMessage(query),
                  style: TextStyle(
                      color: AppColors.bone,
                      fontWeight: FontWeight.w600,
                      height: 1.3),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.close_rounded,
                      color: AppColors.muted, size: 18),
                  onPressed: onDismiss,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sent)
            Row(
              children: [
                Icon(Icons.check_circle_rounded,
                    color: AppColors.victory, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.homeSearchSuggestionRegisteredMessage,
                    style: TextStyle(
                        color: AppColors.victory,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: sending ? null : onSuggest,
                icon: sending
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.bg),
                      )
                    : const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: Text(l10n.homeSearchSuggestButton),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 16)),
              ),
            ),
        ],
      ),
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
      // HOME_REDESIGN_V2_MINIMALISMO.md §3.1 — leve transparência pra
      // marca d'água "respirar" através do card.
      color: AppColors.bg2.withValues(alpha: 0.92),
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
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.4))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Badge(
                isLabelVisible: (badgeCount ?? 0) > 0,
                label: Text('$badgeCount'),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 6),
              // Achado real no aparelho (03/09/2026, grid passou de 4
              // pra 5 colunas — HOME_REDESIGN_V2_MINIMALISMO.md §3.3):
              // a coluna ficou estreita demais até pra "Progresso"/
              // "Movimento" quebrarem em 2 linhas de forma legível —
              // sem um ponto de quebra de palavra disponível, o texto
              // cortava no meio ("Progress"/"o"). FittedBox encolhe a
              // fonte automaticamente pra caber numa linha só, mesmo
              // recurso já usado em "Desafio X" nos cards de território.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  // Cor clara (bone) em vez do "muted" padrão do
                  // bodySmall (29/08/2026) — o cinza discreto ficava
                  // quase invisível contra o fundo escuro.
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.bone,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Um item do carrossel de Mundos — record type nomeado (evita repetir a
/// mesma assinatura longa em `_buildWorldCarousel`/`_WorldCarousel`).
typedef _WorldCarouselItem = ({
  String title,
  IconData icon,
  bool completed,
  List<String> territoryIds,
  String? worldId,
});

/// Pedido de Rhoney (23/09/2026): "o carrossel de Mundos da Home deve ter
/// algo que indique que há mais mundos para ambos os lados e se possível
/// ele deve ficar passando suavemente quando o usuário não estiver
/// tocando na tela". Widget próprio (em vez de método de
/// `_HomeScreenState`) pra manter o ScrollController e o timer de
/// auto-scroll vivos entre os `setState` frequentes da Home (badges,
/// progresso etc.) — um método normal recriaria o controller a cada
/// rebuild e resetaria a posição/o timer sem motivo.
class _WorldCarousel extends StatefulWidget {
  const _WorldCarousel({
    required this.items,
    required this.shortTitle,
    required this.onTapItem,
  });

  final List<_WorldCarouselItem> items;
  final String Function(String title) shortTitle;
  final void Function(_WorldCarouselItem item) onTapItem;

  @override
  State<_WorldCarousel> createState() => _WorldCarouselState();
}

class _WorldCarouselState extends State<_WorldCarousel> {
  final ScrollController _controller = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  bool _paused = false;
  // Token da animação de "voltar pro início" em andamento (animateTo) —
  // incrementado sempre que o usuário interrompe o auto-scroll, pra o
  // `.then` de uma animação já cancelada não reativar o auto-scroll por
  // engano (ver _pauseForInteraction).
  int _bounceToken = 0;
  bool _canScrollLeft = false;
  bool _canScrollRight = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateEdges);
    // hasClients só fica true depois do primeiro layout — checar/iniciar
    // o auto-scroll no frame seguinte, não em initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateEdges();
      _startAutoScroll();
    });
  }

  void _updateEdges() {
    if (!_controller.hasClients || !mounted) return;
    final pos = _controller.position;
    final canLeft = pos.pixels > 4;
    final canRight = pos.pixels < pos.maxScrollExtent - 4;
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  /// Rolagem contínua e suave (poucos pixels por tick) enquanto o
  /// usuário não está tocando o carrossel — ao chegar no fim, volta pro
  /// início com uma animação suave em vez de "teleportar".
  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (_paused || !mounted || !_controller.hasClients) return;
      final pos = _controller.position;
      if (pos.maxScrollExtent <= 0) return; // cabe tudo na tela, nada a rolar
      final next = _controller.offset + 0.8;
      if (next >= pos.maxScrollExtent) {
        _paused = true; // evita o timer competir com a animação de volta
        final token = ++_bounceToken;
        _controller
            .animateTo(0,
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeInOut)
            .then((_) {
          // Só retoma se nada interrompeu esta MESMA animação nesse meio
          // tempo (ver _pauseForInteraction) — senão um toque durante a
          // volta ao início reativaria o auto-scroll por engano.
          if (mounted && token == _bounceToken) _paused = false;
        });
      } else {
        _controller.jumpTo(next);
      }
    });
  }

  /// Pedido de Rhoney (23/09/2026): "assim que o usuário tocar a tela, o
  /// carrossel deve parar imediatamente". `_paused = true` sozinho não
  /// bastava quando a rolagem automática estava no meio da animação de
  /// "voltar pro início" (animateTo) — a animação continuava até o fim
  /// (até 900ms) mesmo com o toque. `jumpTo` pro offset atual cancela
  /// qualquer activity em andamento no ScrollPosition (inclusive um
  /// animateTo), então o carrossel trava exatamente onde estava, no
  /// mesmo frame do toque.
  void _pauseForInteraction() {
    _paused = true;
    _bounceToken++; // invalida o `.then` de uma animação em andamento
    _resumeTimer?.cancel();
    if (_controller.hasClients) {
      _controller.jumpTo(_controller.offset);
    }
  }

  /// Retoma o auto-scroll um tempo depois do usuário soltar o dedo —
  /// nunca imediatamente, senão a rolagem automática "briga" com um
  /// toque logo em seguida (ex.: olhando o card antes de decidir tocar).
  void _scheduleResume() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _paused = false;
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Widget _edgeFade({required bool onLeft}) {
    return Positioned(
      left: onLeft ? 0 : null,
      right: onLeft ? null : 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: onLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: onLeft ? Alignment.centerRight : Alignment.centerLeft,
              colors: [AppColors.bg, AppColors.bg.withValues(alpha: 0)],
            ),
          ),
          alignment: onLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Icon(
            onLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.muted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: Stack(
        children: [
          Listener(
            onPointerDown: (_) => _pauseForInteraction(),
            onPointerUp: (_) => _scheduleResume(),
            onPointerCancel: (_) => _scheduleResume(),
            child: ListView.separated(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              itemCount: widget.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = widget.items[index];
                return _WorldCarouselCard(
                  title: widget.shortTitle(item.title),
                  icon: item.icon,
                  completed: item.completed,
                  onTap: () => widget.onTapItem(item),
                );
              },
            ),
          ),
          if (_canScrollLeft) _edgeFade(onLeft: true),
          if (_canScrollRight) _edgeFade(onLeft: false),
        ],
      ),
    );
  }
}

/// REORGANIZACAO_MENUS_HOME_V1.md §5 (06/09/2026) — um card do carrossel
/// horizontal de Mundos: ícone + nome, sem expandir nada in-place (ver
/// `_buildWorldCarousel`). Substitui a antiga `_WorldSection`
/// (ExpansionTile empilhado verticalmente).
class _WorldCarouselCard extends StatelessWidget {
  const _WorldCarouselCard({
    required this.title,
    required this.icon,
    required this.completed,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      // HOME_REDESIGN_V2_MINIMALISMO.md §3.1 — leve transparência pra
      // marca d'água "respirar" através dos cards.
      color: AppColors.bg2.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Destaque leve quando o Mundo está 100% concluído (29/08/2026,
        // pedido de Rhoney) — só decorativo, nunca trava: o jogador pode
        // refazer os territórios do Mundo quantas vezes quiser.
        side: BorderSide(
            color: completed
                ? AppColors.gold.withValues(alpha: 0.5)
                : Colors.transparent),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          // Achado real testando no dispositivo (06/09/2026): 104 era
          // estreito demais pra uma palavra só de 9-10 letras
          // ("Linguagem", "Descoberta") — quebrava no meio da palavra
          // ("Linguage"/"m") em vez de caber numa linha ou quebrar num
          // ponto natural.
          width: 118,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.gold, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (completed) ...[
                const SizedBox(height: 4),
                Icon(Icons.check_circle, color: AppColors.gold, size: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// REORGANIZACAO_MENUS_HOME_V1.md §5 (06/09/2026) — tela dedicada de um
/// Mundo, aberta ao tocar num card do carrossel da Home: mostra só os
/// territórios daquele Mundo (mesmo grid de sempre), decisão tomada com
/// Rhoney de não expandir nada in-place na Home. `refreshProgress`
/// atualiza o estado da Home por baixo (mesmo papel de `_loadProgress`);
/// como isso sozinho não reconstrói ESTA tela (Navigator empilha uma
/// State própria, alheia ao setState da Home), `_handleReturned` espera
/// o refresh terminar e só então reconstrói localmente — sem isso, a
/// barra de progresso do território respondido ficaria visualmente
/// desatualizada até o jogador voltar pra Home e reabrir o Mundo.
class _WorldDetailScreen extends StatefulWidget {
  const _WorldDetailScreen({
    required this.title,
    required this.worldId,
    required this.completed,
    required this.client,
    required this.refreshProgress,
    required this.buildChildren,
  });

  final String title;
  // Pedido de Rhoney (23/09/2026): a dica do My_Mental_AI foca no
  // desempenho do usuário NESTE Mundo específico. Mundo dos Idiomas
  // fica de fora (agente próprio "Mental Lingo", ainda não implementado)
  // — o card simplesmente não é buscado/mostrado para ele. null (Mundo
  // ainda sem world_id, fallback "todos os territórios") também some.
  final String? worldId;
  final bool completed;
  final ApiClient client;
  final Future<void> Function() refreshProgress;
  final List<Widget> Function(VoidCallback onReturned) buildChildren;

  @override
  State<_WorldDetailScreen> createState() => _WorldDetailScreenState();
}

class _WorldDetailScreenState extends State<_WorldDetailScreen> {
  Map<String, dynamic>? _worldCoachCard;

  @override
  void initState() {
    super.initState();
    _loadWorldCoach();
  }

  Future<void> _loadWorldCoach() async {
    final worldId = widget.worldId;
    if (worldId == null || worldId == 'idiomas') return;
    try {
      final data = await widget.client.getWorldCoach(worldId);
      if (mounted)
        setState(() => _worldCoachCard = data['card'] as Map<String, dynamic>?);
    } on ApiException {
      // o cartão simplesmente não aparece
    }
  }

  Future<void> _handleReturned() async {
    await widget.refreshProgress();
    if (mounted) setState(() {});
    _loadWorldCoach();
  }

  Widget _buildWorldCoachCard(AppLocalizations l10n) {
    final card = _worldCoachCard;
    if (card == null) return const SizedBox.shrink();
    return MyMentalAiWorldCard(card: card, client: widget.client, onReturned: _loadWorldCoach);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
                child: Text(widget.title, overflow: TextOverflow.ellipsis)),
            if (widget.completed) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_circle, color: AppColors.gold, size: 20),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // MENTAL LINGO (aprovado 23/09/2026): só no Mundo dos Idiomas —
            // é o Mundo que ganha agente de voz PRÓPRIO em vez do card
            // genérico do My_Mental_AI (_buildWorldCoachCard já pula
            // 'idiomas' sozinho, ver _loadWorldCoach).
            if (widget.worldId == 'idiomas') MentalLingoBanner(client: widget.client),
            _buildWorldCoachCard(l10n),
            ...widget.buildChildren(_handleReturned),
          ],
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
    required this.blockId,
    required this.blockName,
    required this.territoryIds,
    required this.l10n,
    required this.territoryProgressOf,
    required this.client,
    required this.onReturned,
  });

  final String? blockId;
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
            _SectionHeader(blockId: blockId!, name: blockName!),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              // Uma linha por território: "Desafio" e "Relâmpago" lado a lado
              // dentro do próprio card (pedido de Rhoney, 19/09/2026).
              final cardWidth = constraints.maxWidth;
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

// ORGANIZACAO_VISUAL_POR_SECAO_TODOS_MUNDOS_V1.md §2.1.1 (19/09/2026,
// aprovado) — registro explícito de ícone temático por block_id, mesmo
// padrão de outros registros hand-curated do projeto (SUBMUNDO_BLOCK_
// IDS, IDIOMA_TERRITORY_IDS): nunca inferido do nome, sempre uma
// entrada por bloco conhecido. Bloco sem entrada aqui cai no ícone
// genérico — nunca quebra, só fica menos temático até alguém adicionar.
const Map<String, IconData> _kSectionIcons = {
  'ingles': Icons.flag_rounded,
  'espanhol': Icons.flag_rounded,
  'frances': Icons.flag_rounded,
  'libras': Icons.front_hand_rounded,
  'internet': Icons.public_rounded,
  'futebol': Icons.sports_soccer_rounded,
  'copa_do_mundo': Icons.emoji_events_rounded,
  'tecnologia': Icons.memory_rounded,
  'matematica': Icons.calculate_rounded,
  'enem': Icons.school_rounded,
  'concursos': Icons.gavel_rounded,
  'regioes': Icons.map_rounded,
  'mitologia': Icons.auto_stories_rounded,
  'financas_pessoais': Icons.savings_rounded,
  'filosofia': Icons.psychology_rounded,
  'artes': Icons.palette_rounded,
  'saude_bemestar': Icons.favorite_rounded,
  'curiosidade_relampago': Icons.bolt_rounded,
  'jogos_de_palavras': Icons.extension_rounded,
  'palavras_raras': Icons.spellcheck_rounded,
  'lg_crase': Icons.text_fields_rounded,
  'lg_morfologia': Icons.abc_rounded,
  'lg_interpretacao_de_texto': Icons.menu_book_rounded,
  'lg_concordancia_verbal': Icons.rule_rounded,
  'lg_concordancia_nominal': Icons.link_rounded,
  'lg_regencia_verbal': Icons.alt_route_rounded,
  'lg_regencia_nominal': Icons.merge_type_rounded,
  'lg_colocacao_pronominal': Icons.swap_horiz_rounded,
  'lg_pronomes': Icons.person_pin_rounded,
};

/// Cabeçalho de seção reutilizável — usado por qualquer Bloco/SubMundo
/// em qualquer Mundo do app (ORGANIZACAO_VISUAL_POR_SECAO_TODOS_MUNDOS_
/// V1.md §4: "um componente reutilizável ... evitando implementação
/// repetida e inconsistente"). Substitui o antigo rótulo cinza pequeno
/// por tipografia maior, ícone temático e uma linha de destaque em
/// gradiente — mesmo cuidado de acabamento já pedido pro Caça-palavras
/// e pro ícone do Mapa de Trajetória.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.blockId, required this.name});

  final String blockId;
  final String name;

  @override
  Widget build(BuildContext context) {
    final icon = _kSectionIcons[blockId] ?? Icons.category_rounded;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.gold, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.bone,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              gradient: LinearGradient(
                colors: [
                  AppColors.gold.withValues(alpha: 0.5),
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),
      ],
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
    final progressFraction =
        (xpInTerritory / conquestThreshold).clamp(0.0, 1.0);
    final progressColor =
        Color.lerp(AppColors.error, AppColors.victory, progressFraction)!;
    // V2 item 13 — Disputa territorial (TERRITORY_DISPUTE.md). Sempre
    // relativo a você + amigos confirmados (nunca global) — o backend
    // já filtra isso, a Home só exibe o que vem pronto.
    final detentorNickname = progress?['detentor_nickname'] as String?;
    final detentorPhotoUrl = progress?['detentor_photo_url'] as String?;
    final isDetentor = progress?['is_detentor'] as bool? ?? false;
    // Cor de identidade do bloco Curiosidade Relâmpago (V3.5 §5, item
    // movido pra V4) — índigo em vez do roxo já usado em XP/nível,
    // reforçado só no ícone e no rótulo do card, sem substituir a borda
    // de progresso (vermelho→verde) que já existe em todos os cards.
    final isMysteryBlock = territoryId == 'curiosidade_relampago';

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
              MaterialPageRoute(
                  builder: (_) => WordSearchScreen(
                      client: client,
                      territoryId: territoryId,
                      territoryLabel: label)),
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
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Pedido de Rhoney (19/09/2026): "Desafio" e "Relâmpago" lado a lado,
    // uma linha por território (como em Libras) — em vez de 2 colunas de
    // cards empilhados, que deixava o 3º nível (Avançado) sozinho na 2ª
    // linha e o Relâmpago longe do desafio ao qual pertence.
    //
    // V2 item 15 — Palavras Relâmpago (PALAVRAS_RELAMPAGO.md),
    // generalizado pra todos os territórios (29/08/2026, pedido de
    // Rhoney: "em todos os módulos tem que haver um relâmpago").
    // Territórios em kAlwaysTimedTerritoryIds (Cores, Conhecimento,
    // Curiosidade Relâmpago) já são SEMPRE cronometrados no backend —
    // um segundo botão "Relâmpago" seria redundante (achado real,
    // 2026-09-03); kNeverTimedTerritoryIds nunca têm Relâmpago.
    final showRelampago = !kAlwaysTimedTerritoryIds.contains(territoryId) &&
        !kNeverTimedTerritoryIds.contains(territoryId);
    // Pedido de Rhoney (29/08/2026): o botão do desafio segue a MESMA
    // linguagem visual do card do Mundo (fundo bg2, cantos arredondados,
    // borda de progresso), consistente com os cards do MentalCoins.
    final challengeCard = Material(
      color: AppColors.bg2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChallengeScreen(
                  client: client,
                  territoryId: territoryId,
                  territoryLabel: label),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMysteryBlock) ...[
                      Icon(Icons.auto_awesome,
                          size: 14, color: AppColors.mystery),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      l10n.newChallengeButton(label),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isMysteryBlock ? AppColors.mystery : null,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final relampagoButton = OutlinedButton(
      style: OutlinedButton.styleFrom(
          side: BorderSide(color: progressColor.withValues(alpha: 0.6))),
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
        child: Text(l10n.relampagoModeLabel,
            textAlign: TextAlign.center, maxLines: 1),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showRelampago)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: challengeCard),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: relampagoButton),
              ],
            ),
          )
        else
          challengeCard,
        if (detentorNickname != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pedido de Rhoney (07/09/2026): "agora que os nomes
              // aparecem em qualquer tela, ponha as fotos também" — só
              // quando o detentor é outra pessoa (a própria foto do
              // jogador, no card "Você é o detentor", seria redundante).
              if (!isDetentor && detentorPhotoUrl != null) ...[
                ProfilePhotoCircle(photoUrl: detentorPhotoUrl, size: 14),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  isDetentor
                      ? l10n.territoryDetentorIsMeLabel
                      : l10n.territoryDetentorLabel(detentorNickname),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.technicalStyle(
                    color: isDetentor ? AppColors.gold : AppColors.muted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Card de identidade do usuário (Home/HOME_REDESIGN_V1.md §3, reajustado
/// 29/08/2026 a pedido de Rhoney: "está tomando muito espaço, diminua de
/// forma a aproveitar todo o card de forma estruturada"). Substitui o
/// avatar grande + XpBar completa + chips separados por uma estrutura de
/// 3 linhas compactas dentro do MESMO card, sem nenhuma informação
/// duplicada: nível vira badge sobre o avatar (não repetido em texto),
/// XP ganha uma linha própria fina, e XP total/Mundos/Streak dividem uma
/// única linha de metadados em vez de cards separados.
/// DESTAQUE_ICONE_MAPA_TRAJETORIA_V1.md (18/09/2026) — botão de acesso ao
/// Mapa de Trajetória redesenhado: era um ícone genérico de "sparkles"
/// (✨) pequeno e pouco perceptível, substituído por uma miniatura do
/// próprio planeta/anel usado na tela de destino (mesma metáfora de
/// Universo/Galáxia de trajectory_map_screen.dart — _RingPainter/gradiente
/// radial replicados aqui em escala pequena, não reinventados), com
/// rótulo abaixo no mesmo padrão dos atalhos da Home (ícone + texto).
class _TrajectoryMapLaunchButton extends StatelessWidget {
  const _TrajectoryMapLaunchButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                      size: const Size(40, 40),
                      painter: _MiniRingPainter(color: AppColors.gold)),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: const Alignment(-0.35, -0.35),
                        colors: [AppColors.purple, AppColors.ink],
                      ),
                      border: Border.all(color: AppColors.purple, width: 1.2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                l10n.trajectoryMapQuickActionLabel,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.bone,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Anel elíptico inclinado tipo Saturno, em escala mini — mesmo desenho
/// de trajectory_map_screen.dart::_RingPainter, só sem depender daquele
/// arquivo (evita acoplar a Home a uma tela de feature específica por
/// causa de um detalhe puramente decorativo).
class _MiniRingPainter extends CustomPainter {
  _MiniRingPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.5);
    canvas.rotate(-0.3);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset.zero, width: size.width, height: size.height * 0.32),
        paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.photoUrl,
    required this.realName,
    required this.mentalCoinsBalance,
    required this.l10n,
    required this.onTapPhoto,
    required this.onTapMentalCoins,
    required this.onTapTrajectoryMap,
  });

  final Map<String, dynamic> progress;
  final String? photoUrl;
  final String? realName;
  final int? mentalCoinsBalance;
  final AppLocalizations l10n;
  final VoidCallback onTapPhoto;
  final VoidCallback onTapMentalCoins;
  final VoidCallback onTapTrajectoryMap;

  @override
  Widget build(BuildContext context) {
    final level = progress['level'] as int;
    final xpTotal = progress['xp_total'] as int;
    // Achado de auditoria de qualidade 3.1 (11/09/2026): o backend já é
    // a fonte de verdade (config.XP_PER_LEVEL) e já envia esse valor em
    // GET /progress — consumir daqui em vez de duplicar a constante
    // evita as duas telas ficarem erradas silenciosamente se o backend
    // mudar o valor.
    final xpPerLevel = progress['xp_per_level'] as int;
    final streakDays = progress['streak']['current_streak'] as int;
    final xpIntoLevel = xpTotal % xpPerLevel;
    final fraction = (xpIntoLevel / xpPerLevel).clamp(0.0, 1.0);
    final worlds = (progress['worlds'] as List?)?.cast<Map<String, dynamic>>();
    final worldsCompleted = worlds?.where((w) => w['completed'] as bool).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // HOME_REDESIGN_V2_MINIMALISMO.md §3.1 — leve transparência
          // (alpha 0.92) pra marca d'água "respirar" através do card,
          // sem prejudicar a legibilidade do conteúdo por cima.
          colors: [
            AppColors.bg2.withValues(alpha: 0.92),
            Color.lerp(AppColors.bg2, AppColors.purple, 0.08)!
                .withValues(alpha: 0.92),
          ],
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
                    ProfilePhotoCircle(
                        photoUrl: photoUrl, size: 44, highlighted: true),
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
                        child: Text('$level',
                            style: AppTheme.technicalStyle(
                                    color: AppColors.bg, fontSize: 10)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // DESTAQUE_ICONE_MAPA_TRAJETORIA_V1.md (18/09/2026): nome e
              // botão do mapa dividem o espaço livre entre o avatar e o
              // chip de MentalCoins em ~50/50 (flex:1 cada), independente
              // do tamanho do nome exibido — antes o nome tinha prioridade
              // total (Expanded sozinho) e o botão do mapa era um ícone
              // pequeno espremido no que sobrava.
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (realName != null && realName!.isNotEmpty)
                      Text(realName!,
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                    Text('Nível $level',
                        style: AppTheme.technicalStyle(
                            color: AppColors.teal, fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Center(
                    child:
                        _TrajectoryMapLaunchButton(onTap: onTapTrajectoryMap)),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTapMentalCoins,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MentalCoin(size: 18),
                      const SizedBox(width: 6),
                      Text('${mentalCoinsBalance ?? 0}',
                          style: AppTheme.technicalStyle(
                                  color: AppColors.gold, fontSize: 13)
                              .copyWith(fontWeight: FontWeight.w700)),
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
                            child: Container(
                                decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [
                              AppColors.victory,
                              AppColors.purple,
                              AppColors.gold
                            ]))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('$xpIntoLevel/$xpPerLevel XP',
                  style: AppTheme.technicalStyle(
                      color: AppColors.muted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _MetaStat(
                      icon: Icons.bolt_rounded,
                      color: AppColors.gold,
                      value: '$xpTotal',
                      label: 'XP total')),
              Expanded(
                  child: _MetaStat(
                      icon: Icons.public_rounded,
                      color: AppColors.purple,
                      value: worldsCompleted != null
                          ? '$worldsCompleted/${worlds!.length}'
                          : '—',
                      label: 'Mundos')),
              Expanded(
                  child: _MetaStat(
                      icon: Icons.local_fire_department_rounded,
                      color: AppColors.victory,
                      value: '$streakDays',
                      label: l10n.streakSectionTitle)),
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
  const _MetaStat(
      {required this.icon,
      required this.color,
      required this.value,
      required this.label});

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
            Text(label.toUpperCase(),
                style:
                    AppTheme.technicalStyle(color: AppColors.bone, fontSize: 10)
                        .copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        Text(value,
            style: AppTheme.technicalStyle(color: color, fontSize: 17)
                .copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}
