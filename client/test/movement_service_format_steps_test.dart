import 'package:flutter_test/flutter_test.dart';

import 'package:mental/services/movement_service.dart';

/// Pedido de Rhoney (18/09/2026): passos na notificação persistente de
/// Movimento em forma compacta ("1k", "1.5k") a partir de 1000.
void main() {
  test('abaixo de 1000 mostra o número cheio', () {
    expect(MovementService.formatSteps(0), '0');
    expect(MovementService.formatSteps(999), '999');
  });

  test('1000 exato mostra "1k", sem ".0"', () {
    expect(MovementService.formatSteps(1000), '1k');
  });

  test('valores quebrados mostram 1 casa decimal', () {
    expect(MovementService.formatSteps(1500), '1.5k');
    expect(MovementService.formatSteps(2347), '2.3k');
  });

  test('milhares redondos maiores continuam sem ".0"', () {
    expect(MovementService.formatSteps(12000), '12k');
  });
}
