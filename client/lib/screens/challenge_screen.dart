import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../api/api_client.dart';

/// Ciclo completo de um desafio: busca → responde → resultado → próximo.
/// Uma ação primária por vez (Clareza Imediata, PRODUCT_PRINCIPLES.md §1):
/// enquanto o desafio está aberto, o CTA é "Confirmar resposta"; depois de
/// respondido, vira "Próximo desafio". Dica é sempre secundária/opcional.
class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({
    super.key,
    required this.client,
    required this.territoryId,
    required this.territoryLabel,
  });

  final ApiClient client;
  final String territoryId;
  final String territoryLabel;

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  static const _uuid = Uuid();

  bool _loading = true;
  String? _error;
  String? _errorCode;
  Map<String, dynamic>? _challenge;
  String? _attemptId;
  String? _selectedOption;
  List<String> _hintsShown = [];
  bool _hintsExhausted = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadNextChallenge();
  }

  Future<void> _loadNextChallenge() async {
    setState(() {
      _loading = true;
      _error = null;
      _errorCode = null;
      _challenge = null;
      _result = null;
      _selectedOption = null;
      _hintsShown = [];
      _hintsExhausted = false;
      _attemptId = _uuid.v4();
    });
    try {
      final challenge = await widget.client.nextChallenge(widget.territoryId);
      if (mounted) setState(() => _challenge = challenge);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorCode = e.code;
          if (e.code == 'DAILY_LIMIT_REACHED') {
            _error = 'Você usou seus desafios grátis de hoje. Volte amanhã!';
          } else if (e.code == 'TERRITORY_LOCKED') {
            _error = 'Este território exige assinatura.';
          } else {
            _error = e.message;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestHint() async {
    final challenge = _challenge;
    final attemptId = _attemptId;
    if (challenge == null || attemptId == null) return;
    try {
      final hint = await widget.client.requestHint(challenge['challenge_id'], attemptId);
      setState(() => _hintsShown = [..._hintsShown, hint['content'] as String]);
    } on ApiException catch (e) {
      // NO_MORE_HINTS não é um erro que trava a tela — o jogador só não
      // tem mais dica pra pedir nesse desafio. Achado testando no
      // celular real: sem esse tratamento, o botão "Pedir uma dica"
      // ficava clicável sem nenhum feedback visual do que aconteceu.
      if (e.code == 'NO_MORE_HINTS') {
        setState(() => _hintsExhausted = true);
      } else {
        setState(() => _error = e.message);
      }
    }
  }

  Future<void> _submitAnswer() async {
    final challenge = _challenge;
    final attemptId = _attemptId;
    final answer = _selectedOption;
    if (challenge == null || attemptId == null || answer == null) return;

    setState(() => _loading = true);
    try {
      final result = await widget.client.submitAnswer(challenge['challenge_id'], attemptId, answer);
      if (mounted) setState(() => _result = result);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.territoryLabel)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      // Feedback explícito durante possível cold start do backend
      // (ARCHITECTURE.md §3) — nunca tela em branco.
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Preparando seu desafio...'),
          ],
        ),
      );
    }

    if (_error != null && _challenge == null) {
      // DAILY_LIMIT_REACHED e TERRITORY_LOCKED não são erros transitórios
      // — reenviar a mesma requisição nunca vai funcionar (limite só
      // libera no dia seguinte, ou é fora do escopo deste slice destravar
      // via assinatura). "Tentar de novo" nesses casos é uma promessa
      // falsa; achado testando no celular real. Só oferece retry de
      // verdade para erros que podem mesmo ter sido transitórios (rede,
      // backend acordando de cold start).
      final isPermanentForToday = _errorCode == 'DAILY_LIMIT_REACHED' || _errorCode == 'TERRITORY_LOCKED';
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (isPermanentForToday)
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Voltar para o início'),
              )
            else
              FilledButton(onPressed: _loadNextChallenge, child: const Text('Tentar de novo')),
          ],
        ),
      );
    }

    final result = _result;
    if (result != null) {
      return _buildResult(result);
    }

    return _buildChallenge();
  }

  Widget _buildChallenge() {
    final challenge = _challenge!;
    final options = (challenge['options'] as List?)?.cast<String>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(challenge['prompt'] as String, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        if (options != null)
          RadioGroup<String>(
            groupValue: _selectedOption,
            onChanged: (value) => setState(() => _selectedOption = value),
            child: Column(
              children: options
                  .map((option) => RadioListTile<String>(title: Text(option), value: option))
                  .toList(),
            ),
          )
        else
          TextField(
            decoration: const InputDecoration(labelText: 'Sua resposta'),
            // Bug achado testando no celular real: sem setState aqui, o
            // botão "Confirmar resposta" (que depende de
            // _selectedOption != null) não reavaliava ao digitar — só
            // reabilitava quando algum outro evento forçava rebuild.
            onChanged: (value) => setState(() => _selectedOption = value.trim().isEmpty ? null : value),
          ),
        const SizedBox(height: 16),
        ..._hintsShown.map(
          (hint) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('Dica: $hint', style: const TextStyle(fontStyle: FontStyle.italic)),
          ),
        ),
        if (_hintsExhausted)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Sem mais dicas para este desafio.', style: TextStyle(fontStyle: FontStyle.italic)),
          )
        else
          TextButton(onPressed: _requestHint, child: const Text('Pedir uma dica')),
        const Spacer(),
        FilledButton(
          onPressed: _selectedOption == null ? null : _submitAnswer,
          child: const Text('Confirmar resposta'),
        ),
      ],
    );
  }

  Widget _buildResult(Map<String, dynamic> result) {
    final isCorrect = result['is_correct'] as bool;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isCorrect ? 'Você acertou!' : 'Não foi dessa vez.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Resposta correta: ${result['correct_answer']}'),
        const SizedBox(height: 12),
        Text(result['explanation'] as String),
        const SizedBox(height: 12),
        Text('XP ganho: ${result['xp_awarded']} (base: ${result['xp_base']}, dicas usadas: ${result['hints_used']})'),
        const Spacer(),
        FilledButton(onPressed: _loadNextChallenge, child: const Text('Próximo desafio')),
      ],
    );
  }
}
