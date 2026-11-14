import 'package:flutter/material.dart';

import 'fondea_colors.dart';
import 'fondea_radius.dart';
import 'fondea_sizes.dart';
import 'fondea_typography.dart';

/// Tema de la app. Los cambios globales de marca se hacen aquí y en los tokens.
abstract final class FondeaTheme {
  static ThemeData get light {
    const colors = ColorScheme.light(
      primary: FondeaColors.primary,
      onPrimary: FondeaColors.textInverse,
      secondary: FondeaColors.secondary,
      onSecondary: FondeaColors.textInverse,
      surface: FondeaColors.surface,
      onSurface: FondeaColors.textPrimary,
      error: FondeaColors.error,
      onError: FondeaColors.textInverse,
      outline: FondeaColors.border,
    );

    const fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(FondeaRadius.field)),
      borderSide: BorderSide(color: FondeaColors.border),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      fontFamily: FondeaTypography.fontFamily,
      scaffoldBackgroundColor: FondeaColors.background,
      textTheme: const TextTheme(
        headlineSmall: FondeaTypography.screenTitle,
        titleLarge: FondeaTypography.sectionTitle,
        titleMedium: FondeaTypography.cardTitle,
        bodyLarge: FondeaTypography.body,
        bodyMedium: FondeaTypography.body,
        labelLarge: FondeaTypography.button,
        labelMedium: FondeaTypography.fieldLabel,
        bodySmall: FondeaTypography.helper,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FondeaColors.primary,
          foregroundColor: FondeaColors.textInverse,
          disabledBackgroundColor: FondeaColors.disabled,
          disabledForegroundColor: FondeaColors.disabledText,
          minimumSize: const Size(0, FondeaSizes.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FondeaRadius.button),
          ),
          textStyle: FondeaTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FondeaColors.secondary,
          minimumSize: const Size(0, FondeaSizes.controlHeight),
          side: const BorderSide(color: FondeaColors.secondary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FondeaRadius.button),
          ),
          textStyle: FondeaTypography.button,
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: FondeaColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(FondeaRadius.field)),
          borderSide: BorderSide(color: FondeaColors.secondary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(FondeaRadius.field)),
          borderSide: BorderSide(color: FondeaColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(FondeaRadius.field)),
          borderSide: BorderSide(color: FondeaColors.error, width: 1.5),
        ),
        labelStyle: FondeaTypography.fieldLabel,
        helperStyle: FondeaTypography.helper,
        errorStyle: FondeaTypography.helper,
      ),
    );
  }
}
