import 'package:flutter/material.dart';

import 'fondea_colors.dart';

/// Estilos semánticos que trasladan la jerarquía tipográfica del kit.
abstract final class FondeaTypography {
  static const fontFamily = 'Inter';

  static const screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 30 / 24,
    color: FondeaColors.textPrimary,
  );

  static const sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 26 / 20,
    color: FondeaColors.textPrimary,
  );

  static const cardTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 24 / 16,
    color: FondeaColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 20 / 16,
    color: FondeaColors.textPrimary,
  );

  static const button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
  );

  static const fieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 18 / 13,
    color: FondeaColors.textPrimary,
  );

  static const helper = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: FondeaColors.mutedText,
  );
}
