import 'package:firebase_messaging/firebase_messaging.dart';

import '../api/api_client.dart';

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

  /// Pede permissão, obtém o token do FCM e registra no backend. Também
  /// escuta `onTokenRefresh` (o token pode mudar depois da instalação,
  /// ex.: restauração de backup) para manter o backend sempre com o
  /// token válido mais recente.
  Future<void> initializeAndRegister(ApiClient client) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return; // Sem permissão, sem token — feature fica invisível, sem penalização.
      }

      final token = await messaging.getToken();
      if (token != null) {
        await client.registerPushToken(token);
      }

      messaging.onTokenRefresh.listen((newToken) async {
        try {
          await client.registerPushToken(newToken);
        } catch (_) {
          // Falha ao reenviar token não pode derrubar o app — a próxima
          // abertura tenta de novo.
        }
      });
    } catch (_) {
      // Firebase pode não estar configurado em todo ambiente (ex.: build
      // de desenvolvimento sem google-services.json) — notificações são
      // reforço, nunca requisito para o app funcionar.
    }
  }
}
