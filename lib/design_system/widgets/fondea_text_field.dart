import 'package:flutter/material.dart';

import '../fondea_colors.dart';
import '../fondea_spacing.dart';
import '../fondea_typography.dart';

/// Campo de formulario con etiqueta y estados compartidos del kit Fondea.
class FondeaTextField extends StatelessWidget {
  const FondeaTextField({
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.error,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.autofillHints,
    this.validator,
    this.onChanged,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? error;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: FondeaTypography.fieldLabel.copyWith(
            color: hasError ? FondeaColors.error : null,
          ),
        ),
        const SizedBox(height: FondeaSpacing.xs),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          autofillHints: autofillHints,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            helperText: helper,
            errorText: error,
          ),
        ),
      ],
    );
  }
}
