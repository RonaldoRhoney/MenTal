import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/guest_api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/guest_challenge_service.dart';
import '../theme/app_theme.dart';
import '../world_icons.dart';
import 'guest_challenge_screen.dart';

/// MENTAL_FLUXO_GUEST_3_QUESTOES_DIAGNOSTICO_TECNICO_V1.md §3.4 — primeira
/// tela do fluxo guest, antes do login. Lista Mundos via GET /guest/worlds
/// (sem autenticação) e, ao escolher um, abre GuestChallengeScreen pro
/// território de entrada daquele Mundo. "Já tenho conta" sempre visível
/// pra pular direto pro login, sem forçar ninguém pelas 3 perguntas.
class GuestWorldPickerScreen extends StatefulWidget {
  const GuestWorldPickerScreen({super.key, required this.baseUrl, required this.onSkipToLogin});

  final String baseUrl;
  final VoidCallback onSkipToLogin;

  @override
  State<GuestWorldPickerScreen> createState() => _GuestWorldPickerScreenState();
}

class _GuestWorldPickerScreenState extends State<GuestWorldPickerScreen> {
  late final GuestApiClient _guestClient = GuestApiClient(baseUrl: widget.baseUrl);
  List<Map<String, dynamic>>? _worlds;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final worlds = await _guestClient.listWorlds();
      if (mounted) setState(() => _worlds = worlds);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _skipToLogin() async {
    await GuestChallengeService.dismiss();
    widget.onSkipToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.guestPickerTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text(
                    l10n.guestPickerSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildBody(context, l10n)),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: _skipToLogin,
                child: Text(l10n.guestAlreadyHaveAccount),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.error)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: Text(l10n.tryAgainButton)),
          ],
        ),
      );
    }
    final worlds = _worlds;
    if (worlds == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: worlds.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final world = worlds[index];
        return _WorldTile(
          worldId: world['world_id'] as String,
          worldName: world['world_name'] as String,
          onTap: () async {
            await GuestChallengeService.setTerritoryId(world['territory_id'] as String);
            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => GuestChallengeScreen(
                  baseUrl: widget.baseUrl,
                  territoryId: world['territory_id'] as String,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WorldTile extends StatelessWidget {
  const _WorldTile({required this.worldId, required this.worldName, required this.onTap});

  final String worldId;
  final String worldName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bg2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(worldIcon(worldId), color: AppColors.gold),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(worldName, style: Theme.of(context).textTheme.titleMedium),
              ),
              Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
