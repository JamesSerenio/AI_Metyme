import 'package:flutter/material.dart';

class SeatStyles {
  static const Color pageBg = Color(0xFFF4F2EC);
  static const Color cardBg = Color(0xFFF7EEDB);
  static const Color panelBg = Color(0xFFFFFBF4);

  static const Color primary = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF2E7D32);

  static const Color textDark = Color(0xFF1F1F1F);
  static const Color textSoft = Color(0xFF666666);

  static const Color greenSeat = Color(0xFF00D75A);
  static const Color yellowSeat = Color(0xFFF4C542);
  static const Color redSeat = Color(0xFFE53935);
  static const Color purpleSeat = Color(0xFFB55CFF);

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

  static BoxDecoration stageCard = BoxDecoration(
    color: panelBg,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.black.withOpacity(0.07), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration legendCard = BoxDecoration(
    color: Colors.white.withOpacity(0.78),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: Colors.black.withOpacity(0.06), width: 1),
  );

  static BoxDecoration statusChip = BoxDecoration(
    color: primary.withOpacity(0.10),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: primary.withOpacity(0.18), width: 1),
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

  static TextStyle chipText = const TextStyle(
    fontSize: 12,
    color: primaryDark,
    fontWeight: FontWeight.w700,
  );

  static TextStyle legendText = const TextStyle(
    fontSize: 12.5,
    color: textDark,
    fontWeight: FontWeight.w700,
  );

  static TextStyle sectionTitle = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: textDark,
  );

  static TextStyle dateText = const TextStyle(
    fontSize: 12,
    color: textSoft,
    fontWeight: FontWeight.w700,
  );

  static TextStyle seatLabel = const TextStyle(
    fontSize: 7.8,
    fontWeight: FontWeight.w900,
    color: Color(0xFF141414),
    height: 1,
  );

  static TextStyle roomLabel = const TextStyle(
    fontSize: 9.2,
    fontWeight: FontWeight.w900,
    color: Color(0xFF141414),
    height: 1,
  );

  static BoxDecoration pinDecoration(Color color) {
    return BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withOpacity(0.95), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration roomDecoration(Color color) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withOpacity(0.95), width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.18),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

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
}
