import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';

/// Tela de Configurações — controle do usuário sobre som
/// (AUDIO_FEEDBACK.md §3, requisito não-negociável): toggle on/off e
/// volume, persistidos localmente (nunca vão ao backend, não são dado de
/// jogo). DESIGN_SYSTEM.md aplicado desde a criação.
///
/// Seção de notificações (V2 item 8, NOTIFICATIONS.md §4) — ao contrário
/// do som, a preferência aqui vive no BACKEND (GET/PUT
/// /notifications/preferences): quem decide se envia é o job agendado no
/// servidor, que precisa conhecer a preferência antes de disparar, não
/// só o aparelho. O pedido de permissão do sistema + registro do token de
/// push fica para quando o projeto Firebase do MENTAL existir — até lá,
/// os toggles já funcionam (a preferência é salva e respeitada), só não
/// há token pra receber notificação de fato.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.client, this.signOut = _defaultSignOut});

  final ApiClient client;
  // Injeção só pra teste (evita a chamada de rede real do Supabase SDK,
  // que arma timers internos que sobrevivem ao fim do widget test) —
  // em produção sempre usa o signOut real do Supabase Auth.
  final Future<void> Function() signOut;

  static Future<void> _defaultSignOut() => Supabase.instance.client.auth.signOut();

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _soundEnabled = true;
  double _volume = 0.7;
  bool _reengagementEnabled = true;
  bool _socialEnabled = true;
  String? _notificationsError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await FeedbackService.instance.ensureLoaded();
    Map<String, dynamic>? prefs;
    try {
      prefs = await widget.client.getNotificationPreferences();
    } on ApiException catch (e) {
      if (mounted) setState(() => _notificationsError = e.message);
    }
    if (!mounted) return;
    setState(() {
      _soundEnabled = FeedbackService.instance.enabled;
      _volume = FeedbackService.instance.volume;
      if (prefs != null) {
        _reengagementEnabled = prefs['reengagement_enabled'] as bool;
        _socialEnabled = prefs['social_enabled'] as bool;
      }
      _loading = false;
    });
  }

  Future<void> _updateNotificationPreferences() async {
    try {
      await widget.client.updateNotificationPreferences(
        reengagementEnabled: _reengagementEnabled,
        socialEnabled: _socialEnabled,
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _notificationsError = e.message);
    }
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
                  const SizedBox(height: 28),
                  Text(l10n.notificationsSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.notifReengagementLabel),
                    subtitle: Text(l10n.notifReengagementDescription),
                    value: _reengagementEnabled,
                    onChanged: (value) {
                      setState(() => _reengagementEnabled = value);
                      _updateNotificationPreferences();
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.notifSocialLabel),
                    subtitle: Text(l10n.notifSocialDescription),
                    value: _socialEnabled,
                    onChanged: (value) {
                      setState(() => _socialEnabled = value);
                      _updateNotificationPreferences();
                    },
                  ),
                  if (_notificationsError != null) ...[
                    const SizedBox(height: 8),
                    Text(_notificationsError!, style: const TextStyle(color: AppColors.error)),
                  ],
                  const SizedBox(height: 28),
                  // Login real via Supabase Auth — main.dart
                  // (authStateChanges) já reconstrói a raiz pra LoginScreen
                  // sozinho quando a sessão cai. Mas essa tela chegou aqui
                  // via Navigator.push (empilhada por cima da raiz) —
                  // achado real (2026-08-26): sem o popUntil, essa tela
                  // (e qualquer outra empilhada, ex.: veio de dentro de um
                  // desafio) continuava visível por cima, escondendo a
                  // transição — o usuário só via o Login depois de voltar
                  // manualmente. Esvazia a pilha primeiro pra revelar a
                  // raiz, então encerra a sessão.
                  OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      // Fire-and-forget: a navegação já aconteceu acima,
                      // não precisa esperar a resposta de rede do signOut
                      // (main.dart já limpa a sessão local assim que o
                      // evento de auth chega, mesmo que a chamada de
                      // logout no servidor demore ou falhe).
                      unawaited(widget.signOut().catchError((_) {}));
                    },
                    child: Text(l10n.settingsSignOutButton),
                  ),
                ],
              ),
      ),
    );
  }
}
