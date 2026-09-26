import 'package:flutter/material.dart';

import '../services/health_steps_source.dart';
import '../theme/app_theme.dart';

/// Cartão compacto do Health Connect na tela Movimento (Movimento/HealthConnect/
/// DESENHO_TECNICO_V1.md, aprovado por Rhoney em 25/09/2026). Só EXIBE os
/// passos de hoje vindos de relógio/outros apps — nada daqui vale XP nem
/// MentalCoins e nada é enviado ao servidor (decisão de Rhoney: "passos vindos
/// de relógio não contam para XP e MentalCoins").
///
/// Estados: indisponível → não ocupa espaço (sem Health Connect no aparelho);
/// sem permissão → botão "Conectar" (o consentimento só é pedido ao toque);
/// conectado → total do dia de Brasília.
class HealthConnectCard extends StatefulWidget {
  const HealthConnectCard({super.key, required this.source});

  final HealthStepsSource source;

  @override
  State<HealthConnectCard> createState() => _HealthConnectCardState();
}

class _HealthConnectCardState extends State<HealthConnectCard> {
  HealthStepsStatus? _status;
  int? _steps;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final status = await widget.source.status();
    final steps = status == HealthStepsStatus.connected ? await widget.source.todaySteps() : null;
    if (!mounted) return;
    setState(() {
      _status = status;
      _steps = steps;
    });
  }

  Future<void> _connect() async {
    if (_busy) return;
    setState(() => _busy = true);
    await widget.source.requestPermission();
    await _refresh();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    if (status == null || status == HealthStepsStatus.unavailable) {
      return const SizedBox.shrink(key: Key('health_connect_hidden'));
    }
    return Container(
      key: const Key('health_connect_card'),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.watch_rounded, size: 18, color: AppColors.teal),
          const SizedBox(width: 8),
          Expanded(
            child: status == HealthStepsStatus.connected
                ? Text(
                    _steps == null
                        ? 'Health Connect conectado — sem dados de hoje'
                        : 'Health Connect: $_steps passos hoje (não geram XP)',
                    key: const Key('health_connect_text'),
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  )
                : Text(
                    'Ver passos de relógio e outros apps (Health Connect)',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
          ),
          if (status == HealthStepsStatus.notPermitted)
            TextButton(
              key: const Key('health_connect_button'),
              onPressed: _busy ? null : _connect,
              child: const Text('Conectar'),
            ),
        ],
      ),
    );
  }
}
