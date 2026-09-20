import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/services/movement_service.dart';

/// Achado real (20/09/2026): o celular reiniciou e o Movimento parou de contar
/// — o contador de hardware zera no boot e `atual - baseline` ficava negativo
/// (travado em 0) até o contador passar da leitura antiga.
void main() {
  final service = MovementService.instance;

  test(
      'estado ANTIGO (sem lastRaw) com leitura abaixo do baseline: recomeça de 0 e não perde o já enviado',
      () async {
    // Estado gravado antes da correção: baseline de antes do reboot, 62 passos já enviados.
    SharedPreferences.setMockInitialValues({
      'movement_cycle_state_v1': jsonEncode({
        'ciclo-legado': {'baseline': 20000, 'lastSubmittedTotal': 62},
      }),
    });
    final delta = await service.pendingDeltaFor(
        'ciclo-legado', 300); // contador zerou no boot
    expect(delta.totalStepsInCycle, 362); // 62 já contados + 300 desde o boot
    expect(delta.uncollectedSteps, 300);
  });

  test('sem reboot: conta normal (atual - baseline)', () async {
    await service.clear();
    SharedPreferences.setMockInitialValues({});
    expect((await service.pendingDeltaFor('c1', 1000)).totalStepsInCycle,
        0); // cria baseline
    final delta = await service.pendingDeltaFor('c1', 1500);
    expect(delta.totalStepsInCycle, 500);
    expect(delta.uncollectedSteps, 500);
  });

  test(
      'reboot no meio do ciclo: soma o que já tinha + o que veio depois do boot',
      () async {
    await service.clear();
    SharedPreferences.setMockInitialValues({});
    await service.pendingDeltaFor('c2', 1000);
    final before = await service.pendingDeltaFor('c2', 5000);
    expect(before.totalStepsInCycle, 4000);
    await service.markCollected('c2', 4000);

    final afterReboot = await service.pendingDeltaFor(
        'c2', 300); // leitura menor = contador zerou
    expect(afterReboot.totalStepsInCycle, 4300);
    expect(afterReboot.uncollectedSteps, 300);

    final later = await service.pendingDeltaFor(
        'c2', 800); // continua somando normalmente
    expect(later.totalStepsInCycle, 4800);
    expect(later.uncollectedSteps, 800);
  });

  test('dois reboots no mesmo ciclo continuam acumulando', () async {
    await service.clear();
    SharedPreferences.setMockInitialValues({});
    await service.pendingDeltaFor('c3', 100);
    await service.pendingDeltaFor('c3', 600); // 500
    await service.pendingDeltaFor('c3', 200); // reboot 1: 500 + 200
    final second =
        await service.pendingDeltaFor('c3', 50); // reboot 2: 700 + 50
    expect(second.totalStepsInCycle, 750);
  });

  test('ciclo fechado também respeita o reboot e nunca inventa baseline',
      () async {
    await service.clear();
    SharedPreferences.setMockInitialValues({});
    expect(
        await service.pendingDeltaForClosedCycle('inexistente', 999), isNull);
    await service.pendingDeltaFor('c4', 1000);
    await service.pendingDeltaFor('c4', 2000);
    final closed = await service.pendingDeltaForClosedCycle('c4', 100);
    expect(closed!.totalStepsInCycle, 1100);
  });
}
