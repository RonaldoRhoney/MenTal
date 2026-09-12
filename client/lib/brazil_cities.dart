import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Pedido de Rhoney (12/09/2026): autocomplete de Cidade filtrado pelo
/// Estado escolhido (ex: Estado MA, digita "BAC" → sugere "Bacuri") —
/// evita a mesma mistura de dados que motivou o Estado virar lista
/// fixa. Dado vem de `assets/data/brazil_cities.json` (IBGE, baixado
/// uma vez em 12/09/2026 — ver `assets/data/README.md`), nunca
/// consultado em runtime. Cidade continua texto livre: a lista é só
/// sugestão, o usuário pode ignorá-la e digitar o nome que quiser.
class BrazilCities {
  BrazilCities._();

  static Map<String, List<String>>? _cache;

  static Future<List<String>> citiesForState(String uf) async {
    final data = await _load();
    return data[uf] ?? const [];
  }

  static Future<Map<String, List<String>>> _load() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await rootBundle.loadString('assets/data/brazil_cities.json');
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final parsed = decoded.map((uf, cities) => MapEntry(uf, (cities as List).cast<String>()));
    _cache = parsed;
    return parsed;
  }

  static const Map<String, String> _accentMap = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// Normaliza pra busca tolerante a acento (usuário digitando "sao"
  /// deve encontrar "São Luís" mesmo sem o til).
  static String normalize(String value) {
    final lower = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accentMap[char] ?? char);
    }
    return buffer.toString();
  }
}
