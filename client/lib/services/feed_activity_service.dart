/// FEED_SOCIAL_V1.md — indicador de atividade nova no card "Amigos" da
/// Home (pedido de Rhoney, 06/09/2026, decisão registrada via
/// AskUserQuestion: "badge discreto no card Amigos" em vez de um
/// atalho novo na Home — o Feed é um recurso social secundário, não o
/// painel principal do jogo). "Visto" é rastreado só no dispositivo
/// (SharedPreferences), nunca no backend — não é dado que precise
/// sincronizar entre aparelhos, e mantém o endpoint GET /feed
/// puramente de leitura.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

class FeedActivityService {
  FeedActivityService._();

  static const _kLastSeenKey = 'feed_last_seen_created_at';

  /// Conta quantos eventos do Feed são mais recentes que a última vez
  /// que o jogador abriu a tela de Feed. Nunca lança — falha de rede
  /// aqui não pode quebrar a Home (mesmo princípio de
  /// _loadMovementBadge/_loadMentalCoinsBalance).
  static Future<int> unseenCount(ApiClient client) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString(_kLastSeenKey);
      final lastSeenAt = lastSeen != null ? DateTime.tryParse(lastSeen) : null;

      final result = await client.getFeed();
      final events = (result['events'] as List).cast<Map<String, dynamic>>();
      if (lastSeenAt == null) return events.length;

      return events.where((e) {
        final createdAt = DateTime.tryParse(e['created_at'] as String);
        return createdAt != null && createdAt.isAfter(lastSeenAt);
      }).length;
    } catch (_) {
      return 0;
    }
  }

  /// Chamado quando a tela de Feed termina de carregar — marca o
  /// evento mais recente da primeira página como "visto", pra próxima
  /// contagem em Home não repetir o que o jogador já viu.
  static Future<void> markSeen(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastSeenKey, events.first['created_at'] as String);
    } catch (_) {
      // Falha ao persistir "visto" não é crítica — pior caso, o badge
      // volta a contar o mesmo evento na próxima abertura da Home.
    }
  }
}
