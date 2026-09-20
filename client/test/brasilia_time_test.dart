import 'package:flutter_test/flutter_test.dart';

import 'package:mental/brasilia_time.dart';

void main() {
  test('converte UTC para Brasília e mostra o período do dia', () {
    expect(formatBrasiliaTime('2026-09-21T08:13:00'), '05:13 da manhã');
    expect(formatBrasiliaTime('2026-09-21T20:13:00'), '17:13 da tarde');
    expect(formatBrasiliaTime('2026-09-21T21:00:00Z'), '18:00 da noite');
    expect(formatBrasiliaTime('2026-09-21T05:30:00'), '02:30 da madrugada');
  });

  test('não depende do fuso do aparelho (aceita com ou sem Z)', () {
    expect(formatBrasiliaTime('2026-09-21T15:00:00'),
        formatBrasiliaTime('2026-09-21T15:00:00Z'));
  });

  test('bordas dos períodos do dia', () {
    // UTC-3: 07:59Z = 04:59 (madrugada), 08:00Z = 05:00 (manhã)
    expect(formatBrasiliaTime('2026-09-21T07:59:00'), '04:59 da madrugada');
    expect(formatBrasiliaTime('2026-09-21T08:00:00'), '05:00 da manhã');
    expect(formatBrasiliaTime('2026-09-21T14:59:00'), '11:59 da manhã');
    expect(formatBrasiliaTime('2026-09-21T15:00:00'), '12:00 da tarde');
    expect(formatBrasiliaTime('2026-09-21T20:59:00'), '17:59 da tarde');
    expect(formatBrasiliaTime('2026-09-21T21:00:00'), '18:00 da noite');
  });

  test('virada de dia e meia-noite', () {
    expect(formatBrasiliaTime('2026-09-21T02:30:00'),
        '23:30 da noite'); // ainda dia 20 em Brasília
    expect(formatBrasiliaTime('2026-09-21T03:00:00'), '00:00 da madrugada');
  });

  test('aceita +00:00 sem lançar (além de Z e sem fuso)', () {
    expect(formatBrasiliaTime('2026-09-21T20:13:00+00:00'), '17:13 da tarde');
    expect(parseServerUtc('2026-09-21T20:13:00+00:00'),
        DateTime.utc(2026, 9, 21, 20, 13));
  });
}
