import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/app_version_service.dart';
import '../services/movement_service.dart';
import '../services/share_service.dart';
import '../services/theme_mode_service.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import '../widgets/coins_rise_overlay.dart';
import '../widgets/mentalcoin.dart';
import '../widgets/profile_photo.dart';
import '../widgets/update_available_dialog.dart';
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

/// Link oficial da ficha do MENTAL na Google Play — usado pelo botão de
/// convidar amigos (ao lado do nome do usuário, no card de progresso).
const String kPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.rhoneyinc.mental';

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

  /// Convidar amigos pra baixar o app (pedido de Rhoney, ao lado do
  /// wordmark "MENTAL" no topo) — usa o share sheet nativo do SO e, se o
  /// jogador de fato compartilhou, tenta a recompensa diária PRÓPRIA
  /// deste botão (POST /social/share-app-reward: 20 XP + 5 MentalCoins,
  /// teto de 1x/dia — nunca a mesma chamada/teto de ShareAchievementButton,
  /// que é sobre compartilhar uma conquista, não convidar gente nova).
  Future<void> _shareApp() async {
    final l10n = AppLocalizations.of(context)!;
    final shared = await ShareService.share(l10n.shareAppInviteMessage(kPlayStoreUrl));
    if (!shared) return;
    try {
      final result = await widget.client.rewardAppInviteShare();
      final xpAwarded = result['xp_awarded'] as int? ?? 0;
      final mentalCoinsAwarded = result['mentalcoins_awarded'] as int? ?? 0;
      final coinMilestoneReached = result['coin_milestone_reached'] as bool? ?? false;
      if (xpAwarded > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.shareAppXpAndCoinsRewardedMessage(xpAwarded, mentalCoinsAwarded))),
        );
      }
      if (coinMilestoneReached && mounted && !MediaQuery.of(context).disableAnimations) {
        _coinsRise.play();
      }
      if (mentalCoinsAwarded > 0) _loadMentalCoinsBalance();
      if (xpAwarded > 0) _loadProgress();
    } catch (_) {
      // Reforço opcional — falha ao pedir a recompensa não pode
      // interromper o fluxo de compartilhamento já concluído.
    }
  }

  // V2 item 9 — badge de passos ainda não coletados junto ao ícone de
  // Movimento (decisão de Rhoney, 2026-08-21: "catch-up ao reabrir o
  // app", nunca serviço em segundo plano com notificação fixa). Mostra
  // o valor certo assim que a Home carrega, usando a última leitura
  // conhecida do sensor de QUALQUER sessão — não espera um evento novo.
  int? _movementPendingSteps;
  String? _movementCycleId;
  StreamSubscription<int>? _movementStepSub;

  // Pedido de Rhoney (2026-09-02): moedas sobem na tela ao cruzar 100 XP
  // ou 50 MentalCoins ao convidar amigos (services.crossed_coin_milestone
  // via POST /social/share-app-reward) — mesmo controller/widget usado em
  // ChallengeScreen para o mesmo marco.
  final _coinsRise = CoinsRiseController();

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
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
      if (mounted && _notFoundQuery == query) setState(() => _notFoundQuery = null);
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
    _checkAppVersion();
  }

  // SCREENSHOTS_LOJA_E_AVISO_ATUALIZACAO_V1.md §2 (05/09/2026) — checado
  // uma vez por abertura do app (Home é a tela de entrada), nunca a
  // cada pull-to-refresh (não faz parte de _refreshAll de propósito,
  // pra não repetir o aviso toda vez que o usuário atualiza a tela).
  Future<void> _checkAppVersion() async {
    final result = await AppVersionService.check(widget.client);
    if (!mounted || result.status == AppUpdateStatus.upToDate) return;
    showUpdateAvailableDialog(context, required: result.status == AppUpdateStatus.updateRequired);
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
    _coinsRise.dispose();
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
        child: CoinsRiseOverlay(
          controller: _coinsRise,
          child: Stack(
            children: [
              // HOME_REDESIGN_V2_MINIMALISMO.md §3.1 — "MENTAL" some como
              // bloco de texto de destaque (já aparece na Splash, repetir
              // aqui era redundância pura) e vira marca d'água: opacidade
              // muito baixa, camada de fundo, NUNCA recebe toque
              // (IgnorePointer) — os cards acima continuam 100% clicáveis.
              const Positioned.fill(child: _MentalWatermark()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // §3.3 — grid de 5 cards (Progresso/Ranking/Amigos/
                    // Movimento/Mais), todos com o mesmo tamanho. O 5º
                    // card ("Mais") reaproveita os handlers de
                    // compartilhar e alternar tema que antes ficavam
                    // soltos no cabeçalho.
                    _QuickActionsRow(
                      client: widget.client,
                      movementPendingSteps: _movementPendingSteps,
                      onReturnFromProgress: _loadProgress,
                      onReturnFromMovement: _loadMovementBadge,
                      onShareApp: _shareApp,
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
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.gold),
                    suffixIcon: _searching
                        ? Padding(
                            padding: const EdgeInsets.all(14),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _searchController,
                            builder: (context, _) => _searchController.text.isEmpty
                                ? IconButton(
                                    icon: Icon(Icons.arrow_forward_rounded, color: AppColors.gold),
                                    onPressed: () => _handleSearch(_searchController.text),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.close_rounded, color: AppColors.muted),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _notFoundQuery = null);
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
                          onSuggest: () => _submitContentSuggestion(_notFoundQuery!),
                          onDismiss: () => setState(() => _notFoundQuery = null),
                        ),
                      ),
              ),
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
                    : RefreshIndicator(
                        onRefresh: _refreshAll,
                        color: AppColors.gold,
                        child: ListView(children: _buildWorldSections(l10n)),
                      ),
              ),
                  ],
                ),
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
    required this.onReturnFromProgress,
    required this.onReturnFromMovement,
    required this.onShareApp,
  });

  final ApiClient client;
  final int? movementPendingSteps;
  final VoidCallback onReturnFromProgress;
  final VoidCallback onReturnFromMovement;
  final VoidCallback onShareApp;

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
                MaterialPageRoute(builder: (_) => MovementScreen(client: client)),
              );
              onReturnFromMovement();
            },
          ),
        ),
        const SizedBox(width: 8),
        // HOME_REDESIGN_V2_MINIMALISMO.md §3.3 — 5º card, MESMO tamanho
        // dos outros 4 (Expanded igual), consolidando compartilhar +
        // alternar tema (antes soltos no cabeçalho da Home).
        Expanded(
          child: _MergedActionCard(
            label: l10n.homeMoreCardLabel,
            onShareTap: onShareApp,
          ),
        ),
      ],
    );
  }
}

/// HOME_REDESIGN_V2_MINIMALISMO.md §3.3 — 5º card do grid de atalhos,
/// mesmo container/padding/estrutura de _QuickActionCard, mas com DOIS
/// ícones lado a lado (compartilhar + tema) em vez de um só, separados
/// por um divisor fino. Cada ícone mantém sua própria área de toque —
/// o card inteiro não é um único InkWell (doc §5: "não é preciso que o
/// card inteiro dispare as duas ações ao mesmo tempo").
class _MergedActionCard extends StatelessWidget {
  const _MergedActionCard({required this.label, required this.onShareTap});

  final String label;
  final VoidCallback onShareTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.bg2.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniIconAction(
                icon: Icons.share_outlined,
                tooltip: l10n.shareAppButtonTooltip,
                onTap: onShareTap,
              ),
              Container(
                width: 1,
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: AppColors.muted.withValues(alpha: 0.3),
              ),
              const _ThemeModeMiniToggle(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.bone, fontWeight: FontWeight.w600, fontSize: 12, height: 1.15),
          ),
        ],
      ),
    );
  }
}

/// Ícone pequeno com área de toque própria (usado dentro de
/// _MergedActionCard) — CircleBorder pra feedback de toque redondo,
/// consistente com o resto do app (InkWell/Material já usado em
/// _QuickActionCard).
class _MiniIconAction extends StatelessWidget {
  const _MiniIconAction({required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(3),
            // Achado real no aparelho (03/09/2026, pedido de Rhoney:
            // "ajuste as proporções... trabalhe o espaçamento"): 18px
            // ficava visivelmente menor que os 28px do ícone único dos
            // outros 4 cards do grid — 22px aproxima o peso visual sem
            // estourar a coluna estreita (2 ícones + divisor no mesmo
            // espaço de 1 ícone dos demais cards).
            child: Icon(icon, color: AppColors.gold, size: 22),
          ),
        ),
      ),
    );
  }
}

/// Versão compacta de _ThemeModeToggleButton pra caber lado a lado com
/// o ícone de compartilhar dentro do mesmo card pequeno (o IconButton
/// original tem alvo de toque de 48dp, largo demais pros dois ícones
/// juntos no espaço de uma única coluna do grid).
class _ThemeModeMiniToggle extends StatelessWidget {
  const _ThemeModeMiniToggle();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeModeService.instance,
      builder: (context, _) {
        final isDark = ThemeModeService.instance.isDark;
        return _MiniIconAction(
          icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          tooltip: isDark ? 'Ativar tom claro' : 'Ativar tom escuro',
          onTap: () => ThemeModeService.instance.toggle(),
        );
      },
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
              Icon(Icons.travel_explore_rounded, color: AppColors.gold, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.homeSearchNotFoundMessage(query),
                  style: TextStyle(color: AppColors.bone, fontWeight: FontWeight.w600, height: 1.3),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.close_rounded, color: AppColors.muted, size: 18),
                  onPressed: onDismiss,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (sent)
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.victory, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.homeSearchSuggestionRegisteredMessage,
                    style: TextStyle(color: AppColors.victory, fontWeight: FontWeight.w600, fontSize: 13),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bg),
                      )
                    : const Icon(Icons.lightbulb_outline_rounded, size: 18),
                label: Text(l10n.homeSearchSuggestButton),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40), padding: const EdgeInsets.symmetric(horizontal: 16)),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.bone, fontWeight: FontWeight.w600, fontSize: 12, height: 1.15),
                ),
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
        // HOME_REDESIGN_V2_MINIMALISMO.md §3.1 — leve transparência pra
        // marca d'água "respirar" através dos itens de Mundo.
        color: AppColors.bg2.withValues(alpha: 0.92),
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMysteryBlock) ...[
                          Icon(Icons.auto_awesome, size: 14, color: AppColors.mystery),
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
        //
        // Achado real (pedido de Rhoney, 2026-09-03: "busque erros...
        // em Desafio de cores e relâmpago"): territórios em
        // kAlwaysTimedTerritoryIds (Cores, Conhecimento, Curiosidade
        // Relâmpago) já são SEMPRE cronometrados no backend, com ou sem
        // mode=relampago — mostrar um segundo botão "Relâmpago" ao lado
        // do botão normal é redundante e confuso, já que os dois abrem
        // exatamente o mesmo formato (a única diferença real, um piso
        // de dificuldade mínima, é invisível pro jogador).
        if (!kAlwaysTimedTerritoryIds.contains(territoryId)) ...[
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
          // HOME_REDESIGN_V2_MINIMALISMO.md §3.1 — leve transparência
          // (alpha 0.92) pra marca d'água "respirar" através do card,
          // sem prejudicar a legibilidade do conteúdo por cima.
          colors: [
            AppColors.bg2.withValues(alpha: 0.92),
            Color.lerp(AppColors.bg2, AppColors.purple, 0.08)!.withValues(alpha: 0.92),
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
              // Flexible com flex maior que os dois Spacer abaixo — o
              // nome continua tendo prioridade de espaço (só encolhe/
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
