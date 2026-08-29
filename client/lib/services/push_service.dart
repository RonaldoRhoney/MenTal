import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// V2 item 8 — Notificações (NOTIFICATIONS.md). O backend é a única
/// autoridade sobre QUANDO e SE notificar (app/notifications.py) — este
/// serviço só cuida do lado do dispositivo: pedir permissão, obter o
/// token do FCM e mantê-lo atualizado no backend via
/// POST /notifications/register-token. Nunca decide conteúdo/timing de
/// notificação, só entrega o "endereço" pra onde o backend pode enviar.
///
/// Resiliente por design (mesmo princípio de FeedbackService/
/// MovementService): qualquer falha aqui (permissão negada, Firebase mal
/// configurado, sem rede) nunca pode travar ou quebrar o resto do app —
/// a notificação passa a simplesmente não chegar, sem penalizar o
/// usuário nem impedir uso do app.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _tokenRefreshListenerAttached = false;

  // Auditoria de conformidade Google Play (29/08/2026, item 4): antes,
  // o diálogo padrão do sistema (POST_NOTIFICATIONS) aparecia direto no
  // login, sem nenhuma explicação do app antes — só a explicação do
  // próprio Android, insuficiente pra boa prática de permissão sensível.
  // Esta chave marca que o usuário já passou pelo diálogo REAL do
  // sistema pelo menos uma vez — enquanto isso não acontecer (ex.:
  // usuário disse "agora não" no priming), volta a perguntar no próximo
  // login, em vez de desistir de vez.
  static const _kPermissionDeterminedKey = 'push_permission_determined';

  /// Pede permissão, obtém o token do FCM e registra no backend. Também
  /// escuta `onTokenRefresh` (o token pode mudar depois da instalação,
  /// ex.: restauração de backup) para manter o backend sempre com o
  /// token válido mais recente.
  ///
  /// Idempotente por design: se o chamador invocar isso mais de uma vez
  /// na mesma sessão do app (ex.: main.dart reagindo a outro evento de
  /// auth), não deve empilhar um novo listener de onTokenRefresh a cada
  /// chamada — visto em produção causando um loop de registro de token
  /// quase 1x/segundo, saturando conexões do backend.
  Future<void> initializeAndRegister(ApiClient client, BuildContext context) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final prefs = await SharedPreferences.getInstance();
      final alreadyDetermined = prefs.getBool(_kPermissionDeterminedKey) ?? false;

      if (!alreadyDetermined) {
        if (!context.mounted) return;
        final wantsToEnable = await _showPrimingDialog(context);
        if (!context.mounted) return;
        if (!wantsToEnable) return; // Não marca como "determined" — pode perguntar de novo no próximo login.
      }

      final settings = await messaging.requestPermission();
      await prefs.setBool(_kPermissionDeterminedKey, true);
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return; // Sem permissão, sem token — feature fica invisível, sem penalização.
      }

      final token = await messaging.getToken();
      if (token != null) {
        await client.registerPushToken(token);
      }

      if (!_tokenRefreshListenerAttached) {
        _tokenRefreshListenerAttached = true;
        messaging.onTokenRefresh.listen((newToken) async {
          try {
            await client.registerPushToken(newToken);
          } catch (_) {
            // Falha ao reenviar token não pode derrubar o app — a próxima
            // abertura tenta de novo.
          }
        });
      }
    } catch (_) {
      // Firebase pode não estar configurado em todo ambiente (ex.: build
      // de desenvolvimento sem google-services.json) — notificações são
      // reforço, nunca requisito para o app funcionar.
    }
  }

  Future<bool> _showPrimingDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Text(l10n.pushPrimingDialogTitle),
        content: Text(l10n.pushPrimingDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.pushPrimingDialogDeclineButton),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.pushPrimingDialogAllowButton),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
