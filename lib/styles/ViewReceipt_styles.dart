import 'package:flutter/material.dart';

class ViewReceiptStyles {
  static const Color bgColor = Color(0xFFF3F1EC);
  static const Color cardBg = Color(0xFFF4EBD9);
  static const Color cardBorder = Color(0xFFE7DBC6);
  static const Color innerCardBg = Color(0xFFF8F4EC);
  static const Color innerBorder = Color(0xE5D9C7B4);

  static const Color brown = Color(0xFF8A6232);
  static const Color darkBrown = Color(0xFF262220);
  static const Color gold = Color(0xFFB8843B);
  static const Color green = Color(0xFF49A246);

  static const BoxDecoration pageBackground = BoxDecoration(color: bgColor);

  static BoxDecoration get mainCard => BoxDecoration(
    color: cardBg,
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: cardBorder, width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 18,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration get topHeaderCard => BoxDecoration(
    color: const Color(0xFFF8F3E8),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xE5D9C8B3), width: 1.1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get topHeaderAvatar => BoxDecoration(
    color: const Color(0xFFFDFCF9),
    shape: BoxShape.circle,
    border: Border.all(color: const Color(0xFFD7D1C8), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static const TextStyle headerTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: darkBrown,
    height: 1.1,
  );

  static const TextStyle headerSubtitle = TextStyle(
    fontSize: 13.5,
    color: Color(0xFF76716B),
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static BoxDecoration get headerChip => BoxDecoration(
    color: const Color(0xFFE2F1D8),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFC2DCB1), width: 1.1),
  );

  static const TextStyle headerChipText = TextStyle(
    color: Color(0xFF478D45),
    fontWeight: FontWeight.w800,
    fontSize: 13.5,
  );

  static BoxDecoration get chatAreaCard => BoxDecoration(
    color: innerCardBg,
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: innerBorder, width: 1.1),
  );

  static BoxDecoration get aiAvatarBox => BoxDecoration(
    shape: BoxShape.circle,
    color: const Color(0xFFFDFCF9),
    border: Border.all(color: const Color(0xFFD7D1C8), width: 1.1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 5,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration get aiBubble => BoxDecoration(
    color: const Color(0xFFF0F0F2),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE5E5E8), width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.025),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static const TextStyle aiBubbleText = TextStyle(
    fontSize: 14,
    color: Color(0xFF2F2D2C),
    height: 1.45,
    fontWeight: FontWeight.w500,
  );

  static BoxDecoration get userBubble => BoxDecoration(
    color: green,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: green.withOpacity(0.22),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static const TextStyle userBubbleText = TextStyle(
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.w800,
    height: 1.35,
  );

  static BoxDecoration get codeInputWrap => BoxDecoration(
    color: const Color(0xFFF4F4F6),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xFFE3E0DA), width: 1.1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.025),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  static const TextStyle codeLabel = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: Color(0xFF2B2520),
  );

  static InputDecoration codeInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFFA8A39C),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9D4CD), width: 1.05),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD9D4CD), width: 1.05),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: gold, width: 1.2),
      ),
    );
  }

  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: green,
    foregroundColor: Colors.white,
    minimumSize: const Size.fromHeight(52),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );

  static const TextStyle primaryButtonText = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 15,
    letterSpacing: 0.2,
  );

  static BoxDecoration get receiptCardBox => BoxDecoration(
    color: const Color(0xFFFFFCF7),
    borderRadius: BorderRadius.circular(26),
    border: Border.all(color: const Color(0xFFE5DAC9), width: 1.05),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration get receiptLogoWrap => BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    border: Border.all(color: const Color(0xFFD9D0C4), width: 1.1),
  );

  static const TextStyle receiptMainTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Color(0xFF231A15),
  );

  static const TextStyle receiptSubTitle = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w800,
    color: Color(0xFFA17435),
    letterSpacing: 0.45,
  );

  static const TextStyle receiptLabel = TextStyle(
    color: Color(0xFF6F5336),
    fontWeight: FontWeight.w700,
    fontSize: 14,
  );

  static const TextStyle receiptValue = TextStyle(
    color: Color(0xFF1F1713),
    fontWeight: FontWeight.w900,
    fontSize: 14,
  );

  static BoxDecoration get sessionInfoBox => BoxDecoration(
    color: const Color(0xFFF6F3ED),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFE1D8CB), width: 1.05),
  );

  static const TextStyle receiptTitleAmount = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    color: Color(0xFF231A15),
  );

  static const TextStyle sessionInfoSubText = TextStyle(
    color: Color(0xFF9B6E39),
    fontWeight: FontWeight.w700,
    fontSize: 13.5,
  );

  static BoxDecoration get totalBox => BoxDecoration(
    color: const Color(0xFFF0E7D7),
    borderRadius: BorderRadius.circular(18),
  );

  static const TextStyle totalTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w900,
    color: Color(0xFF231A15),
  );

  static const TextStyle thankYouText = TextStyle(
    color: Color(0xFF9C7A55),
    fontWeight: FontWeight.w600,
    height: 1.5,
    fontSize: 14,
  );

  static ButtonStyle get bottomCloseButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    minimumSize: const Size.fromHeight(52),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );

  static const TextStyle bottomCloseButtonText = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 15,
  );

  static BoxDecoration get paymentDialog => BoxDecoration(
    color: const Color(0xFFF7F2E9),
    borderRadius: BorderRadius.circular(28),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.16),
        blurRadius: 26,
        offset: const Offset(0, 14),
      ),
    ],
  );

  static BoxDecoration get paymentSectionBox => BoxDecoration(
    color: const Color(0xFFFFFCF8),
    borderRadius: BorderRadius.circular(22),
    border: Border.all(color: const Color(0xFFE3D7C5), width: 1.05),
  );

  static const TextStyle paymentTitle = TextStyle(
    color: brown,
    fontWeight: FontWeight.w800,
    fontSize: 15,
    letterSpacing: 0.3,
  );

  static const TextStyle paymentDueText = TextStyle(
    color: Color(0xFF7C6751),
    fontWeight: FontWeight.w600,
    fontSize: 13.5,
  );

  static const TextStyle paymentLabel = TextStyle(
    color: brown,
    fontWeight: FontWeight.w700,
    fontSize: 13.5,
  );

  static InputDecoration paymentInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFFA8A39C), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF8F8F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE0D6C8), width: 1.05),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFE0D6C8), width: 1.05),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: gold, width: 1.2),
      ),
    );
  }

  static ButtonStyle get saveButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF6B3115),
    foregroundColor: Colors.white,
    minimumSize: const Size(104, 46),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );

  static const TextStyle saveButtonText = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 14.5,
  );

  static const TextStyle dialogCloseText = TextStyle(
    color: brown,
    fontWeight: FontWeight.w700,
    fontSize: 14,
  );
}
