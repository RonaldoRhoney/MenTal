import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';

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
  final _codeController = TextEditingController();
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.friendsScreenTitle)),
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
                      Text(_error!, style: const TextStyle(color: AppColors.error)),
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
                                return ListTile(
                                  title: Text(friend['nickname'] as String),
                                  trailing: Text(
                                    '${friend['xp_total']} XP',
                                    style: AppTheme.technicalStyle(color: AppColors.teal, fontSize: 14),
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
