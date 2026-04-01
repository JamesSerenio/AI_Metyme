import 'package:flutter/material.dart';

class BookAddStyles {
  static const Color bgColor = Color(0xFFF4F2EC);
  static const Color cardColor = Color(0xFFF7EEDB);
  static const Color primary = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color textDark = Color(0xFF1F1F1F);
  static const Color textSoft = Color(0xFF616161);
  static const Color aiBubbleBg = Color(0xFFF8F8FB);

  static BoxDecoration pageBackground = const BoxDecoration(color: bgColor);

  static BoxDecoration mainCard = BoxDecoration(
    color: cardColor.withOpacity(0.92),
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.12),
        blurRadius: 34,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.20),
        blurRadius: 12,
        offset: const Offset(0, -2),
      ),
    ],
  );

  static BoxDecoration headerCard = BoxDecoration(
    color: Colors.white.withOpacity(0.30),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
  );

  static BoxDecoration chatContainer = BoxDecoration(
    color: Colors.white.withOpacity(0.20),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
  );

  static BoxDecoration chatBubbleAI = BoxDecoration(
    color: aiBubbleBg,
    borderRadius: BorderRadius.circular(
      22,
    ).copyWith(topLeft: const Radius.circular(8)),
    border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration chatBubbleUser = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    ),
    borderRadius: BorderRadius.circular(
      22,
    ).copyWith(topRight: const Radius.circular(8)),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.22),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration onlineChip = BoxDecoration(
    color: primary.withOpacity(0.10),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: primary.withOpacity(0.18), width: 1),
  );

  static BoxDecoration readyChip = BoxDecoration(
    color: primary.withOpacity(0.10),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: primary.withOpacity(0.18), width: 1),
  );

  static InputDecoration inputDecoration({String hintText = "Type 1-4..."}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.black.withOpacity(0.42),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.94),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );

  static ButtonStyle sendButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );

  static TextStyle title = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 17,
    color: textDark,
    letterSpacing: 0.2,
  );

  static TextStyle bigTitle = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 32,
    color: textDark,
    height: 1.15,
    letterSpacing: 0.2,
  );

  static TextStyle subtitle = const TextStyle(
    fontSize: 14,
    color: textSoft,
    height: 1.55,
  );

  static TextStyle helperText = TextStyle(
    fontSize: 12.5,
    color: Colors.black.withOpacity(0.56),
    fontWeight: FontWeight.w500,
  );

  static TextStyle chatTextAI = const TextStyle(
    fontSize: 14.5,
    color: textDark,
    height: 1.62,
    fontWeight: FontWeight.w500,
  );

  static TextStyle chatTextUser = const TextStyle(
    fontSize: 14.5,
    color: Colors.white,
    height: 1.62,
    fontWeight: FontWeight.w600,
  );

  static TextStyle inputText = const TextStyle(
    fontSize: 14.5,
    color: textDark,
    fontWeight: FontWeight.w500,
  );

  static TextStyle onlineText = const TextStyle(
    fontSize: 12,
    color: primaryDark,
    fontWeight: FontWeight.w700,
  );

  static TextStyle readyText = const TextStyle(
    fontSize: 12,
    color: primaryDark,
    fontWeight: FontWeight.w700,
  );
}
