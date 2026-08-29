import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/photo_picker_service.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_photo.dart';

/// Cadastro mínimo obrigatório (decisão de Rhoney, 26/08/2026, revisado
/// 28/08/2026): nome, país, cidade, faixa etária e foto de perfil são
/// exigidos antes de liberar o jogo — gênero passou a ser OPCIONAL
/// nessa revisão. Mostrada uma única vez por conta — main.dart checa
/// GET /profile (campo onboarding_completed_at) e só exibe esta tela
/// quando ainda não preenchido. USER_PROFILE.md §1/§3 tratava nome/
/// localização como 100% opcional (e bloqueava especificamente "cidade
/// exata" por risco de localizar um menor) — restrição que deixou de
/// fazer sentido com o MENTAL exclusivo pra 18+ desde a DIR-001.
class MandatoryOnboardingScreen extends StatefulWidget {
  const MandatoryOnboardingScreen({super.key, required this.client, required this.onDone, this.pickAndUploadPhoto = _defaultPickAndUploadPhoto});

  final ApiClient client;
  final VoidCallback onDone;
  // Injeção só pra teste (evita picker nativo + upload real do Supabase
  // Storage, que exigiriam mockar plataforma/rede) — mesmo padrão já
  // usado em SettingsScreen.signOut. Em produção sempre usa o fluxo
  // real de escolher + subir a foto, devolvendo o PATH resultante (ou
  // null se o usuário cancelou o picker / não há sessão).
  final Future<String?> Function(BuildContext context) pickAndUploadPhoto;

  // 29/08/2026 (pedido de Rhoney): tirar foto na hora (câmera) além de
  // escolher da galeria, e recortar antes de salvar — PhotoPickerService
  // cobre fonte + recorte 1:1; aqui só o upload em si, igual a
  // profile_screen.dart.
  static Future<String?> _defaultPickAndUploadPhoto(BuildContext context) async {
    final croppedFile = await PhotoPickerService.pickAndCrop(context);
    if (croppedFile == null) return null;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    // Achado real (29/08/2026, profile_screen.dart): pickers de galeria
    // Android vindos de content:// resolvers (Google Fotos, etc.) podem
    // devolver um path SEM extensão reconhecível — sem esse fallback, o
    // backend rejeitava o path (_is_valid_photo_path exige uma extensão
    // permitida), quebrando o onboarding obrigatório silenciosamente.
    final rawExt = croppedFile.path.contains('.') ? croppedFile.path.split('.').last.toLowerCase() : '';
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    final ext = allowedExtensions.contains(rawExt) ? rawExt : 'jpg';
    final path = '$userId/photo.$ext';
    await Supabase.instance.client.storage.from('profile-photos').upload(
          path,
          croppedFile,
          fileOptions: const FileOptions(upsert: true),
        );
    return path;
  }

  @override
  State<MandatoryOnboardingScreen> createState() => _MandatoryOnboardingScreenState();
}

class _MandatoryOnboardingScreenState extends State<MandatoryOnboardingScreen> {
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  String? _gender;
  String? _ageRange;
  String? _photoPath;
  bool _uploadingPhoto = false;
  bool _saving = false;
  String? _error;

  static const _genderValues = ['masculino', 'feminino', 'nao_binario', 'prefiro_nao_informar'];
  // Revisão 28/08/2026 (decisão de Rhoney): 4 faixas em vez das 5
  // anteriores (18-25/26-30/31-45/46-50/51+).
  static const _ageRangeValues = ['18-25', '26-35', '36-45', '46+'];

  @override
  void dispose() {
    _nameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      _countryController.text.trim().isNotEmpty &&
      _cityController.text.trim().isNotEmpty &&
      _ageRange != null &&
      _photoPath != null;

  Future<void> _pickAndUploadPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _uploadingPhoto = true;
      _error = null;
    });
    try {
      // widget.pickAndUploadPhoto mostra o bottom sheet de fonte + o
      // editor de recorte, depois sobe a foto — cobre a etapa inteira
      // (não só a espera de rede), então o spinner do botão fica visível
      // por baixo do bottom sheet/editor nativo enquanto o usuário
      // interage, o que é inofensivo.
      final path = await widget.pickAndUploadPhoto(context);
      if (!mounted || path == null) return;
      setState(() => _photoPath = path);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.profilePhotoUploadError);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_canContinue || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.client.updateProfile(
        realName: _nameController.text.trim(),
        locationCountry: _countryController.text.trim(),
        city: _cityController.text.trim(),
        gender: _gender,
        ageRange: _ageRange,
        photoPath: _photoPath,
        locationPublic: false,
      );
      widget.onDone();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _genderLabel(AppLocalizations l10n, String value) {
    switch (value) {
      case 'masculino':
        return l10n.onboardingGenderMasculino;
      case 'feminino':
        return l10n.onboardingGenderFeminino;
      case 'nao_binario':
        return l10n.onboardingGenderNaoBinario;
      default:
        return l10n.onboardingGenderPrefiroNaoInformar;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            Text(l10n.onboardingTitle, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(l10n.onboardingSubtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 32),
            Text(l10n.onboardingPhotoTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                const ProfilePhotoCircle(photoUrl: null, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
                    child: _uploadingPhoto
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_photoPath == null ? l10n.profilePhotoChangeButton : l10n.onboardingPhotoChosenLabel),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.onboardingNameLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _countryController,
              decoration: InputDecoration(labelText: l10n.onboardingCountryLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(labelText: l10n.onboardingCityLabel),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            // Revisão 28/08/2026: gênero agora é OPCIONAL — título indica
            // isso, e não entra em _canContinue.
            Text(l10n.onboardingGenderOptionalTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in _genderValues)
                  ChoiceChip(
                    label: Text(_genderLabel(l10n, value)),
                    selected: _gender == value,
                    selectedColor: AppColors.teal.withValues(alpha: 0.25),
                    side: BorderSide(color: _gender == value ? AppColors.teal : AppColors.muted),
                    onSelected: (_) => setState(() => _gender = _gender == value ? null : value),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(l10n.onboardingAgeRangeTitle, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final value in _ageRangeValues)
                  ChoiceChip(
                    label: Text(value),
                    selected: _ageRange == value,
                    selectedColor: AppColors.gold.withValues(alpha: 0.25),
                    side: BorderSide(color: _ageRange == value ? AppColors.gold : AppColors.muted),
                    onSelected: (_) => setState(() => _ageRange = value),
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: (_canContinue && !_saving) ? _submit : null,
              child: Text(l10n.onboardingContinueButton),
            ),
          ],
        ),
      ),
    );
  }
}
