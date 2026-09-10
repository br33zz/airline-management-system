import 'package:flutter/material.dart';

class FieldSpec {
  final String keyName, label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  const FieldSpec({
    required this.keyName,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
  });
}

class ConfiguredFields extends StatelessWidget {
  final List<FieldSpec> fields;
  final ValueChanged<String>? onChanged;
  const ConfiguredFields({super.key, required this.fields, this.onChanged});

  @override
  Widget build(BuildContext context) => Column(
    children: fields
        .map(
          (field) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextFormField(
              key: ValueKey(field.keyName),
              controller: field.controller,
              decoration: InputDecoration(labelText: field.label),
              validator: field.validator,
              keyboardType: field.keyboardType,
              maxLines: field.maxLines,
              onChanged: onChanged,
            ),
          ),
        )
        .toList(),
  );
}
