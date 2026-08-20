import 'package:flutter/material.dart';

import '../api/api_client.dart';
import 'challenge_screen.dart';

const List<Map<String, String>> _kTerritories = [
  {'id': 'palavras', 'label': 'Palavras'},
  {'id': 'numeros', 'label': 'Números'},
  {'id': 'logica', 'label': 'Lógica'},
  {'id': 'conhecimento', 'label': 'Conhecimento'},
];

/// Home: um CTA primário claro por território, conforme Princípio de
/// Clareza Imediata (PRODUCT_PRINCIPLES.md §1) — nada compete visualmente
/// com "escolher território e jogar".
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    try {
      final progress = await widget.client.progress();
      if (mounted) setState(() => _progress = progress);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return Scaffold(
      appBar: AppBar(title: const Text('MENTAL')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progress != null)
                Text(
                  'XP: ${progress['xp_total']} · Nível ${progress['level']} · '
                  'Streak: ${progress['streak']['current_streak']} dias',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _kTerritories.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final territory = _kTerritories[index];
                    return FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChallengeScreen(
                              client: widget.client,
                              territoryId: territory['id']!,
                              territoryLabel: territory['label']!,
                            ),
                          ),
                        );
                        _loadProgress();
                      },
                      child: Text('Novo desafio — ${territory['label']}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
