import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../avatars.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// USER_PROFILE.md (aprovado). Todos os campos são opcionais — nenhum
/// bloqueia ou degrada o uso do app se não preenchidos. O backend é a
/// única autoridade sobre o que fica salvo; esta tela só carrega/edita.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _avatarId;
  final _realNameController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  bool _locationPublic = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _realNameController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.client.getProfile();
      if (mounted) {
        setState(() {
          _avatarId = profile['avatar_id'] as String?;
          _realNameController.text = profile['real_name'] as String? ?? '';
          _stateController.text = profile['location_state'] as String? ?? '';
          _countryController.text = profile['location_country'] as String? ?? '';
          _locationPublic = profile['location_public'] as bool? ?? false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.client.updateProfile(
        avatarId: _avatarId,
        realName: _realNameController.text.trim().isEmpty ? null : _realNameController.text.trim(),
        locationState: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        locationCountry: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        locationPublic: _locationPublic,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileSavedMessage)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileScreenTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.profileAvatarSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final entry in kAvatarEmoji.entries)
                        InkWell(
                          borderRadius: BorderRadius.circular(28),
                          onTap: () => setState(() => _avatarId = entry.key),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _avatarId == entry.key ? AppColors.gold : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: AvatarCircle(avatarId: entry.key, size: 48),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _realNameController,
                    decoration: InputDecoration(
                      labelText: l10n.profileRealNameLabel,
                      helperText: l10n.profileRealNameHelperText,
                      helperMaxLines: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.profileLocationSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _stateController,
                    decoration: InputDecoration(labelText: l10n.profileLocationStateLabel),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _countryController,
                    decoration: InputDecoration(labelText: l10n.profileLocationCountryLabel),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.profileLocationPublicLabel),
                    value: _locationPublic,
                    onChanged: (value) => setState(() => _locationPublic = value),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(l10n.profileSaveButton),
                  ),
                ],
              ),
      ),
    );
  }
}
