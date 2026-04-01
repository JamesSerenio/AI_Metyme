import 'package:flutter/material.dart';

class PromoModalStyles {
  static const Color pageBg = Color(0xFFF4F7FB);
  static const Color cardBg = Color(0xFFFDF7EE);
  static const Color primary = Color(0xFF2F9E63);
  static const Color primaryDark = Color(0xFF278A57);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF8B94A3);
  static const Color error = Color(0xFFD32F2F);

  static BoxDecoration modalCard = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8EDD7), Color(0xFFE8C183)],
    ),
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.12),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
    ],
  );

  static BoxDecoration headerCard = BoxDecoration(
    color: Colors.white24,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.black12),
  );

  static BoxDecoration chatArea = BoxDecoration(
    color: Colors.white24,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.black12),
  );

  static BoxDecoration formCard = BoxDecoration(
    color: Colors.white30,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.black12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 14,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration infoCard = BoxDecoration(
    color: const Color(0xFFF8EEDC),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFD8BE8E)),
  );

  static BoxDecoration aiBubble = BoxDecoration(
    color: Colors.white.withOpacity(0.95),
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration successBubble = BoxDecoration(
    color: const Color(0xFF2F9E63),
    borderRadius: BorderRadius.circular(18),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 12,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static BoxDecoration statusChip = BoxDecoration(
    color: const Color(0xFFE7F7ED),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: const Color(0xFFB7E3C8)),
  );

  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textDark,
    letterSpacing: 0.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: textDark,
    height: 1.35,
  );

  static const TextStyle chipText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: primary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: textDark,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const TextStyle aiText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textDark,
    height: 1.4,
  );

  static const TextStyle successText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.4,
  );

  static const TextStyle infoTitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: textDark,
  );

  static const TextStyle infoText = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    color: textDark,
    height: 1.35,
  );

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    minimumSize: const Size.fromHeight(52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    ),
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: textDark,
    elevation: 0,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.black.withOpacity(0.08)),
    ),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
  );
}
