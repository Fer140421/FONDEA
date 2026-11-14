import 'package:flutter/material.dart';

import '../fondea_colors.dart';
import '../fondea_radius.dart';
import '../fondea_sizes.dart';

enum FondeaButtonVariant { primary, secondary }

/// Botón reutilizable con estados activo, deshabilitado y cargando.
class FondeaButton extends StatelessWidget {
  const FondeaButton({
    required this.label,
    required this.onPressed,
    this.variant = FondeaButtonVariant.primary,
    this.isLoading = false,
    this.loadingLabel,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final FondeaButtonVariant variant;
  final bool isLoading;
  final String? loadingLabel;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == FondeaButtonVariant.primary
                  ? FondeaColors.textInverse
                  : FondeaColors.secondary,
            ),
          )
        else if (icon != null)
          icon!,
        if (isLoading || icon != null) const SizedBox(width: 8),
        Flexible(child: Text(isLoading ? loadingLabel ?? label : label)),
      ],
    );

    return SizedBox(
      width: double.infinity,
      height: FondeaSizes.controlHeight,
      child: variant == FondeaButtonVariant.primary
          ? FilledButton(
              onPressed: isLoading ? null : onPressed,
              style: isLoading
                  ? FilledButton.styleFrom(
                      disabledBackgroundColor: FondeaColors.primary,
                      disabledForegroundColor: FondeaColors.textInverse,
                    )
                  : null,
              child: content,
            )
          : OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: isLoading
                  ? OutlinedButton.styleFrom(
                      disabledForegroundColor: FondeaColors.secondary,
                      side: const BorderSide(
                        color: FondeaColors.secondary,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(FondeaRadius.button),
                      ),
                    )
                  : null,
              child: content,
            ),
    );
  }
}
