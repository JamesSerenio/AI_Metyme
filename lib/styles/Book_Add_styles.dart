import 'package:flutter/material.dart';

class BookAddStyles {
  static const Color bgColor = Color(0xFFF6F2E9);
  static const Color cardColor = Color(0xFFF8EFDF);
  static const Color primary = Color(0xFF43A047);
  static const Color primaryDark = Color(0xFF2E7D32);
  static const Color primarySoft = Color(0xFFE3F1DE);
  static const Color textDark = Color(0xFF1F1F1F);
  static const Color textSoft = Color(0xFF6A6A6A);
  static const Color aiBubbleBg = Color(0xFFF8F8FB);

  static BoxDecoration pageBackground = const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF8F4EC), Color(0xFFF3EBDD), Color(0xFFF6F2E9)],
    ),
  );

  static BoxDecoration mainCard = BoxDecoration(
    color: cardColor.withOpacity(0.78),
    borderRadius: BorderRadius.circular(32),
    border: Border.all(
      color: const Color(0xFFDCCFAF).withOpacity(0.78),
      width: 1.2,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.10),
        blurRadius: 34,
        spreadRadius: 2,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: Colors.white.withOpacity(0.35),
        blurRadius: 12,
        offset: const Offset(0, -2),
      ),
    ],
  );

  static BoxDecoration mainCardGlassOverlay = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withOpacity(0.10),
        const Color(0xFFF7EEDB).withOpacity(0.14),
        Colors.white.withOpacity(0.06),
      ],
    ),
  );

  static BoxDecoration headerCard = BoxDecoration(
    color: Colors.white.withOpacity(0.54),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: Colors.white.withOpacity(0.48), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.045),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration chatContainer = BoxDecoration(
    color: const Color(0xFFF5EEDF).withOpacity(0.74),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: const Color(0xD9D1C0A8), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration chatBubbleAI = BoxDecoration(
    color: aiBubbleBg.withOpacity(0.96),
    borderRadius: BorderRadius.circular(
      22,
    ).copyWith(topLeft: const Radius.circular(8)),
    border: Border.all(color: const Color(0xFFE7E6ED), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.045),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration chatBubbleUser = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF52B857), Color(0xFF2E7D32)],
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
    color: primarySoft.withOpacity(0.92),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: primary.withOpacity(0.22), width: 1),
  );

  static BoxDecoration readyChip = BoxDecoration(
    color: primarySoft.withOpacity(0.92),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: primary.withOpacity(0.22), width: 1),
  );

  static InputDecoration inputDecoration({String hintText = "Type 1-6..."}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.black.withOpacity(0.38),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.94),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: BorderSide(
          color: const Color(0xFFE1D8C8).withOpacity(0.9),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    );
  }

  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    backgroundColor: primaryDark,
    foregroundColor: Colors.white,
    elevation: 5,
    padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    ),
  );

  static ButtonStyle sendButton = ElevatedButton.styleFrom(
    backgroundColor: primary,
    foregroundColor: Colors.white,
    elevation: 4,
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );

  static const TextStyle title = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 17,
    color: textDark,
    letterSpacing: 0.2,
  );

  static const TextStyle bigTitle = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 34,
    color: textDark,
    height: 1.15,
    letterSpacing: 0.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 14,
    color: textSoft,
    height: 1.55,
    fontWeight: FontWeight.w500,
  );

  static TextStyle helperText = TextStyle(
    fontSize: 12.5,
    color: Colors.black.withOpacity(0.56),
    fontWeight: FontWeight.w500,
  );

  static const TextStyle chatTextAI = TextStyle(
    fontSize: 14.5,
    color: textDark,
    height: 1.62,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle chatTextUser = TextStyle(
    fontSize: 14.5,
    color: Colors.white,
    height: 1.62,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 14.5,
    color: textDark,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle onlineText = TextStyle(
    fontSize: 12,
    color: primaryDark,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle readyText = TextStyle(
    fontSize: 12,
    color: primaryDark,
    fontWeight: FontWeight.w700,
  );

  static ShapeBorder themeMenuShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
    side: BorderSide(color: Colors.white.withOpacity(0.65), width: 1),
  );

  static const TextStyle themeMenuText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Color(0xFF24351F),
  );

  static PopupMenuThemeData themePopupMenu = PopupMenuThemeData(
    color: Color(0xFFF8F4EC),
    elevation: 10,
    shape: themeMenuShape,
    textStyle: themeMenuText,
  );
  // ================= THEME DROPDOWN =================

  static const Color themeMenuBg = Color(0xFFF8F4EC);

  static BoxDecoration themeMenuSelected = BoxDecoration(
    borderRadius: BorderRadius.circular(14),
    gradient: const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFFE8F6E8), Color(0xFFD7F0D7)],
    ),
    border: Border.all(color: Color(0xFF43A047), width: 1),
  );

  static BoxDecoration themeMenuNormal = BoxDecoration(
    borderRadius: BorderRadius.circular(14),
  );

  static const TextStyle themeMenuSelectedText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    color: Color(0xFF2E7D32),
  );

  static const TextStyle themeMenuNormalText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Color(0xFF24351F),
  );

  // ================= CHRISTMAS THEME =================

  static const Color christmasRed = Color(0xFFD32F2F);
  static const Color christmasGreen = Color(0xFF1B5E20);
  static const Color christmasGold = Color(0xFFFFC857);

  static BoxDecoration christmasMainCard = BoxDecoration(
    color: const Color(0xFFFFF8EC).withOpacity(0.78),
    borderRadius: BorderRadius.circular(32),
    border: Border.all(color: christmasGold.withOpacity(0.75), width: 1.4),
    boxShadow: [
      BoxShadow(
        color: christmasRed.withOpacity(0.18),
        blurRadius: 34,
        spreadRadius: 2,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: christmasGold.withOpacity(0.20),
        blurRadius: 18,
        offset: const Offset(0, -3),
      ),
    ],
  );

  static BoxDecoration christmasReadyChip = BoxDecoration(
    color: const Color(0xFFFFF3F3).withOpacity(0.95),
    borderRadius: BorderRadius.circular(999),
    border: Border.all(color: christmasRed.withOpacity(0.35), width: 1),
  );

  static const TextStyle christmasReadyText = TextStyle(
    fontSize: 12,
    color: christmasRed,
    fontWeight: FontWeight.w800,
  );

  static BoxDecoration christmasHeaderCard = BoxDecoration(
    color: Colors.white.withOpacity(0.58),
    borderRadius: BorderRadius.circular(28),
    border: Border.all(color: christmasGold.withOpacity(0.55), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: christmasRed.withOpacity(0.12),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
