import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static const bodyLarge = TextStyle(fontSize: 16);

  static const bodyMedium = TextStyle(fontSize: 14);

  static const bodySmall = TextStyle(fontSize: 12, color: Colors.black54);

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  static const monospace = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
  );
}
