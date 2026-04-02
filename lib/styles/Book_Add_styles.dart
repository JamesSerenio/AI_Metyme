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

  static BoxDecoration displayImageWash = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.white.withOpacity(0.15),
        Colors.white.withOpacity(0.04),
        Colors.white.withOpacity(0.16),
      ],
    ),
  );

  static BoxDecoration displayImageTint = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF8EFDF).withOpacity(0.70),
        const Color(0xFFF8EFDF).withOpacity(0.42),
        const Color(0xFFF3EBDD).withOpacity(0.66),
      ],
      stops: const [0.0, 0.45, 1.0],
    ),
  );

  static BoxDecoration headerCard = BoxDecoration(
    color: Colors.white.withOpacity(0.48),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: const Color(0xFFD8CCB3).withOpacity(0.78),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.white.withOpacity(0.14),
        blurRadius: 8,
        offset: const Offset(0, -1),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 5),
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

  static InputDecoration inputDecoration({String hintText = "Type 1-5..."}) {
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

  static ButtonStyle primaryButton =
      ElevatedButton.styleFrom(
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
      ).copyWith(
        shadowColor: WidgetStateProperty.all(primary.withOpacity(0.20)),
        elevation: WidgetStateProperty.all(4),
      );

  static ButtonStyle sendButton =
      ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ).copyWith(
        shadowColor: WidgetStateProperty.all(primary.withOpacity(0.22)),
        elevation: WidgetStateProperty.all(4),
      );

  static const TextStyle title = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 17,
    color: textDark,
    letterSpacing: 0.2,
  );

  static const TextStyle bigTitle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 32,
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
}
