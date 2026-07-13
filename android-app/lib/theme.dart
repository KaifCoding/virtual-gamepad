import 'package:flutter/material.dart';

/// Central palette matching the Canva design (purple/blue gradient brand,
/// dark indigo gamepad screen, muted face-button colors).
class AppColors {
  // Splash / connect screen gradient (light violet -> vivid blue-violet)
  static const gradientTop = Color(0xFFA99EF5);
  static const gradientBottom = Color(0xFF3D2BEB);

  // App icon / primary accent
  static const iconBg = Color(0xFF0B5FA3);
  static const accent = Color(0xFF6366F1);
  static const accentLight = Color(0xFF8B5CF6);

  // Gamepad (in-game) screen gradient
  static const gamepadTop = Color(0xFF201347);
  static const gamepadBottom = Color(0xFF0A0818);

  // Face buttons - matches the mockup's muted palette
  static const buttonA = Color(0xFF4CAF50); // green
  static const buttonB = Color(0xFFD32F2F); // red
  static const buttonX = Color(0xFF16A085); // teal
  static const buttonY = Color(0xFFB5A642); // olive/dark yellow

  static const stickFill = Color(0xFF6C63FF);
}
