/// Formata um instante UTC (ISO, com ou sem "Z") no horário de Brasília
/// (UTC-3 fixo — o Brasil não tem horário de verão desde 2019), com o
/// período do dia: "05:13 da manhã", "17:13 da tarde".
///
/// Pedido de Rhoney (20/09/2026): o chip de boost mostrava só "05:13" e
/// não dava pra saber se era manhã ou tarde. Independe do fuso do aparelho.
String formatBrasiliaTime(String isoUtc) {
  final utc = DateTime.parse(isoUtc.endsWith('Z') ? isoUtc : '${isoUtc}Z');
  final br = utc.toUtc().subtract(const Duration(hours: 3));
  final hh = br.hour.toString().padLeft(2, '0');
  final mm = br.minute.toString().padLeft(2, '0');
  final String period;
  if (br.hour < 5) {
    period = 'da madrugada';
  } else if (br.hour < 12) {
    period = 'da manhã';
  } else if (br.hour < 18) {
    period = 'da tarde';
  } else {
    period = 'da noite';
  }
  return '$hh:$mm $period';
}
