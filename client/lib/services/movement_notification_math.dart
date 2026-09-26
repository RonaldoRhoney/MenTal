/// Matemática PURA da notificação de Movimento sem abrir o app (pedido de
/// Rhoney, 26/09/2026: "deve ser atualizada a cada 1500 passos sem a
/// necessidade de abrir o App"). Sem plugin nem estado: só espelhos das
/// regras do servidor pra ESTIMAR o que ainda vai ser creditado. Quem credita
/// de verdade continua sendo o backend (app/movement.py), na coleta feita
/// com o app aberto — por isso o texto se declara "estimado" quando há
/// passos ainda não coletados.

/// A notificação só é reescrita quando o total avança 1500 passos.
const int kMovementNotificationStepInterval = 1500;

/// Espelho de app/config.py MOVEMENT_XP_BASE / MOVEMENT_STEP_TIERS.
const int _kXpBase = 20;
const List<(int, int)> _kStepTiers = [
  (15000, 4),
  (10000, 3),
  (5000, 2),
  (2000, 1),
  (0, 0),
];

/// Espelho de app/config.py: MOVEMENT_STEPS_PER_MENTALCOIN = 1000 e
/// MOVEMENT_MENTALCOINS_PER_MILESTONE = 1 (REGRA_OFICIAL_GAMIFICACAO_MENTAL.md
/// item 2.1, 19/09/2026 — a prévia antiga usava 5 e superestimava 5x).
const int kMovementStepsPerMentalCoin = 1000;
const int kMovementMentalCoinsPerMilestone = 1;

/// XP de faixa para um total de passos no ciclo (mesma lógica de _bonus_for_steps).
int movementTierBonus(int totalSteps) {
  for (final (threshold, multiplier) in _kStepTiers) {
    if (totalSteps >= threshold) return _kXpBase * multiplier;
  }
  return 0;
}

int movementMentalCoinsFor(int totalSteps) =>
    (totalSteps ~/ kMovementStepsPerMentalCoin) * kMovementMentalCoinsPerMilestone;

/// Faixa de 1500 em 1500 passos (só reescreve quando a faixa muda).
int movementNotificationBucket(int totalSteps) => totalSteps ~/ kMovementNotificationStepInterval;

/// Total de passos do ciclo, SEM gravar nada (mesma regra de
/// MovementService._totalSoFar, incluindo o ajuste de reboot). O serviço de
/// segundo plano roda em outro isolate: se gravasse, sobrescreveria o estado
/// do app principal e poderia gerar coleta em dobro.
int estimateCycleTotalSteps({
  required int baseline,
  required int carry,
  required int? lastRaw,
  required int lastSubmittedTotal,
  required int currentRaw,
}) {
  var b = baseline;
  var c = carry;
  if (lastRaw != null && currentRaw < lastRaw) {
    c += lastRaw - b < 0 ? 0 : lastRaw - b;
    b = 0;
  } else if (lastRaw == null && currentRaw < b) {
    c = lastSubmittedTotal;
    b = 0;
  }
  final total = c + (currentRaw - b);
  return total < 0 ? 0 : total;
}

String _compact(int steps) {
  if (steps < 1000) return '$steps';
  final rounded = (steps / 1000 * 10).round() / 10;
  final whole = rounded == rounded.roundToDouble();
  return '${whole ? rounded.toInt().toString() : rounded.toStringAsFixed(1)}k';
}

/// Texto da notificação. `estimated` = há passos ainda não creditados pelo servidor.
String movementNotificationText({
  required int steps,
  required int coins,
  required int xp,
  required bool estimated,
}) {
  final base = '🚶 ${_compact(steps)} passos · 🪙 $coins MentalCoins · ⚡ $xp XP hoje';
  return estimated ? '$base (estimado — abra o app para creditar)' : base;
}

/// Estimativa a partir do último retrato do servidor: XP = o já creditado +
/// o que a mudança de faixa ainda vai render (bônus de meta e de checkpoint só
/// contam quando o servidor credita, então isto nunca superestima).
({int steps, int coins, int xp}) estimateFromSnapshot({
  required int snapshotSteps,
  required int snapshotXp,
  required int totalStepsNow,
}) {
  final steps = totalStepsNow < snapshotSteps ? snapshotSteps : totalStepsNow;
  final tierGain = movementTierBonus(steps) - movementTierBonus(snapshotSteps);
  return (
    steps: steps,
    coins: movementMentalCoinsFor(steps),
    xp: snapshotXp + (tierGain > 0 ? tierGain : 0),
  );
}
