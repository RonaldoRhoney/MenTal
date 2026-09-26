import 'package:flutter_test/flutter_test.dart';

import 'package:mental/services/movement_notification_math.dart';

/// Notificação de Movimento sem abrir o app (pedido de Rhoney, 26/09/2026):
/// atualiza a cada 1500 passos com números ESTIMADOS, espelhando as regras do
/// servidor (app/config.py) sem nunca gravar estado do app principal.
void main() {
  test('faixas de XP espelham MOVEMENT_STEP_TIERS x MOVEMENT_XP_BASE=20', () {
    expect(movementTierBonus(0), 0);
    expect(movementTierBonus(1999), 0);
    expect(movementTierBonus(2000), 20);
    expect(movementTierBonus(5000), 40);
    expect(movementTierBonus(10000), 60);
    expect(movementTierBonus(15000), 80);
    expect(movementTierBonus(999999), 80);
  });

  test('MentalCoins: 1 por 1000 passos (regra oficial 2.1; a prévia antiga usava 5)', () {
    expect(movementMentalCoinsFor(999), 0);
    expect(movementMentalCoinsFor(1000), 1);
    expect(movementMentalCoinsFor(9720), 9);
  });

  test('a notificação só muda quando o total cruza uma faixa de 1500 passos', () {
    expect(movementNotificationBucket(1499), 0);
    expect(movementNotificationBucket(1500), 1);
    expect(movementNotificationBucket(2999), 1);
    expect(movementNotificationBucket(3000), 2);
  });

  test('total do ciclo sem gravar nada, com e sem reboot no meio', () {
    expect(estimateCycleTotalSteps(baseline: 1000, carry: 0, lastRaw: 1200, lastSubmittedTotal: 0, currentRaw: 2500), 1500);
    // contador de hardware zerou (reboot): o que já valia vira carry
    expect(estimateCycleTotalSteps(baseline: 1000, carry: 0, lastRaw: 4000, lastSubmittedTotal: 0, currentRaw: 300), 3300);
    // estado antigo sem lastRaw: assume o que foi enviado ao servidor
    expect(estimateCycleTotalSteps(baseline: 5000, carry: 0, lastRaw: null, lastSubmittedTotal: 2000, currentRaw: 100), 2100);
    // nunca negativo
    expect(estimateCycleTotalSteps(baseline: 900, carry: 0, lastRaw: 900, lastSubmittedTotal: 0, currentRaw: 900), 0);
  });

  test('estimativa parte do retrato do servidor e nunca superestima XP de bônus de meta', () {
    final est = estimateFromSnapshot(snapshotSteps: 4000, snapshotXp: 20, totalStepsNow: 10500);
    expect(est.steps, 10500);
    expect(est.coins, 10);
    // servidor já creditou 20; a mudança de faixa 2000->10000 rende +40
    expect(est.xp, 60);
    // total menor que o retrato (ex.: leitura antiga) não regride o que já foi creditado
    final low = estimateFromSnapshot(snapshotSteps: 4000, snapshotXp: 20, totalStepsNow: 3000);
    expect((low.steps, low.xp), (4000, 20));
  });

  test('texto: creditado x estimado, passos em forma compacta', () {
    expect(movementNotificationText(steps: 9720, coins: 9, xp: 60, estimated: false),
        '🚶 9.7k passos · 🪙 9 MentalCoins · ⚡ 60 XP hoje');
    expect(movementNotificationText(steps: 1500, coins: 1, xp: 0, estimated: true),
        '🚶 1.5k passos · 🪙 1 MentalCoins · ⚡ 0 XP hoje (estimado — abra o app para creditar)');
  });
}
