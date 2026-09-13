import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_client.dart';
import '../brazil_states.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/photo_picker_service.dart';
import '../theme/app_theme.dart';
import '../widgets/city_autocomplete_field.dart';
import '../widgets/profile_photo.dart';

/// USER_PROFILE.md (aprovado). Nome real/localização são opcionais aqui
/// (podem já ter sido preenchidos no onboarding obrigatório) — nenhum
/// bloqueia ou degrada o uso do app se não preenchidos. O backend é a
/// única autoridade sobre o que fica salvo; esta tela só carrega/edita.
///
/// Upload de foto real (revisão 27/08/2026 — USER_PROFILE.md §3.1)
/// substitui o antigo picker de avatar emoji: a imagem sobe direto pro
/// Supabase Storage (bucket privado `profile-photos` desde 28/08/2026),
/// e só o PATH resultante é enviado ao backend em PUT /profile — o
/// backend nunca recebe bytes de imagem, só valida a forma do path.
///
/// Revisão 13/09/2026 (decisão de Rhoney): visibilidade pra outros
/// usuários é escolha do próprio dono (photoIsPublic, toggle nesta
/// tela), não mais aprovação de admin.
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
  // Revisão 13/09/2026 (decisão de Rhoney): visibilidade da foto passa a
  // ser escolha do usuário, não mais aprovação de admin.
  bool _photoIsPublic = true;
  final _realNameController = TextEditingController();
  // Pedido de Rhoney (12/09/2026): Estado deixou de ser texto livre —
  // ver client/lib/brazil_states.dart. Sigla de UF ou null (nunca um
  // valor fora da lista, garantido pelo dropdown).
  String? _selectedStateUf;
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  bool _locationPublic = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _realNameController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await widget.client.getProfile();
      if (mounted) {
        setState(() {
          _photoUrl = profile['photo_url'] as String?;
          _photoModerationStatus =
              profile['photo_moderation_status'] as String?;
          _photoIsPublic = profile['photo_is_public'] as bool? ?? true;
          _realNameController.text = profile['real_name'] as String? ?? '';
          // Dado legado gravado como texto livre (antes desta mudança)
          // pode não bater com nenhuma sigla válida — nesse caso fica
          // sem seleção em vez de arriscar mapear errado.
          final existingState = profile['location_state'] as String?;
          _selectedStateUf = kBrazilStates.any((s) => s.uf == existingState)
              ? existingState
              : null;
          _countryController.text =
              profile['location_country'] as String? ?? '';
          _cityController.text = profile['city'] as String? ?? '';
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
    final rawExt = croppedFile.path.contains('.')
        ? croppedFile.path.split('.').last.toLowerCase()
        : '';
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
        realName: _realNameController.text.trim().isEmpty
            ? null
            : _realNameController.text.trim(),
        photoPath: path,
        photoIsPublic: _photoIsPublic,
        locationState: _selectedStateUf,
        locationCountry: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        locationPublic: _locationPublic,
      );
      if (mounted) {
        setState(() {
          _photoUrl = updated['photo_url'] as String?;
          _photoModerationStatus =
              updated['photo_moderation_status'] as String?;
          _photoIsPublic = updated['photo_is_public'] as bool? ?? true;
        });
      }
    } on ApiException catch (e) {
      debugPrint(
          'MENTAL: falha ao salvar o path da foto no perfil: ${e.code} — ${e.message}');
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
        realName: _realNameController.text.trim().isEmpty
            ? null
            : _realNameController.text.trim(),
        // photoPath fica de fora aqui de propósito: este botão só salva
        // nome/localização. A foto é enviada separadamente em
        // _pickAndUploadPhoto — reenviar _photoUrl aqui mandaria a URL
        // assinada de exibição como se fosse um path, o que falharia
        // na validação do backend. photoIsPublic vai mesmo sem foto
        // nova: é o toggle de visibilidade da foto já existente.
        photoIsPublic: _photoIsPublic,
        locationState: _selectedStateUf,
        locationCountry: _countryController.text.trim().isEmpty
            ? null
            : _countryController.text.trim(),
        city: _cityController.text.trim().isEmpty
            ? null
            : _cityController.text.trim(),
        locationPublic: _locationPublic,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.profileSavedMessage)),
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
            // Pedido de Rhoney (04/09/2026): pull-to-refresh em qualquer
            // tela do app.
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.gold,
                // Redesign 13/09/2026 (pedido de Rhoney: "mais elegante,
                // profissional, proporções mais amigáveis", depois
                // ajustado pra caber tudo numa tela só sem rolar em
                // dispositivos como o Moto G22 testado ao vivo) — 2
                // cartões (Seu perfil / Localização) em vez de 3, espaço
                // reduzido entre eles e dentro deles, textos de apoio
                // encurtados pra 1 linha, País+Estado lado a lado.
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    children: [
                      _ProfileSectionCard(
                        icon: Icons.person_outline_rounded,
                        title: l10n.profilePhotoSectionTitle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ProfilePhotoCircle(
                                    photoUrl: _photoUrl, size: 64),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: _uploadingPhoto
                                        ? null
                                        : _pickAndUploadPhoto,
                                    style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(40)),
                                    child: _uploadingPhoto
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          )
                                        : Text(l10n.profilePhotoChangeButton),
                                  ),
                                ),
                              ],
                            ),
                            if (_photoModerationStatus == 'rejected') ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.profilePhotoRejectedLabel,
                                style: TextStyle(
                                    color: AppColors.error, fontSize: 12),
                              ),
                            ],
                            // Revisão 13/09/2026 (decisão de
                            // Rhoney): visibilidade da foto é
                            // escolha do usuário, não mais
                            // aprovação de admin — some quando
                            // 'rejected' (override do admin em
                            // resposta a denúncia), já que nesse
                            // caso a escolha do usuário não tem
                            // efeito mesmo.
                            if (_photoModerationStatus != 'rejected')
                              _CompactSwitchRow(
                                title: l10n.profilePhotoPublicToggleLabel,
                                value: _photoIsPublic,
                                onChanged: (value) =>
                                    setState(() => _photoIsPublic = value),
                              ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: _realNameController,
                              decoration: InputDecoration(
                                labelText: l10n.profileRealNameLabel,
                                helperText: l10n.profileRealNameHelperText,
                                helperMaxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ProfileSectionCard(
                        icon: Icons.location_on_outlined,
                        title: l10n.profileLocationSectionTitle,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ordem pedida por Rhoney (12/09/2026):
                            // País → Estado → Cidade — mesma ordem
                            // já usada no onboarding obrigatório
                            // (mandatory_onboarding_screen.dart).
                            // País+Estado lado a lado economiza uma
                            // linha inteira de altura.
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextField(
                                    controller: _countryController,
                                    decoration: InputDecoration(
                                        labelText:
                                            l10n.profileLocationCountryLabel),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _selectedStateUf,
                                    decoration: InputDecoration(
                                        labelText:
                                            l10n.profileLocationStateLabel),
                                    isExpanded: true,
                                    items: [
                                      for (final state in kBrazilStates)
                                        DropdownMenuItem(
                                          value: state.uf,
                                          // Nome completo no popup (fácil
                                          // de reconhecer ao escolher);
                                          // selectedItemBuilder abaixo
                                          // mostra só a sigla no campo
                                          // fechado, que é onde o espaço é
                                          // realmente apertado (Row
                                          // dividida com País).
                                          child: Text(
                                              '${state.name} (${state.uf})'),
                                        ),
                                    ],
                                    selectedItemBuilder: (context) => [
                                      for (final state in kBrazilStates)
                                        Text(state.uf),
                                    ],
                                    onChanged: (value) => setState(
                                        () => _selectedStateUf = value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            CityAutocompleteField(
                              stateUf: _selectedStateUf,
                              controller: _cityController,
                              labelText: l10n.onboardingCityLabel,
                            ),
                            _CompactSwitchRow(
                              title: l10n.profileLocationPublicLabel,
                              value: _locationPublic,
                              onChanged: (value) =>
                                  setState(() => _locationPublic = value),
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Text(_error!,
                            style: TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44)),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(l10n.profileSaveButton),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// Cartão de seção reutilizado nas 3 áreas da tela (Foto/Nome/Localização)
/// — mesmo padrão visual já estabelecido no card de Progresso da Home
/// (AppColors.bg2 + borda dourada suave, radius 18), pra dar hierarquia
/// e "respiro" entre seções em vez da lista corrida de campos soltos
/// que existia antes (pedido de Rhoney, 13/09/2026: "mais elegante,
/// profissional, proporções mais amigáveis").
class _ProfileSectionCard extends StatelessWidget {
  const _ProfileSectionCard(
      {required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      // Material(transparency) evita o aviso do framework de que o
      // SwitchListTile dentro do card (Foto pública/Localização
      // pública) perderia o ink splash por causa do Container colorido
      // logo acima na árvore — sem mudar nada visualmente.
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.gold, size: 22),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(title,
                        style: Theme.of(context).textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Linha de toggle compacta (1 linha, sem subtítulo explicativo) — troca
/// o SwitchListTile de 3 linhas usado antes, parte do ajuste pra caber
/// a tela de Perfil inteira sem rolar (pedido de Rhoney, 13/09/2026). O
/// título de cada toggle já é autoexplicativo o bastante sem o texto de
/// apoio.
class _CompactSwitchRow extends StatelessWidget {
  const _CompactSwitchRow(
      {required this.title, required this.value, required this.onChanged});

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.bodyMedium)),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
