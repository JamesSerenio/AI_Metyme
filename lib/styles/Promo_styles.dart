import 'package:flutter/material.dart';

class PromoModalStyles {
  static const Color pageBg = Color(0xFFF4F2EC);
  static const Color cardBg = Color(0xFFF5EEDC);
  static const Color panelBg = Color(0xFFFFFBF4);

  static const Color primary = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF2E7D32);

  static const Color textDark = Color(0xFF1F1F1F);
  static const Color textMuted = Color(0xFF666666);
  static const Color error = Color(0xFFD32F2F);

  static BoxDecoration modalCard = BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.black.withOpacity(0.06)),
  );

  static BoxDecoration headerCard = BoxDecoration(
    color: Colors.white.withOpacity(0.40),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black.withOpacity(0.06)),
  );

  static BoxDecoration chatArea = BoxDecoration(
    color: Colors.white.withOpacity(0.25),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black.withOpacity(0.06)),
  );

  static BoxDecoration formCard = BoxDecoration(
    color: panelBg,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black.withOpacity(0.05)),
  );

  static BoxDecoration infoCard = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.black.withOpacity(0.05)),
  );

  static BoxDecoration aiBubble = BoxDecoration(
    color: const Color(0xFFF1F1F1),
    borderRadius: BorderRadius.circular(
      20,
    ).copyWith(topLeft: const Radius.circular(8)),
  );

  static BoxDecoration successBubble = BoxDecoration(
    color: primary,
    borderRadius: BorderRadius.circular(
      20,
    ).copyWith(topRight: const Radius.circular(8)),
  );

  static BoxDecoration statusChip = BoxDecoration(
    color: primary.withOpacity(0.15),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: primary.withOpacity(0.18)),
  );

  static BoxDecoration seatGroupCard = BoxDecoration(
    color: Colors.white.withOpacity(0.70),
    borderRadius: BorderRadius.circular(18),
  );

  static BoxDecoration seatBox = BoxDecoration(
    color: const Color(0xFFD5CEC0),
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration selectedSeatBox = BoxDecoration(
    color: primary,
    borderRadius: BorderRadius.circular(12),
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
    color: primaryDark,
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

  static const TextStyle seatPickerTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const TextStyle seatGroupTitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static const TextStyle seatText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle selectedSeatText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
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

  static InputDecoration inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.black.withOpacity(0.40),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFFF7F7F7),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: error, width: 1.3),
      ),
    );
  }
}
