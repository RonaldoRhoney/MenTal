import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// MENTAL_FLUXO_GUEST_3_QUESTOES_DIAGNOSTICO_TECNICO_V1.md §3.3 — estado
/// local das 3 questões respondidas SEM conta, antes do login. Guarda só
/// dados brutos (challenge_id + resposta enviada), nunca "acertei ou
/// errei" como fonte de verdade pra XP: quem decide isso de novo é
/// sempre o backend, em /guest/migrate-progress, depois do cadastro —
/// `isCorrect` aqui serve só pra UI (tela de resultado parcial).
class GuestAnswer {
  const GuestAnswer({
    required this.challengeId,
    required this.submittedAnswer,
    required this.isCorrect,
    required this.xpPreview,
    required this.completionToken,
  });

  final String challengeId;
  final String submittedAnswer;
  final bool isCorrect;
  // Exibição apenas (tela de resultado parcial) — o mesmo valor que
  // POST /guest/challenges/{id}/answer devolveu em xp_preview, nunca
  // recalculado no cliente. O XP de verdade sai de /guest/migrate-
  // progress, recalculado do zero pelo backend.
  final int xpPreview;
  // Achado crítico de auditoria de segurança (09/10/2026) — recibo
  // assinado devolvido por POST /guest/challenges/{id}/answer, provando
  // que ESTE (challengeId, submittedAnswer) foi gradeado de verdade
  // pelo fluxo guest. Exigido por POST /guest/migrate-progress; sem
  // isso, qualquer par challenge_id+submitted_answer "correto" virava
  // XP e progresso de território reais sem nunca ter sido jogado.
  final String completionToken;

  Map<String, dynamic> toJson() => {
        'challenge_id': challengeId,
        'submitted_answer': submittedAnswer,
        'is_correct': isCorrect,
        'xp_preview': xpPreview,
        'completion_token': completionToken,
      };

  static GuestAnswer fromJson(Map<String, dynamic> json) => GuestAnswer(
        challengeId: json['challenge_id'] as String,
        submittedAnswer: json['submitted_answer'] as String,
        isCorrect: json['is_correct'] as bool,
        xpPreview: json['xp_preview'] as int? ?? 0,
        completionToken: json['completion_token'] as String? ?? '',
      );
}

class GuestChallengeService {
  GuestChallengeService._();

  static const _kTerritoryIdKey = 'guest_flow_territory_id_v1';
  static const _kAnswersKey = 'guest_flow_answers_v1';
  static const _kDismissedKey = 'guest_flow_dismissed_v1';

  static const maxQuestions = 3;

  static Future<String?> getTerritoryId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_kTerritoryIdKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> setTerritoryId(String territoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTerritoryIdKey, territoryId);
    } catch (_) {}
  }

  static Future<List<GuestAnswer>> getAnswers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_kAnswersKey) ?? const [];
      return raw.map((s) => GuestAnswer.fromJson(jsonDecode(s) as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  static Future<void> addAnswer(GuestAnswer answer) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_kAnswersKey) ?? const [];
      await prefs.setStringList(_kAnswersKey, [...current, jsonEncode(answer.toJson())]);
    } catch (_) {}
  }

  /// Botão "Já tenho conta" (pode pular o fluxo guest a qualquer
  /// momento, mesmo sem ter respondido nenhuma questão ainda) e também
  /// marcado automaticamente depois que a migração pós-login é
  /// concluída — em ambos os casos, main.dart nunca mais deve oferecer
  /// o seletor de Mundo guest de novo neste dispositivo.
  static Future<bool> isDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_kDismissedKey) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> dismiss() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDismissedKey, true);
    } catch (_) {}
  }

  /// Limpa só o progresso guest (território + respostas) depois de uma
  /// migração bem-sucedida — `dismiss()` é setado à parte, nunca
  /// implícito aqui, pra um clear no meio de uma tentativa de migração
  /// que falhou não destravar o seletor de novo sem querer.
  static Future<void> clearProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kTerritoryIdKey);
      await prefs.remove(_kAnswersKey);
    } catch (_) {}
  }
}
