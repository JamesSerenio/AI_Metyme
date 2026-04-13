import 'package:flutter/material.dart';

class NoisyStyles {
  static const Color pageBg = Color(0xFFF4F2EC);
  static const Color cardBg = Color(0xFFF7EEDB);
  static const Color panelBg = Color(0xFFFFFBF4);

  static const Color primary = Color(0xFF45A049);
  static const Color primaryDark = Color(0xFF2F7D32);
  static const Color primarySoft = Color(0xFFE4F5E5);

  static const Color textDark = Color(0xFF1F1F1F);
  static const Color textSoft = Color(0xFF666666);
  static const Color borderSoft = Color(0x1F000000);
  static const Color danger = Color(0xFFD95C5C);
  static const Color aiBubbleBg = Color(0xFFFFFFFF);
  static const Color userBubbleBg = Color(0xFF45A049);

  static BoxDecoration get modalCard => BoxDecoration(
        color: cardBg.withOpacity(0.98),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.14),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      );

  static BoxDecoration get headerCard => BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFFFFF9F0),
            Color(0xFFF6ECD9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x1A000000)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      );

  static BoxDecoration get chatArea => BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      );

  static BoxDecoration get formCard => BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      );

  static BoxDecoration get sectionCard => BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get infoCard => BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFFF4FBF4),
            Color(0xFFE8F5E9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primary.withOpacity(0.18)),
      );

  static BoxDecoration get infoInnerCard => BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      );

  static BoxDecoration get aiBubble => BoxDecoration(
        color: aiBubbleBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(6),
        ),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration get successBubble => BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF4CAF50),
            Color(0xFF3D9141),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(6),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: primary.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration get statusChip => BoxDecoration(
        color: primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primary.withOpacity(0.20)),
      );

  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: primary.withOpacity(0.45),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
      );

  static ButtonStyle get secondaryButton => ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFFEEF2EC),
        foregroundColor: textDark,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
      );

  static ButtonStyle get dangerButton => ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: const Color(0xFFFCECEC),
        foregroundColor: danger,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 0.4,
        ),
      );

  static InputDecoration inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.black.withOpacity(0.35),
        fontWeight: FontWeight.w500,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFFFEFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: Colors.black.withOpacity(0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: primary,
          width: 1.2,
        ),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }

  static TextStyle get title => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: textDark,
      );

  static TextStyle get subtitle => const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: textSoft,
        height: 1.3,
      );

  static TextStyle get chipText => const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: primaryDark,
        letterSpacing: 0.4,
      );

  static TextStyle get sectionTitle => const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: textDark,
      );

  static TextStyle get label => const TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w800,
        color: textDark,
      );

  static TextStyle get mutedText => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: textSoft,
      );

  static TextStyle get aiText => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textDark,
        height: 1.45,
      );

  static TextStyle get successText => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.45,
      );
}