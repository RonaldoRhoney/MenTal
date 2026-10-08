import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mental/services/floating_mental_controller.dart';

/// MENTAL_AGENTE_FLUTUANTE_DIAGNOSTICO_TECNICO_V1.md — visibilidade final
/// = enabled && homeReached && hiddenDepth == 0.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Como o controller é singleton (instance), cada teste reseta o que
  // mexeu pra não vazar estado pro próximo.
  tearDown(() {
    FloatingMentalController.instance.popHidden();
  });

  test('enabled=true e sem conflito de estado por padrão', () async {
    await FloatingMentalController.instance.load();
    expect(FloatingMentalController.instance.enabled, isTrue);
  });

  test('não visível antes de homeReached, mesmo enabled', () async {
    final controller = FloatingMentalController.instance;
    await controller.load();
    expect(controller.homeReached, isFalse);
    expect(controller.visible, isFalse);
  });

  test('visível depois de homeReached, enabled e sem hide pendente', () async {
    final controller = FloatingMentalController.instance;
    await controller.load();
    controller.setHomeReached();
    expect(controller.visible, isTrue);
  });

  test('setHomeReached() é um trinco de uma via (idempotente)', () {
    final controller = FloatingMentalController.instance;
    controller.setHomeReached();
    expect(controller.homeReached, isTrue);
    controller.setHomeReached();
    expect(controller.homeReached, isTrue);
  });

  test('setEnabled(false) esconde mesmo com homeReached e sem hide pendente', () async {
    final controller = FloatingMentalController.instance;
    controller.setHomeReached();
    await controller.setEnabled(false);
    expect(controller.visible, isFalse);
    await controller.setEnabled(true);
    expect(controller.visible, isTrue);
  });

  test('pushHidden()/popHidden() escondem e reaparecem (contador, não bool)', () {
    final controller = FloatingMentalController.instance;
    controller.setHomeReached();
    expect(controller.visible, isTrue);

    controller.pushHidden();
    expect(controller.visible, isFalse);

    // Telas aninhadas: um segundo pushHidden() não pode deixar um único
    // popHidden() reaparecer o personagem cedo demais.
    controller.pushHidden();
    controller.popHidden();
    expect(controller.visible, isFalse);

    controller.popHidden();
    expect(controller.visible, isTrue);
  });

  test('popHidden() nunca deixa o contador negativo (chamada a mais é inofensiva)', () {
    final controller = FloatingMentalController.instance;
    controller.setHomeReached();
    controller.popHidden();
    controller.popHidden();
    expect(controller.visible, isTrue);
    controller.pushHidden();
    expect(controller.visible, isFalse);
    controller.popHidden();
    expect(controller.visible, isTrue);
  });

  test('updatePosition() persiste e volta via load() numa nova leitura', () async {
    final controller = FloatingMentalController.instance;
    await controller.updatePosition(const Offset(123, 456));
    expect(controller.position, const Offset(123, 456));

    // Simula um load() novo (ex.: próxima abertura do app) lendo o que
    // foi persistido.
    await controller.load();
    expect(controller.position, const Offset(123, 456));
  });

  test('currentClient é null por padrão (setado só após login, em main.dart)', () {
    expect(FloatingMentalController.instance.currentClient, isNull);
  });
}
