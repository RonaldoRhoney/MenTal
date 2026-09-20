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
}
