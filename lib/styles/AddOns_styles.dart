import 'package:flutter/material.dart';

class AddOnsStyles {
  static const Color pageBg = Color(0xFFF4F2EC);
  static const Color cardBg = Color(0xFFF7EEDB);
  static const Color panelBg = Color(0xFFFFFBF4);

  static const Color primary = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF2E7D32);

  static const Color textDark = Color(0xFF1F1F1F);
  static const Color textSoft = Color(0xFF666666);

  static BoxDecoration modalCard = BoxDecoration(
    color: cardBg.withOpacity(0.98),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.14),
        blurRadius: 30,
        offset: const Offset(0, 16),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.18),
        blurRadius: 8,
        offset: const Offset(0, -2),
      ),
    ],
  );

  static BoxDecoration headerCard = BoxDecoration(
    color: Colors.white.withOpacity(0.34),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
  );

  static BoxDecoration chatArea = BoxDecoration(
    color: Colors.white.withOpacity(0.20),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.black.withOpacity(0.08), width: 1),
  );

  static BoxDecoration aiBubble = BoxDecoration(
    color: const Color(0xFFF5F5F9),
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

  static BoxDecoration successBubble = BoxDecoration(
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

  static BoxDecoration formCard = BoxDecoration(
    color: panelBg,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration sectionCard = BoxDecoration(
    color: Colors.white.withOpacity(0.68),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black.withOpacity(0.05), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration statusChip = BoxDecoration(
    color: primary.withOpacity(0.10),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: primary.withOpacity(0.18), width: 1),
  );

  static BoxDecoration imageBox = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
  );

  static BoxDecoration seatPanel = BoxDecoration(
    color: Colors.white.withOpacity(0.62),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
  );

  static BoxDecoration seatBox = BoxDecoration(
    color: const Color(0xFFD5CEC0),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static BoxDecoration selectedSeatBox = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
    ),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: primary.withOpacity(0.22),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
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
      fillColor: Colors.white,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.05), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: primary, width: 1.4),
      ),
    );
  }

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    textStyle: const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );

  static ButtonStyle secondaryButton = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: textDark,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: Colors.black.withOpacity(0.07)),
    ),
    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  );

  static ButtonStyle dangerButton = ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFC92A2A),
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
  );

  static TextStyle title = const TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 18,
    color: textDark,
    letterSpacing: 0.2,
  );

  static TextStyle subtitle = const TextStyle(
    fontSize: 13,
    color: textSoft,
    height: 1.5,
  );

  static TextStyle sectionTitle = const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: textDark,
  );

  static TextStyle label = const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: textDark,
  );

  static TextStyle aiText = const TextStyle(
    fontSize: 14.5,
    color: textDark,
    height: 1.6,
    fontWeight: FontWeight.w500,
  );

  static TextStyle successText = const TextStyle(
    fontSize: 14.5,
    color: Colors.white,
    height: 1.6,
    fontWeight: FontWeight.w600,
  );

  static TextStyle chipText = const TextStyle(
    fontSize: 12,
    color: primaryDark,
    fontWeight: FontWeight.w700,
  );

  static TextStyle seatGroupTitle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: textSoft,
  );

  static TextStyle seatText = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static TextStyle selectedSeatText = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static TextStyle priceText = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: primaryDark,
  );

  static TextStyle mutedText = const TextStyle(
    fontSize: 12.5,
    fontWeight: FontWeight.w600,
    color: textSoft,
  );
}
