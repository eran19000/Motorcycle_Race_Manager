import 'package:flutter/material.dart';

/// Shared look for all text fields & dropdown inputs: black fill (matches scaffold),
/// neon borders & typed text, hint-style placeholders (hintText — hidden when filled).
abstract final class RaceInputTheme {
  static const Color fieldFill = Color(0xFF000000);
  static const Color neon = Color(0xFF22D3EE);
  static const Color neonBright = Color(0xFF7EE7F2);

  static const TextStyle typingStyle = TextStyle(
    color: neonBright,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1.25,
  );

  static const TextStyle hintStyle = TextStyle(
    color: Color(0x9922D3EE),
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.25,
  );

  /// Use on [TextField], [TextFormField], and as [DropdownButtonFormField.style].
  static const TextStyle dropdownStyle = typingStyle;

  static InputDecorationTheme get decorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: fieldFill,
        isDense: false,
        floatingLabelBehavior: FloatingLabelBehavior.never,
        errorMaxLines: 4,
        helperMaxLines: 3,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        hintStyle: hintStyle,
        helperStyle: const TextStyle(color: Color(0xAA7EE7F2), fontSize: 13, height: 1.2),
        labelStyle: hintStyle,
        floatingLabelStyle: const TextStyle(color: neonBright, fontWeight: FontWeight.w600),
        errorStyle: const TextStyle(color: Color(0xFFFF6B6B), height: 1.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neon, width: 1.1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neon, width: 1.1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: neonBright, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.3),
        ),
      );

  static InputDecoration neonDecoration(String hint, {Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: fieldFill,
      isDense: false,
      errorMaxLines: 4,
      helperMaxLines: 3,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintStyle: hintStyle,
      labelStyle: hintStyle,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neon, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: neonBright, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.4),
      ),
    );
  }
}
