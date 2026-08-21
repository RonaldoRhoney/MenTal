import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';

/// Tela de Configurações — controle do usuário sobre som
/// (AUDIO_FEEDBACK.md §3, requisito não-negociável): toggle on/off e
/// volume, persistidos localmente (nunca vão ao backend, não são dado de
/// jogo). DESIGN_SYSTEM.md aplicado desde a criação.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _soundEnabled = true;
  double _volume = 0.7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await FeedbackService.instance.ensureLoaded();
    if (!mounted) return;
    setState(() {
      _soundEnabled = FeedbackService.instance.enabled;
      _volume = FeedbackService.instance.volume;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsScreenTitle)),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(l10n.soundSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.soundToggleLabel),
                    value: _soundEnabled,
                    onChanged: (value) async {
                      setState(() => _soundEnabled = value);
                      await FeedbackService.instance.setEnabled(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.soundVolumeLabel),
                  Slider(
                    value: _volume,
                    onChanged: _soundEnabled
                        ? (value) async {
                            setState(() => _volume = value);
                            await FeedbackService.instance.setVolume(value);
                          }
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.soundSilencedNote,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ],
              ),
      ),
    );
  }
}
