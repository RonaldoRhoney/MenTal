import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/photo_picker_service.dart';
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
    // 29/08/2026 (pedido de Rhoney): tirar foto na hora (câmera) além de
    // escolher da galeria, e recortar antes de salvar — PhotoPickerService
    // cobre as duas etapas (fonte + recorte 1:1), devolvendo um File já
    // pronto pra upload.
    final croppedFile = await PhotoPickerService.pickAndCrop(context);
    if (croppedFile == null || !mounted) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {
      _uploadingPhoto = true;
      _error = null;
    });
    // Achado real (29/08/2026): um catch único e genérico aqui escondia
    // qual das duas etapas (upload pro Storage vs. PUT /profile) estava
    // de fato falhando, dificultando o diagnóstico de bugs relatados
    // por testadores. Separado em dois blocos, cada um com sua própria
    // mensagem de erro específica + debugPrint da exceção real (visível
    // via `adb logcat`/`flutter logs`, nunca exposto na UI).
    //
    // Extensão do arquivo: o ImageCropper sempre devolve JPEG
    // (compressFormat fixado em PhotoPickerService), então "jpg" é
    // sempre uma extensão válida aqui — mas mantém o fallback por
    // segurança caso o path do arquivo recortado não tenha extensão
    // reconhecível por algum motivo específico de plataforma.
    final rawExt = croppedFile.path.contains('.') ? croppedFile.path.split('.').last.toLowerCase() : '';
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    final ext = allowedExtensions.contains(rawExt) ? rawExt : 'jpg';
    final path = '$userId/photo.$ext';

    try {
      final storage = Supabase.instance.client.storage.from('profile-photos');
      await storage.upload(
        path,
        croppedFile,
        fileOptions: const FileOptions(upsert: true),
      );
    } catch (e) {
      debugPrint('MENTAL: falha no upload pro Supabase Storage: $e');
      if (mounted) {
        setState(() {
          _error = l10n.profilePhotoUploadError;
          _uploadingPhoto = false;
        });
      }
      return;
    }

    try {
      // Achado de auditoria de segurança (28/08/2026): bucket
      // profile-photos virou privado — não existe mais "URL pública"
      // pra ler (getPublicUrl não funcionaria pra leitura). Manda só o
      // PATH; o backend devolve uma URL assinada de curta duração pra
      // exibição (services.own_photo_url), gerada sob demanda — não
      // precisa mais de cache-busting manual, já que o token da URL
      // assinada muda a cada chamada.
      final updated = await widget.client.updateProfile(
        realName: _realNameController.text.trim().isEmpty ? null : _realNameController.text.trim(),
        photoPath: path,
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
    } on ApiException catch (e) {
      debugPrint('MENTAL: falha ao salvar o path da foto no perfil: ${e.code} — ${e.message}');
      if (mounted) setState(() => _error = e.message);
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
        // photoPath fica de fora aqui de propósito: este botão só salva
        // nome/localização. A foto é enviada separadamente em
        // _pickAndUploadPhoto — reenviar _photoUrl aqui mandaria a URL
        // assinada de exibição como se fosse um path, o que falharia
        // na validação do backend.
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
