import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';
import 'admin_metrics_screen.dart';
import 'onboarding_tutorial_screen.dart';

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
  bool _deletingAccount = false;
  List<Map<String, dynamic>> _blockedUsers = [];
  // U.I/ADMIN_PAINEL_IN_APP_V1.md — mesmo padrão já usado em
  // feedback_screen.dart (profile['role']): autorização de verdade
  // sempre no backend, isto aqui só decide o que aparece na UI.
  bool _isAdmin = false;

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
    List<Map<String, dynamic>> blocked = [];
    try {
      final blockedResponse = await widget.client.getBlockedUsers();
      blocked = (blockedResponse['blocked'] as List).cast<Map<String, dynamic>>();
    } on ApiException catch (_) {
      // Não bloqueia o resto da tela — lista de bloqueados fica vazia.
    }
    bool isAdmin = false;
    try {
      final profile = await widget.client.getProfile();
      isAdmin = profile['role'] == 'admin';
    } on ApiException catch (_) {
      // Item admin só é reforço de UI — nunca bloqueia a tela por causa disso.
    }
    if (!mounted) return;
    setState(() {
      _soundEnabled = FeedbackService.instance.enabled;
      _volume = FeedbackService.instance.volume;
      if (prefs != null) {
        _reengagementEnabled = prefs['reengagement_enabled'] as bool;
        _socialEnabled = prefs['social_enabled'] as bool;
      }
      _blockedUsers = blocked;
      _isAdmin = isAdmin;
      _loading = false;
    });
  }

  // Auditoria de conformidade Google Play (29/08/2026, item 6) — gestão
  // de bloqueios: sem isso, um bloqueio acidental (ou de reconciliação)
  // seria permanente, sem forma de desfazer.
  Future<void> _unblockUser(String userId) async {
    try {
      await widget.client.unblockUser(userId);
      if (mounted) setState(() => _blockedUsers.removeWhere((u) => u['user_id'] == userId));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
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

  // Achado de auditoria de segurança (28/08/2026) — DIR-001 item 5,
  // LGPD: exclusão real de conta, não só zerar campos. Confirmação
  // explícita (é irreversível) antes de chamar a API; em sucesso,
  // mesmo padrão de "Sair" logo abaixo — esvazia a pilha de navegação
  // primeiro pra revelar a tela de Login por baixo, só então encerra a
  // sessão local (o backend já apagou a conta do lado dele).
  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsDeleteAccountConfirmTitle),
        content: Text(l10n.settingsDeleteAccountConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.settingsDeleteAccountCancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsDeleteAccountConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingAccount = true);
    try {
      await widget.client.deleteAccount();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      unawaited(widget.signOut().catchError((_) {}));
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.code == 'ACCOUNT_DELETION_UNAVAILABLE' ? l10n.settingsDeleteAccountUnavailableError : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _deletingAccount = false);
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
            // Pedido de Rhoney (04/09/2026): pull-to-refresh em qualquer
            // tela do app.
            : RefreshIndicator(
                onRefresh: _load,
                color: AppColors.gold,
                child: ListView(
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
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  // "Como usar o MENTAL" (29/08/2026, pedido de Rhoney:
                  // "dê melhor destaque") — card com cor própria em vez
                  // de ListTile solto, mesma linguagem visual dos outros
                  // destaques do app (borda + fundo tintado). Sempre
                  // disponível pra rever, sem mexer na flag de "já visto"
                  // que controla a exibição automática após o splash
                  // (main.dart).
                  _HighlightedSettingsTile(
                    icon: Icons.help_outline_rounded,
                    color: AppColors.teal,
                    label: l10n.tutorialMenuLabel,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => OnboardingTutorialScreen(onDone: () => Navigator.of(context).pop())),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                    Text(_notificationsError!, style: TextStyle(color: AppColors.error)),
                  ],
                  if (_blockedUsers.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    Text(l10n.blockedUsersSectionTitle, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    for (final user in _blockedUsers)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        // Nome real substitui o apelido gerado pelo
                        // sistema assim que existir (29/08/2026, pedido
                        // de Rhoney).
                        title: Text(() {
                          final realName = user['real_name'] as String?;
                          return realName != null && realName.isNotEmpty ? realName : user['nickname'] as String;
                        }()),
                        trailing: OutlinedButton(
                          style: OutlinedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          onPressed: () => _unblockUser(user['user_id'] as String),
                          child: Text(l10n.unblockUserButton),
                        ),
                      ),
                  ],
                  if (_isAdmin) ...[
                    const SizedBox(height: 28),
                    // U.I/ADMIN_PAINEL_IN_APP_V1.md §2: "ponto de entrada
                    // sugerido... ou menu de Configurações" — só aparece
                    // pra role=admin, usuário comum nunca vê nem sabe que
                    // essa tela existe.
                    _HighlightedSettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      color: AppColors.gold,
                      label: l10n.adminMetricsMenuLabel,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => AdminMetricsScreen(client: widget.client)),
                      ),
                    ),
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
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error)),
                    onPressed: _deletingAccount ? null : _deleteAccount,
                    child: _deletingAccount
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.settingsDeleteAccountButton),
                  ),
                ],
              ),
                ),
      ),
    );
  }
}

/// Card de destaque em Ajuste (29/08/2026, pedido de Rhoney: "dê melhor
/// destaque em Como usar o MENTAL e no Painel Admin") — mesma
/// linguagem visual dos outros cards de destaque do app (fundo tintado
/// + borda na cor do ícone), em vez de um ListTile solto igual aos
/// toggles de som/notificação ao redor.
class _HighlightedSettingsTile extends StatelessWidget {
  const _HighlightedSettingsTile({required this.icon, required this.color, required this.label, required this.onTap});

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.4))),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: color)),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
