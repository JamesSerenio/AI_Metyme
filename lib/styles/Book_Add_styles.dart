import 'package:flutter/material.dart';

class BookAddStyles {
  static const Color bgColor = Color(0xFFF4F1EA);
  static const Color cardColor = Color(0xFFF8EEDC);
  static const Color primary = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color accent = Color(0xFF66BB6A);

  static const Color textDark = Color(0xFF1F1F1F);
  static const Color textSoft = Color(0xFF5E5E5E);
  static const Color borderSoft = Color(0x14000000);
  static const Color aiBubbleBg = Color(0xFFFFFFFF);

  static BoxDecoration mainCard = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.10),
        blurRadius: 30,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.35),
        blurRadius: 12,
        offset: const Offset(0, -2),
      ),
    ],
  );

  static BoxDecoration headerCard = BoxDecoration(
    color: Colors.white.withOpacity(0.34),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
  );

  static BoxDecoration chatContainer = BoxDecoration(
    color: Colors.white.withOpacity(0.24),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
  );

  static BoxDecoration chatBubbleAI = BoxDecoration(
    color: aiBubbleBg,
    borderRadius: BorderRadius.circular(
      18,
    ).copyWith(topLeft: const Radius.circular(6)),
    border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
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
      18,
    ).copyWith(topRight: const Radius.circular(6)),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.22),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration onlineChip = BoxDecoration(
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );

  static TextStyle title = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 17,
    color: textDark,
    letterSpacing: 0.2,
  );

  static TextStyle bigTitle = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 28,
    color: textDark,
    height: 1.15,
    letterSpacing: 0.2,
  );

  static TextStyle subtitle = const TextStyle(
    fontSize: 13,
    color: textSoft,
    height: 1.4,
  );

  static TextStyle helperText = TextStyle(
    fontSize: 12,
    color: Colors.black.withOpacity(0.56),
    fontWeight: FontWeight.w500,
  );

  static TextStyle chipText = const TextStyle(
    fontSize: 12,
    color: primaryDark,
    fontWeight: FontWeight.w700,
  );

  static TextStyle chatTextAI = const TextStyle(
    fontSize: 14,
    color: textDark,
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  static TextStyle chatTextUser = const TextStyle(
    fontSize: 14,
    color: Colors.white,
    height: 1.45,
    fontWeight: FontWeight.w600,
  );

  static TextStyle inputText = const TextStyle(
    fontSize: 14,
    color: textDark,
    fontWeight: FontWeight.w500,
  );

  static TextStyle onlineText = const TextStyle(
    fontSize: 12,
    color: primaryDark,
    fontWeight: FontWeight.w700,
  );
}
