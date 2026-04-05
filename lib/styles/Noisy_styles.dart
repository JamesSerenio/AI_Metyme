import 'package:flutter/material.dart';

class NoisyStyles {
  static const pageBg = Color(0xFFF4F2EC);

  static BoxDecoration card = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
    ],
  );

  static TextStyle title = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static InputDecoration input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Color(0xFFF7EEDB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  static BoxDecoration aiBubble = BoxDecoration(
    color: Color(0xFFF1F5F9),
    borderRadius: BorderRadius.circular(16),
  );

  static BoxDecoration userBubble = BoxDecoration(
    color: Color(0xFF4CAF50),
    borderRadius: BorderRadius.circular(16),
  );

  static TextStyle aiText = const TextStyle(color: Colors.black87);
  static TextStyle userText = const TextStyle(color: Colors.white);
}
