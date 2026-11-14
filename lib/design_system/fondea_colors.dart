import 'package:flutter/material.dart';

/// Colores del kit Fondea en Figma. Evita duplicar valores hexadecimales en pantallas.
abstract final class FondeaColors {
  static const primary = Color(0xFF14324B);
  static const secondary = Color(0xFF0F766E);
  static const accent = Color(0xFF2DD4BF);

  static const background = Color(0xFFF5F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE5EE);
  static const textPrimary = primary;
  static const textInverse = surface;

  static const success = secondary;
  static const warning = Color(0xFFB45309);
  static const error = Color(0xFFB42318);
  static const disabled = Color(0xFFE5EDF3);
  static const disabledText = Color(0xFF94A3B8);
  static const mutedText = Color(0xFF73777E);

  static const successSurface = Color(0xFFECFDF5);
  static const warningSurface = Color(0xFFFFFBEB);
  static const errorSurface = Color(0xFFFEF2F2);
}
