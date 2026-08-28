import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo.dart';

/// USER_PROFILE.md (aprovado). Nome real/localização são opcionais aqui
/// (podem já ter sido preenchidos no onboarding obrigatório) — nenhum
/// bloqueia ou degrada o uso do app se não preenchidos. O backend é a
/// única autoridade sobre o que fica salvo; esta tela só carrega/edita.
///
/// Upload de foto real (revisão 27/08/2026 — USER_PROFILE.md §3.1)
/// substitui o antigo picker de avatar emoji: a imagem sobe direto pro
/// Supabase Storage (bucket público `profile-photos`, RLS restringe
/// escrita ao próprio dono via auth.uid()), e só a URL pública resultante
/// é enviada ao backend em PUT /profile — o backend nunca recebe bytes de
/// imagem, só valida a forma da URL. Toda foto nova nasce 'pending'
/// (fail-closed) até um admin aprovar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;
  String? _photoUrl;
  String? _photoModerationStatus;
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
          _photoUrl = profile['photo_url'] as String?;
          _photoModerationStatus = profile['photo_moderation_status'] as String?;
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

  Future<void> _pickAndUploadPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _uploadingPhoto = true;
      _error = null;
    });
    try {
      final ext = picked.path.split('.').last.toLowerCase();
      final path = '$userId/photo.$ext';
      final storage = Supabase.instance.client.storage.from('profile-photos');
      await storage.upload(
        path,
        File(picked.path),
        fileOptions: const FileOptions(upsert: true),
      );
      final publicUrl = storage.getPublicUrl(path);
      // Sufixo de cache-busting: o backend valida só a forma da URL
      // (prefixo + extensão), então o parâmetro extra não quebra
      // _is_valid_photo_url, e evita que o Image.network fique preso no
      // cache de uma foto antiga com o mesmo nome de arquivo.
      final bustedUrl = '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      final updated = await widget.client.updateProfile(
        realName: _realNameController.text.trim().isEmpty ? null : _realNameController.text.trim(),
        photoUrl: bustedUrl,
        locationState: _stateController.text.trim().isEmpty ? null : _stateController.text.trim(),
        locationCountry: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        locationPublic: _locationPublic,
      );
      if (mounted) {
        setState(() {
          _photoUrl = updated['photo_url'] as String?;
          _photoModerationStatus = updated['photo_moderation_status'] as String?;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = l10n.profilePhotoUploadError);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.client.updateProfile(
        realName: _realNameController.text.trim().isEmpty ? null : _realNameController.text.trim(),
        photoUrl: _photoUrl,
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
                  Text(l10n.profilePhotoSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ProfilePhotoCircle(photoUrl: _photoUrl, size: 72),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton(
                              onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                              child: _uploadingPhoto
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(l10n.profilePhotoChangeButton),
                            ),
                            if (_photoModerationStatus == 'pending') ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.profilePhotoPendingLabel,
                                style: AppTheme.technicalStyle(color: AppColors.gold, fontSize: 13),
                              ),
                            ] else if (_photoModerationStatus == 'rejected') ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.profilePhotoRejectedLabel,
                                style: const TextStyle(color: AppColors.error, fontSize: 13),
                              ),
                            ],
                          ],
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
