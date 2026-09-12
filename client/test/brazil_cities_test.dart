import 'package:flutter_test/flutter_test.dart';
import 'package:mental/brazil_cities.dart';

/// Pedido de Rhoney (12/09/2026): autocomplete de Cidade por Estado
/// (assets/data/brazil_cities.json, IBGE). Cobre o que é novo — dado
/// carregado do asset bundle de verdade (não mockado), filtro por UF,
/// e tolerância a acento na busca.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('normalize remove acentos e baixa a caixa, pra busca tolerante', () {
    expect(BrazilCities.normalize('São Luís'), 'sao luis');
    expect(BrazilCities.normalize('BAC'), 'bac');
    expect(BrazilCities.normalize('Ananindeua'), 'ananindeua');
  });

  test('citiesForState carrega o asset real e filtra por UF (Bacuri está em MA, não em PA)', () async {
    final maCities = await BrazilCities.citiesForState('MA');
    final paCities = await BrazilCities.citiesForState('PA');

    expect(maCities, contains('Bacuri'));
    expect(paCities, isNot(contains('Bacuri')));
    expect(paCities, contains('Ananindeua'));
    expect(paCities, contains('Belém'));
  });

  test('UF desconhecida devolve lista vazia, nunca erro', () async {
    final cities = await BrazilCities.citiesForState('XX');
    expect(cities, isEmpty);
  });
}
