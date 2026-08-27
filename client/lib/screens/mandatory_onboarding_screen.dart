import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Cadastro mínimo obrigatório (decisão de Rhoney, 2026-08-26): nome,
/// país, cidade, gênero e faixa etária, exigidos antes de liberar o
/// jogo. Mostrada uma única vez por conta — main.dart checa GET /profile
/// (campo onboarding_completed_at) e só exibe esta tela quando ainda
/// não preenchido. USER_PROFILE.md §1/§3 tratava nome/localização como
/// 100% opcional (e bloqueava especificamente "cidade exata" por risco
/// de localizar um menor) — restrição que deixou de fazer sentido com o
/// MENTAL exclusivo pra 18+ desde a DIR-001.
class MandatoryOnboardingScreen extends StatefulWidget {
  const MandatoryOnboardingScreen({super.key, required this.client, required this.onDone});

  final ApiClient client;
  final VoidCallback onDone;

  @override
  State<MandatoryOnboardingScreen> createState() => _MandatoryOnboardingScreenState();
}

class _MandatoryOnboardingScreenState extends State<MandatoryOnboardingScreen> {
  final _nameController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  String? _gender;
  String? _ageRange;
  bool _saving = false;
  String? _error;

  static const _genderValues = ['masculino', 'feminino', 'nao_binario', 'prefiro_nao_informar'];
  static const _ageRangeValues = ['18-25', '26-30', '31-45', '46-50', '51+'];

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
      _gender != null &&
      _ageRange != null;

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
            Text(l10n.onboardingGenderTitle, style: Theme.of(context).textTheme.titleLarge),
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
                    onSelected: (_) => setState(() => _gender = value),
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
