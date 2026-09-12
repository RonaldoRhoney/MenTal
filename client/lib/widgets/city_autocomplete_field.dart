import 'package:flutter/material.dart';

import '../brazil_cities.dart';

/// Pedido de Rhoney (12/09/2026): a partir de 3 letras digitadas,
/// sugere cidades do Estado já escolhido (ex: Estado MA, digita "BAC"
/// → aparece "Bacuri"). Cidade continua texto livre — a lista é só
/// assistência, nunca trava o campo a uma opção da lista.
class CityAutocompleteField extends StatefulWidget {
  const CityAutocompleteField({
    super.key,
    required this.stateUf,
    required this.controller,
    required this.labelText,
    this.onChanged,
  });

  final String? stateUf;
  final TextEditingController controller;
  final String labelText;
  final ValueChanged<String>? onChanged;

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  // RawAutocomplete exige focusNode junto de textEditingController (os
  // dois externos, ou nenhum) — precisa de State pra ter um FocusNode
  // com ciclo de vida próprio (dispose).
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateUf = widget.stateUf;
    final controller = widget.controller;
    final labelText = widget.labelText;
    final onChanged = widget.onChanged;
    return Autocomplete<String>(
      textEditingController: controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue value) async {
        final uf = stateUf;
        final query = value.text.trim();
        if (uf == null || query.length < 3) return const Iterable<String>.empty();
        final cities = await BrazilCities.citiesForState(uf);
        final normalizedQuery = BrazilCities.normalize(query);
        return cities.where((city) => BrazilCities.normalize(city).startsWith(normalizedQuery)).take(20);
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: labelText),
          onChanged: onChanged,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
      onSelected: onChanged,
    );
  }
}
