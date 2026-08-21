import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Tela de idade neutra — obrigatória antes de qualquer coleta de dado não
/// essencial (FAMILY_SAFETY.md §3). Linguagem neutra, sem gamificação, sem
/// emoji, sem personagem falando — regra vinculante, não estética.
class AgeGateScreen extends StatefulWidget {
  const AgeGateScreen({super.key, required this.client, required this.onDone});

  final ApiClient client;
  final VoidCallback onDone;

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _submit(String ageMode) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.client.ageGate(ageMode);
      widget.onDone();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.ageGateTitle,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.ageGateSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_loading) const Center(child: CircularProgressIndicator()),
              if (!_loading) ...[
                FilledButton(
                  onPressed: () => _submit('child'),
                  child: Text(l10n.ageGateChildOption),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => _submit('adult'),
                  child: Text(l10n.ageGateAdultOption),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
