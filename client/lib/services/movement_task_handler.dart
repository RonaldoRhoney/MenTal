import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:pedometer/pedometer.dart';

import 'movement_service.dart';

/// V3.0.1 — mantém o listener do sensor de passos vivo com o app em
/// segundo plano/tela apagada (achado real, 29/08/2026: caminhada de
/// teste com o celular no bolso não contabilizou nenhum passo).
/// TYPE_STEP_COUNTER só entrega um evento quando um passo de verdade
/// acontece com um listener ATIVO naquele instante (ver comentário em
/// movement_service.dart) — sem um foreground service rodando, o
/// Android tende a suspender o processo do app com a tela apagada, o
/// listener morre, e a "leitura conhecida" salva localmente fica presa
/// no valor de antes da caminhada. O foreground service roda numa
/// engine Flutter separada, mantida viva pela notificação persistente
/// do Android — os plugins de canal do app (incluindo `pedometer`) já
/// vêm registrados nela.
@pragma('vm:entry-point')
void startMovementTaskCallback() {
  FlutterForegroundTask.setTaskHandler(MovementTaskHandler());
}

class MovementTaskHandler extends TaskHandler {
  StreamSubscription<StepCount>? _sub;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _sub = Pedometer.stepCountStream.listen(
      (event) async {
        await MovementService.instance.recordRawSteps(event.steps);
        FlutterForegroundTask.sendDataToMain({'steps': event.steps});
      },
      onError: (_) {},
    );
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _sub?.cancel();
  }
}
