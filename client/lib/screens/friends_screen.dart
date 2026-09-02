import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../widgets/profile_photo.dart';
import '../widgets/report_block_sheet.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/share_service.dart';
import '../territories.dart';
import '../theme/app_theme.dart';
import '../widgets/help_sheet.dart';
import 'challenge_screen.dart';
import 'public_profile_screen.dart';

/// V2 item 12 — Amigos (V2_KICKOFF.md §6A). Reaproveita o MESMO
/// invite_code de sempre (GET /social/invite-code, já existente desde o
/// Vertical Slice 01) como ponto de entrada — nenhum fluxo novo de
/// convite, só um endpoint novo que consome o código já existente. O
/// backend é a única autoridade sobre a amizade (mental.friendships,
/// N:N, separado de invite_conversions) e sobre a anonimização de
/// nickname para child_safe_mode — esta tela só exibe o que já vem
/// pronto, mesmo princípio de RankingScreen.
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  bool _loading = true;
  String? _error;
  String? _inviteCode;
  List<Map<String, dynamic>> _friends = [];
  // Achado de auditoria de segurança (28/08/2026): resgatar um
  // invite_code não cria mais amizade direto, só um pedido pendente —
  // precisa do aceite explícito de quem convidou.
  List<Map<String, dynamic>> _friendRequests = [];
  final _codeController = TextEditingController();
  bool _adding = false;

  // AMIGOS_CONVITE_POR_NOME.md — busca por nome, complementa o convite
  // por código acima (não substitui: código funciona fora do app).
  // Autocomplete só a partir da 3ª letra (§5 do doc) e com debounce de
  // ~300ms — evita uma chamada de API a cada tecla digitada.
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  final Set<String> _pendingRequestUserIds = {};

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.length < 3) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 300), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _searching = true);
    try {
      final response = await widget.client.searchUsers(query);
      if (mounted && _searchController.text.trim() == query) {
        setState(() => _searchResults = (response['results'] as List).cast<Map<String, dynamic>>());
      }
    } on ApiException catch (_) {
      // Busca é um reforço, não crítico — nunca sobrescreve o erro
      // principal da tela (ex.: falha ao carregar amigos).
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _sendSearchFriendRequest(Map<String, dynamic> result) async {
    final userId = result['user_id'] as String;
    setState(() => _pendingRequestUserIds.add(userId));
    try {
      await widget.client.sendFriendRequest(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.friendRequestSentMessage)),
        );
      }
    } on ApiException catch (e) {
      _pendingRequestUserIds.remove(userId);
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final invite = await widget.client.getInviteCode();
      final friends = await widget.client.getFriends();
      if (mounted) {
        setState(() {
          _inviteCode = invite['invite_code'] as String;
          _friends = (friends['friends'] as List).cast<Map<String, dynamic>>();
        });
      }
      // Pedidos pendentes buscados à parte: uma falha aqui não deve
      // impedir a lista de amigos (que já carregou com sucesso acima)
      // de aparecer.
      try {
        final requests = await widget.client.getFriendRequests();
        if (mounted) {
          setState(() => _friendRequests = (requests['requests'] as List).cast<Map<String, dynamic>>());
        }
      } on ApiException catch (_) {
        // Reforço visual, não crítico — segue sem a lista de pedidos.
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openReportBlockSheet({required String userId, required String nickname}) async {
    final blocked = await showReportBlockSheet(context, client: widget.client, targetUserId: userId, targetNickname: nickname);
    // Bloquear encerra qualquer amizade/pedido existente no backend —
    // recarrega pra tirar a pessoa bloqueada das duas listas na tela.
    if (blocked) await _load();
  }

  Future<void> _acceptRequest(Map<String, dynamic> request) async {
    try {
      await widget.client.acceptFriendRequest(request['friendship_id'] as String);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _declineRequest(Map<String, dynamic> request) async {
    try {
      await widget.client.declineFriendRequest(request['friendship_id'] as String);
      await _load();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _copyCode() async {
    final code = _inviteCode;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.friendsCodeCopiedMessage)),
      );
    }
  }

  Future<void> _shareInvite() async {
    final code = _inviteCode;
    if (code == null) return;
    await ShareService.share(AppLocalizations.of(context)!.friendsInviteShareMessage(code));
  }

  void _showHelp() {
    final l10n = AppLocalizations.of(context)!;
    showHelpSheet(
      context,
      title: l10n.friendsHelpTitle,
      steps: [
        HelpStep(icon: Icons.share_outlined, title: l10n.friendsHelpStep1Title, description: l10n.friendsHelpStep1Body),
        HelpStep(icon: Icons.hourglass_top_outlined, title: l10n.friendsHelpStep2Title, description: l10n.friendsHelpStep2Body),
        HelpStep(icon: Icons.check_circle_outline, title: l10n.friendsHelpStep3Title, description: l10n.friendsHelpStep3Body),
        HelpStep(icon: Icons.flash_on_outlined, title: l10n.friendsHelpStep4Title, description: l10n.friendsHelpStep4Body),
        HelpStep(icon: Icons.shield_outlined, title: l10n.friendsHelpStep5Title, description: l10n.friendsHelpStep5Body),
      ],
    );
  }

  Future<void> _addFriend() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _adding = true;
      _error = null;
    });
    try {
      await widget.client.addFriend(code);
      _codeController.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.friendRequestSentMessage)),
        );
      }
    } on ApiException catch (e) {
      final message = switch (e.code) {
        'INVITE_NOT_FOUND' => l10n.friendsInviteNotFoundError,
        'CANNOT_FRIEND_SELF' => l10n.friendsCannotAddSelfError,
        _ => e.message,
      };
      if (mounted) setState(() => _error = message);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  // V2 item 14 — Batalha assíncrona (ASYNC_BATTLE.md §2.1): desafiante
  // escolhe território e nível livremente (não é a dificuldade adaptativa
  // do modo normal). Diálogo simples — backend valida amizade/limite
  // diário/território de qualquer forma, esta UI só evita o óbvio (ex.:
  // não deixa enviar sem escolher território).
  Future<void> _challengeFriend(Map<String, dynamic> friend) async {
    final l10n = AppLocalizations.of(context)!;
    String territoryId = kTerritoryIds.first;
    int difficultyLevel = 2;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text(l10n.battleDialogTitle(friend['nickname'] as String)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: territoryId,
                    decoration: InputDecoration(labelText: l10n.battleDialogTerritoryLabel),
                    items: [
                      for (final id in kTerritoryIds)
                        DropdownMenuItem(value: id, child: Text(territoryLabel(l10n, id))),
                    ],
                    onChanged: (value) => setDialogState(() => territoryId = value ?? territoryId),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: difficultyLevel,
                    decoration: InputDecoration(labelText: l10n.battleDialogDifficultyLabel),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('1')),
                      DropdownMenuItem(value: 2, child: Text('2')),
                      DropdownMenuItem(value: 3, child: Text('3')),
                      DropdownMenuItem(value: 4, child: Text('4')),
                      DropdownMenuItem(value: 5, child: Text('5')),
                    ],
                    onChanged: (value) => setDialogState(() => difficultyLevel = value ?? difficultyLevel),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: Text(l10n.battleDialogSendButton),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed != true || !mounted) return;

    try {
      final created = await widget.client.createBattle(
        opponentUserId: friend['user_id'] as String,
        territoryId: territoryId,
        difficultyLevel: difficultyLevel,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChallengeScreen(
            client: widget.client,
            territoryId: territoryId,
            territoryLabel: territoryLabel(l10n, territoryId),
            battleId: created['battle_id'] as String,
            prefetchedChallenge: created['challenge'] as Map<String, dynamic>,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'BATTLE_DAILY_LIMIT_REACHED' ? l10n.battleDailyLimitReachedMessage : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildSearchResultAction(Map<String, dynamic> result) {
    final l10n = AppLocalizations.of(context)!;
    final userId = result['user_id'] as String;
    final status = result['friendship_status'] as String?;
    if (status == 'accepted') {
      return Text(l10n.friendsSearchAlreadyFriendsLabel, style: Theme.of(context).textTheme.bodySmall);
    }
    if (status == 'pending' || _pendingRequestUserIds.contains(userId)) {
      return Text(l10n.friendsSearchRequestPendingLabel, style: Theme.of(context).textTheme.bodySmall);
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
      onPressed: () => _sendSearchFriendRequest(result),
      child: Text(l10n.friendsSearchSendInviteButton),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.friendsScreenTitle),
        actions: [
          IconButton(
            tooltip: l10n.friendsHelpTooltip,
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_inviteCode != null) ...[
                      Text(
                        l10n.friendsInviteCodeLabel(_inviteCode!),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      // Dois botões lado a lado: Expanded nos dois evita o
                      // bug real já achado nesta tela (minimumSize:
                      // Size.fromHeight(48) do tema força largura infinita
                      // em OutlinedButton/FilledButton dentro de um Row sem
                      // constraint — Expanded distribui a largura igual
                      // pros dois, sem esse risco).
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _copyCode,
                              child: Text(l10n.friendsCopyCodeButton),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _shareInvite,
                              icon: const Icon(Icons.share_outlined, size: 18),
                              label: Text(l10n.friendsInviteShareButton),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.friendsSearchFieldHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (_searchController.text.trim().length >= 3 && !_searching) ...[
                      const SizedBox(height: 4),
                      if (_searchResults.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            l10n.friendsSearchEmptyMessage,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      else
                        // Resultado leva direto à ação de convite — nunca
                        // abre o perfil público completo a partir daqui
                        // (AMIGOS_CONVITE_POR_NOME.md §2, exceção escopada
                        // estritamente ao fluxo de convite).
                        ...[
                          for (final result in _searchResults)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: ProfilePhotoCircle(photoUrl: result['photo_url'] as String?),
                              title: Text(
                                (result['real_name'] as String?) ?? (result['nickname'] as String),
                              ),
                              subtitle: Text(
                                l10n.levelLabel(result['level'] as int),
                                style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 14),
                              ),
                              trailing: _buildSearchResultAction(result),
                            ),
                        ],
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeController,
                            decoration: InputDecoration(hintText: l10n.friendsAddFieldHint),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Achado real (2026-08-22): AppTheme define
                        // minimumSize: Size.fromHeight(48) pro FilledButton
                        // (largura infinita mínima, pensado pros CTAs de
                        // largura cheia em Column — "Novo desafio", "Ativar
                        // contador" etc.). Isso quebra com "BoxConstraints
                        // forces an infinite width" sempre que o botão vai
                        // direto num Row sem Flexible/Expanded — Flexible dá
                        // a constraint limitada que falta, sem esticar o
                        // botão como o TextField ao lado.
                        Flexible(
                          child: FilledButton(
                            onPressed: _adding ? null : _addFriend,
                            child: Text(l10n.friendsAddButton),
                          ),
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: AppColors.error)),
                    ],
                    if (_friendRequests.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(l10n.friendRequestsTitle, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final request in _friendRequests)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(request['from_nickname'] as String),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                onPressed: () => _declineRequest(request),
                                child: Text(l10n.friendRequestDeclineButton),
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                style: FilledButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                onPressed: () => _acceptRequest(request),
                                child: Text(l10n.friendRequestAcceptButton),
                              ),
                              IconButton(
                                tooltip: l10n.friendMoreOptionsTooltip,
                                icon: const Icon(Icons.more_vert, size: 20),
                                onPressed: () => _openReportBlockSheet(
                                  userId: request['from_user_id'] as String,
                                  nickname: request['from_nickname'] as String,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 24),
                    Text(l10n.friendsListTitle, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _friends.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(l10n.friendsEmptyMessage, textAlign: TextAlign.center),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _friends.length,
                              itemBuilder: (context, index) {
                                final friend = _friends[index];
                                final realName = friend['real_name'] as String?;
                                return ListTile(
                                  // V4 item 1 — Perfil Público: toque na
                                  // linha (fora dos botões de ação) abre o
                                  // perfil público do amigo
                                  // (PERFIL_PUBLICO_E_TORCIDA_V1.md §3).
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => PublicProfileScreen(client: widget.client, userId: friend['user_id'] as String)),
                                  ),
                                  leading: ProfilePhotoCircle(photoUrl: friend['photo_url'] as String?),
                                  // Nome real substitui o apelido gerado
                                  // pelo sistema assim que existir
                                  // (29/08/2026, pedido de Rhoney).
                                  title: Text(
                                    realName != null && realName.isNotEmpty ? realName : friend['nickname'] as String,
                                  ),
                                  subtitle: Text(
                                    '${friend['xp_total']} XP',
                                    style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 14),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      OutlinedButton(
                                        // Mesmo achado do bug de largura
                                        // infinita já documentado nesta tela
                                        // (AppTheme define minimumSize:
                                        // Size.fromHeight(48), largura
                                        // infinita) — aqui o problema é outro
                                        // sintoma do mesmo bug: dentro de
                                        // ListTile.trailing (não um Row
                                        // solto), então a correção é reduzir
                                        // o mínimo, não usar Flexible/Expanded.
                                        style: OutlinedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                        onPressed: () => _challengeFriend(friend),
                                        child: Text(l10n.battleChallengeButton),
                                      ),
                                      IconButton(
                                        tooltip: l10n.friendMoreOptionsTooltip,
                                        icon: const Icon(Icons.more_vert, size: 20),
                                        onPressed: () => _openReportBlockSheet(
                                          userId: friend['user_id'] as String,
                                          nickname: friend['nickname'] as String,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
