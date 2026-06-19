import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'styles/Book_Add_styles.dart';
import 'pages/Booking.dart';
import 'pages/Promo.dart';
import 'pages/AddOns.dart';
import 'pages/Seat.dart';
import 'pages/Attendance.dart';
import 'pages/ViewReceipt.dart';

class BookAddPage extends StatefulWidget {
  const BookAddPage({super.key});

  @override
  State<BookAddPage> createState() => _BookAddPageState();
}

class _BookAddPageState extends State<BookAddPage>
    with TickerProviderStateMixin {
  bool started = false;
  bool openingBooking = false;
  bool openingPromo = false;
  bool openingAddOns = false;
  bool openingSeat = false;
  bool openingAttendance = false;
  bool openingReceipt = false;

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];

  late final AnimationController pageControllerAnim;
  late final AnimationController leafController;
  late final AnimationController ambientController;

  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;
  late final Animation<double> leafFloatAnim;
  late final Animation<double> ambientFloatAnim;

  late final PageController displayPageController;
  Timer? autoSlideTimer;

  late List<String> displayImages;

  static const int _loopStartPage = 10000;
  int currentAbsolutePage = _loopStartPage;
  int currentDisplayIndex = 0;

  String selectedTheme = "Regular";

  final Map<String, List<String>> themeImages = {
    "Regular": List.generate(20, (index) => 'assets/${index + 1}.png'),
    "Christmas": List.generate(20, (index) => 'assets/${index + 1}.png'),
    "Halloween": List.generate(20, (index) => 'assets/${index + 1}.png'),
    "Valentine": List.generate(20, (index) => 'assets/${index + 1}.png'),
    "Summer": List.generate(20, (index) => 'assets/${index + 1}.png'),
    "Fiesta": List.generate(20, (index) => 'assets/${index + 1}.png'),
  };

  static final List<String> _allDisplayImages = List.generate(
    20,
    (index) => 'assets/${index + 1}.png',
  );

  @override
  void initState() {
    super.initState();

    pageControllerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5600),
    )..repeat(reverse: true);

    fadeAnim = CurvedAnimation(
      parent: pageControllerAnim,
      curve: Curves.easeOutCubic,
    );

    slideAnim = Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: pageControllerAnim,
            curve: Curves.easeOutCubic,
          ),
        );

    leafFloatAnim = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(parent: leafController, curve: Curves.easeInOut));

    ambientFloatAnim = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: ambientController, curve: Curves.easeInOut),
    );

    displayImages = List<String>.from(_allDisplayImages)..shuffle(Random());

    displayPageController = PageController(
      initialPage: _loopStartPage,
      viewportFraction: 1,
    );

    pageControllerAnim.forward();
    _startAutoSlide();
  }

  @override
  void dispose() {
    autoSlideTimer?.cancel();
    controller.dispose();
    scrollController.dispose();
    pageControllerAnim.dispose();
    leafController.dispose();
    ambientController.dispose();
    displayPageController.dispose();
    super.dispose();
  }

  bool get isBusy =>
      openingBooking ||
      openingPromo ||
      openingAddOns ||
      openingSeat ||
      openingAttendance ||
      openingReceipt;

  void _startAutoSlide() {
    autoSlideTimer?.cancel();
    autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted ||
          !displayPageController.hasClients ||
          displayImages.isEmpty) {
        return;
      }

      currentAbsolutePage += 1;

      displayPageController.animateToPage(
        currentAbsolutePage,
        duration: const Duration(milliseconds: 2800),
        curve: Curves.easeInOutExpo,
      );
    });
  }

  void startChat() {
    if (started) return;

    setState(() {
      started = true;
      messages.clear();
    });

    _scrollToBottom();
  }

  void sendMessage(String text) {
    final String value = text.trim();
    if (value.isEmpty || isBusy) return;

    setState(() {
      messages.add({"isAI": false, "text": value});
    });

    controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 420), () {
      handleAIResponse(value);
    });
  }

  Future<void> _openBookingFlow() async {
    if (!mounted || isBusy) return;

    setState(() {
      openingBooking = true;
      messages.add({
        "isAI": true,
        "text":
            "You selected Booking ✅\n\nOpening the booking form for you now...",
      });
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingModalPage(theme: selectedTheme)),
    );

    if (!mounted) return;

    setState(() {
      openingBooking = false;
      messages.add({
        "isAI": true,
        "text":
            "You may choose another service anytime.\n\nPlease select one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo\n6. View Receipt",
      });
    });

    _scrollToBottom();
  }

  Future<void> _openPromoFlow() async {
    if (!mounted || isBusy) return;

    setState(() {
      openingPromo = true;
      messages.add({
        "isAI": true,
        "text":
            "You selected Promo 🎉\n\nOpening the promo booking form for you now...",
      });
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PromoModalPage(theme: selectedTheme)),
    );

    if (!mounted) return;

    setState(() {
      openingPromo = false;
      messages.add({
        "isAI": true,
        "text":
            "You may choose another service anytime.\n\nPlease select one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo\n6. View Receipt",
      });
    });

    _scrollToBottom();
  }

  Future<void> _openAddOnsFlow() async {
    if (!mounted || isBusy) return;

    setState(() {
      openingAddOns = true;
      messages.add({
        "isAI": true,
        "text":
            "You selected Add-Ons 🍔\n\nOpening the add-ons form for you now...",
      });
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddOnsPage()),
    );

    if (!mounted) return;

    setState(() {
      openingAddOns = false;
      messages.add({
        "isAI": true,
        "text":
            "You may choose another service anytime.\n\nPlease select one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo\n6. View Receipt",
      });
    });

    _scrollToBottom();
  }

  Future<void> _openSeatFlow() async {
    if (!mounted || isBusy) return;

    setState(() {
      openingSeat = true;
      messages.add({
        "isAI": true,
        "text":
            "You selected Seat View 🪑\n\nOpening the seat map for you now...",
      });
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SeatPage()),
    );

    if (!mounted) return;

    setState(() {
      openingSeat = false;
      messages.add({
        "isAI": true,
        "text":
            "You may choose another service anytime.\n\nPlease select one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo\n6. View Receipt",
      });
    });

    _scrollToBottom();
  }

  Future<void> _openAttendanceFlow() async {
    if (!mounted || isBusy) return;

    setState(() {
      openingAttendance = true;
      messages.add({
        "isAI": true,
        "text":
            "You selected Attendance for Reservation and Promo ✅\n\nOpening the attendance form for you now...",
      });
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AttendancePage()),
    );

    if (!mounted) return;

    setState(() {
      openingAttendance = false;
      messages.add({
        "isAI": true,
        "text":
            "You may choose another service anytime.\n\nPlease select one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo\n6. View Receipt",
      });
    });

    _scrollToBottom();
  }

  Future<void> _openReceiptFlow() async {
    if (!mounted || isBusy) return;

    setState(() {
      openingReceipt = true;
      messages.add({
        "isAI": true,
        "text": "You selected View Receipt 🧾\n\nOpening your receipt now...",
      });
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ViewReceipt()),
    );

    if (!mounted) return;

    setState(() {
      openingReceipt = false;
      messages.add({
        "isAI": true,
        "text":
            "You may choose another service anytime.\n\nPlease select one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo\n6. View Receipt",
      });
    });

    _scrollToBottom();
  }

  void handleAIResponse(String input) {
    final String value = input.trim().toLowerCase();

    switch (value) {
      case "1":
      case "booking":
        _openBookingFlow();
        return;

      case "2":
      case "promo":
        _openPromoFlow();
        return;

      case "3":
      case "add-ons":
      case "addons":
      case "add ons":
        _openAddOnsFlow();
        return;

      case "4":
      case "seat view":
      case "seatview":
        _openSeatFlow();
        return;

      case "5":
      case "attendance":
      case "attendance for reservation and promo":
      case "reservation attendance":
      case "promo attendance":
        _openAttendanceFlow();
        return;

      case "6":
      case "view receipt":
      case "receipt":
        _openReceiptFlow();
        return;

      default:
        setState(() {
          messages.add({
            "isAI": true,
            "text":
                "I’m sorry, I could not recognize that selection.\n\nPlease choose one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo\n6. View Receipt",
          });
        });
        _scrollToBottom();
        return;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 140,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildLogo(double size) {
    return PopupMenuButton<String>(
      tooltip: "Change Theme",
      offset: Offset(0, size - 8),
      position: PopupMenuPosition.under,
      color: const Color(0xFFF8F4EC),
      elevation: 12,
      shape: BookAddStyles.themeMenuShape,
      onSelected: (value) {
        setState(() {
          selectedTheme = value;
          displayImages = List<String>.from(themeImages[value]!)
            ..shuffle(Random());
          currentDisplayIndex = 0;
          currentAbsolutePage = _loopStartPage;
        });

        if (displayPageController.hasClients) {
          displayPageController.jumpToPage(_loopStartPage);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "Regular",
          child: Container(
            decoration: selectedTheme == "Regular"
                ? BookAddStyles.themeMenuSelected
                : BookAddStyles.themeMenuNormal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "🌿 Regular",
              style: selectedTheme == "Regular"
                  ? BookAddStyles.themeMenuSelectedText
                  : BookAddStyles.themeMenuNormalText,
            ),
          ),
        ),
        PopupMenuItem(
          value: "Christmas",
          child: Container(
            decoration: selectedTheme == "Christmas"
                ? BookAddStyles.themeMenuSelected
                : BookAddStyles.themeMenuNormal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "🎄 Christmas",
              style: selectedTheme == "Christmas"
                  ? BookAddStyles.themeMenuSelectedText
                  : BookAddStyles.themeMenuNormalText,
            ),
          ),
        ),

        PopupMenuItem(
          value: "Halloween",
          child: Container(
            decoration: selectedTheme == "Halloween"
                ? BookAddStyles.themeMenuSelected
                : BookAddStyles.themeMenuNormal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "🎃 Halloween",
              style: selectedTheme == "Halloween"
                  ? BookAddStyles.themeMenuSelectedText
                  : BookAddStyles.themeMenuNormalText,
            ),
          ),
        ),

        PopupMenuItem(
          value: "Valentine",
          child: Container(
            decoration: selectedTheme == "Valentine"
                ? BookAddStyles.themeMenuSelected
                : BookAddStyles.themeMenuNormal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "💘 Valentine",
              style: selectedTheme == "Valentine"
                  ? BookAddStyles.themeMenuSelectedText
                  : BookAddStyles.themeMenuNormalText,
            ),
          ),
        ),

        PopupMenuItem(
          value: "Summer",
          child: Container(
            decoration: selectedTheme == "Summer"
                ? BookAddStyles.themeMenuSelected
                : BookAddStyles.themeMenuNormal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "☀️ Summer",
              style: selectedTheme == "Summer"
                  ? BookAddStyles.themeMenuSelectedText
                  : BookAddStyles.themeMenuNormalText,
            ),
          ),
        ),

        PopupMenuItem(
          value: "Fiesta",
          child: Container(
            decoration: selectedTheme == "Fiesta"
                ? BookAddStyles.themeMenuSelected
                : BookAddStyles.themeMenuNormal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "🎉 Fiesta",
              style: selectedTheme == "Fiesta"
                  ? BookAddStyles.themeMenuSelectedText
                  : BookAddStyles.themeMenuNormalText,
            ),
          ),
        ),
      ],
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'assets/study_hub.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.image_not_supported_outlined);
            },
          ),
        ),
      ),
    );
  }

  Widget _cornerDecor({required double width, required String position}) {
    final bool isChristmas = selectedTheme == "Christmas";

    if (!isChristmas) {
      return _leafInsideRegular(width: width, position: position);
    }

    String asset;
    double size;
    Alignment align;
    Offset offset;

    switch (position) {
      case "topLeft":
        asset = BookAddStyles.christmasBellsJson;
        size = width * 0.52;
        align = Alignment.topLeft;
        offset = const Offset(8, 8);
        break;

      case "topRight":
        asset = BookAddStyles.christmasBellsJson;
        size = width * 0.52;
        align = Alignment.topRight;
        offset = const Offset(-8, 8);
        break;

      case "bottomLeft":
        asset = BookAddStyles.christmasBellsJson;
        size = width * 0.52;
        align = Alignment.bottomLeft;
        offset = const Offset(8, -8);
        break;

      default:
        asset = BookAddStyles.christmasBellsJson;
        size = width * 0.52;
        align = Alignment.bottomRight;
        offset = const Offset(-8, -8);
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: leafFloatAnim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(offset.dx, offset.dy + leafFloatAnim.value * 0.12),
            child: child,
          );
        },
        child: SizedBox(
          width: width,
          height: width,
          child: Align(
            alignment: align,
            child: Lottie.asset(
              asset,
              width: size,
              height: size,
              repeat: true,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Widget _leafInsideRegular({required double width, required String position}) {
    double angle;
    bool invertY;

    switch (position) {
      case "topLeft":
        angle = 0;
        invertY = true;
        break;
      case "topRight":
        angle = 3.14159;
        invertY = false;
        break;
      case "bottomLeft":
        angle = 0;
        invertY = false;
        break;
      default:
        angle = -1.5708;
        invertY = false;
    }

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: leafFloatAnim,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, leafFloatAnim.value),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..rotateZ(angle)
                ..scale(1.0, invertY ? -1.0 : 1.0),
              child: child,
            ),
          );
        },
        child: Image.asset(
          'assets/leave.png',
          width: width,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFloatingGlow({
    required Alignment alignment,
    required double size,
    required double opacity,
  }) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: ambientFloatAnim,
        builder: (context, child) {
          final double shift = ambientFloatAnim.value;
          return Align(
            alignment: alignment,
            child: Transform.translate(
              offset: Offset(alignment.x * shift * 0.8, alignment.y * shift),
              child: child,
            ),
          );
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.white.withOpacity(opacity),
                Colors.white.withOpacity(0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplayBackground(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: displayPageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                currentAbsolutePage = index;
                currentDisplayIndex = index % displayImages.length;
              });
            },
            itemBuilder: (context, index) {
              final String imagePath =
                  displayImages[index % displayImages.length];

              return AnimatedBuilder(
                animation: displayPageController,
                builder: (context, child) {
                  double page = currentAbsolutePage.toDouble();

                  if (displayPageController.hasClients &&
                      displayPageController.position.haveDimensions) {
                    page =
                        displayPageController.page ??
                        currentAbsolutePage.toDouble();
                  }

                  final double diff = (page - index).abs().clamp(0.0, 1.0);

                  final double scale = lerpDouble(1.25, 1.0, 1 - diff)!;

                  final double rotate = lerpDouble(0.06, 0.0, 1 - diff)!;

                  final double slideX = (page - index) * 140;

                  final double slideY = sin((page - index) * pi) * 25;

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..translate(slideX, slideY)
                      ..scale(scale)
                      ..rotateZ(rotate),
                    child: child,
                  );
                },
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(imagePath),
                  tween: Tween(begin: 1.18, end: 1.0),
                  duration: const Duration(seconds: 4),
                  curve: Curves.easeOutCubic,
                  builder: (context, zoom, child) {
                    return Transform.scale(scale: zoom, child: child);
                  },
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    gaplessPlayback: true,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          'Image not found:\n$imagePath',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.02),
                  Colors.white.withOpacity(0.08),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFF7EEDB).withOpacity(0.12),
                  const Color(0xFFF7EEDB).withOpacity(0.04),
                  const Color(0xFFF2E7D3).withOpacity(0.12),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, 0.02),
                radius: 0.88,
                colors: [Colors.transparent, Colors.black.withOpacity(0.03)],
              ),
            ),
          ),
          _buildFloatingGlow(
            alignment: Alignment.topLeft,
            size: isMobile ? 180 : 260,
            opacity: 0.16,
          ),
          _buildFloatingGlow(
            alignment: Alignment.bottomRight,
            size: isMobile ? 220 : 300,
            opacity: 0.13,
          ),
          _buildFloatingGlow(
            alignment: Alignment.centerRight,
            size: isMobile ? 120 : 170,
            opacity: 0.08,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroPanel(bool isMobile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 18 : 28,
            vertical: isMobile ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.20),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                "Start Your Booking Assistant",
                textAlign: TextAlign.center,
                style:
                    (isMobile
                            ? BookAddStyles.bigTitle.copyWith(fontSize: 22)
                            : BookAddStyles.bigTitle.copyWith(fontSize: 28))
                        .copyWith(
                          color: const Color(0xFF1A1A1A),
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.55),
                              blurRadius: 10,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 22),
                child: Text(
                  "Click Start to choose Booking, Promo, Add-Ons, Seat View, Attendance for Reservation and Promo, or View Receipt through chat.",
                  textAlign: TextAlign.center,
                  style: BookAddStyles.subtitle.copyWith(
                    color: Colors.black.withOpacity(0.72),
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chatBubble(Map<String, dynamic> msg, bool isMobile) {
    final bool isAI = msg["isAI"] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isAI
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            _buildLogo(isMobile ? 34 : 38),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              constraints: BoxConstraints(maxWidth: isMobile ? 255 : 500),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 12 : 14,
              ),
              decoration: isAI
                  ? BookAddStyles.chatBubbleAI
                  : BookAddStyles.chatBubbleUser,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg["text"]?.toString() ?? "",
                    style: isAI
                        ? BookAddStyles.chatTextAI
                        : BookAddStyles.chatTextUser,
                  ),
                  if (msg["showOptions"] == true) ...[
                    const SizedBox(height: 14),
                    _buildChatOptionGrid(isMobile),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final bool isMobile = screen.width < 640;
    final bool isTablet = screen.width >= 640 && screen.width < 1100;

    final double cardWidth = isMobile
        ? screen.width - 20
        : isTablet
        ? 600
        : 700;

    final double cardHeight = isMobile
        ? screen.height * 0.88
        : isTablet
        ? 560
        : 600;

    final double leafWidth = isMobile
        ? 100
        : isTablet
        ? 130
        : 155;

    return Scaffold(
      backgroundColor: BookAddStyles.bgColor,
      body: Container(
        decoration: BookAddStyles.pageBackground,
        child: SafeArea(
          child: FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Center(
                child: SizedBox(
                  width: cardWidth,
                  height: cardHeight,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Container(
                          margin: EdgeInsets.all(isMobile ? 10 : 8),
                          decoration: selectedTheme == "Christmas"
                              ? BookAddStyles.christmasMainCard
                              : BookAddStyles.mainCard,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildDisplayBackground(isMobile),

                                if (selectedTheme == "Christmas")
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: AnimatedBuilder(
                                        animation: ambientController,
                                        builder: (context, child) {
                                          return CustomPaint(
                                            painter:
                                                ChristmasLightsBorderPainter(
                                                  progress:
                                                      ambientController.value,
                                                  radius: 32,
                                                ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                if (selectedTheme == "Christmas") ...[
                                  Positioned(
                                    top: screen.width < 500
                                        ? 18
                                        : screen.width < 1100
                                        ? -8
                                        : 20,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: SizedBox(
                                        width: isMobile
                                            ? 240
                                            : isTablet
                                            ? 320
                                            : 420,

                                        height: isMobile
                                            ? 70
                                            : isTablet
                                            ? 90
                                            : 120,
                                        child: Lottie.asset(
                                          BookAddStyles.christmasSleighJson,
                                          repeat: true,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: AnimatedBuilder(
                                        animation: ambientController,
                                        builder: (context, child) {
                                          return CustomPaint(
                                            painter: ChristmasSnowPainter(
                                              progress: ambientController.value,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],

                                Container(
                                  decoration:
                                      BookAddStyles.mainCardGlassOverlay,
                                ),
                                Padding(
                                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 420),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: !started
                                        ? _buildStartState(isMobile)
                                        : _buildChatState(isMobile),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: isMobile ? -5 : -8,
                        left: isMobile ? -5 : -8,
                        child: _cornerDecor(
                          width: leafWidth,
                          position: "topLeft",
                        ),
                      ),
                      Positioned(
                        top: isMobile ? -5 : -8,
                        right: isMobile ? -5 : -8,
                        child: _cornerDecor(
                          width: leafWidth,
                          position: "topRight",
                        ),
                      ),
                      Positioned(
                        bottom: isMobile ? -5 : -8,
                        left: isMobile ? -5 : -8,
                        child: _cornerDecor(
                          width: leafWidth,
                          position: "bottomLeft",
                        ),
                      ),
                      Positioned(
                        bottom: isMobile ? -5 : -8,
                        right: isMobile ? -5 : -8,
                        child: _cornerDecor(
                          width: leafWidth,
                          position: "bottomRight",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLotusAnimation(bool isMobile) {
    final double size = isMobile ? 80 : 105;

    return SizedBox(
      width: size + 90,
      height: size + 45,
      child: AnimatedBuilder(
        animation: Listenable.merge([leafController, ambientController]),
        builder: (context, child) {
          final double t = leafController.value * 2 * pi;
          final double a = ambientController.value * 2 * pi;

          return Stack(
            alignment: Alignment.center,
            children: [
              // soft glow
              Container(
                width: size + 20,
                height: size + 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      BookAddStyles.primary.withOpacity(0.20),
                      Colors.white.withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // floating leaves
              _floatingMiniLeaf(
                dx: -65 + sin(t) * 8,
                dy: -8 + cos(t) * 8,
                angle: -0.8 + sin(t) * 0.2,
                size: isMobile ? 24 : 30,
                opacity: 0.85,
              ),
              _floatingMiniLeaf(
                dx: 65 + cos(t) * 7,
                dy: -15 + sin(t) * 7,
                angle: 0.8 + cos(t) * 0.2,
                size: isMobile ? 24 : 30,
                opacity: 0.85,
              ),
              _floatingMiniLeaf(
                dx: -38 + cos(t) * 5,
                dy: 42 + sin(t) * 5,
                angle: 0.4,
                size: isMobile ? 18 : 23,
                opacity: 0.75,
              ),
              _floatingMiniLeaf(
                dx: 38 + sin(t) * 5,
                dy: 42 + cos(t) * 5,
                angle: -0.4,
                size: isMobile ? 18 : 23,
                opacity: 0.75,
              ),

              // sparkles
              _sparkle(dx: -50, dy: -40, opacity: 0.35 + sin(a) * 0.25),
              _sparkle(dx: 50, dy: -35, opacity: 0.35 + cos(a) * 0.25),
              _sparkle(dx: 0, dy: -58, opacity: 0.45 + sin(a) * 0.20),

              // lotus icon
              Transform.translate(
                offset: Offset(0, sin(t) * 4),
                child: Lottie.asset(
                  selectedTheme == "Christmas"
                      ? BookAddStyles.christmasCardJson
                      : 'assets/lottie/flower.json',
                  width: size,
                  height: size,
                  repeat: true,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _floatingMiniLeaf({
    required double dx,
    required double dy,
    required double angle,
    required double size,
    required double opacity,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Transform.rotate(
        angle: angle,
        child: Opacity(
          opacity: opacity,
          child: Icon(
            Icons.eco_rounded,
            size: size,
            color: const Color(0xFF5C9F4A),
          ),
        ),
      ),
    );
  }

  Widget _sparkle({
    required double dx,
    required double dy,
    required double opacity,
  }) {
    return Transform.translate(
      offset: Offset(dx, dy),
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: const Icon(
          Icons.auto_awesome_rounded,
          size: 16,
          color: Color(0xFFE8D8A8),
        ),
      ),
    );
  }

  Widget _buildStartState(bool isMobile) {
    return Column(
      key: const ValueKey("start-state"),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: selectedTheme == "Christmas"
              ? BookAddStyles.christmasHeaderCard
              : BookAddStyles.headerCard,
          child: Row(
            children: [
              _buildLogo(isMobile ? 46 : 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedTheme == "Christmas"
                          ? "Merry Christmas, Me Tyme Lounge!"
                          : "Welcome to Me Tyme Lounge!",
                      style: BookAddStyles.title.copyWith(
                        color: const Color(0xFF232323),
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.50),
                            blurRadius: 8,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rest, relax, and focus in a peaceful environment.",
                      style: BookAddStyles.subtitle.copyWith(
                        color: Colors.black.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: selectedTheme == "Christmas"
                      ? BookAddStyles.christmasReadyChip
                      : BookAddStyles.readyChip,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: BookAddStyles.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedTheme == "Christmas"
                            ? "Christmas booking"
                            : "Ready for booking",
                        style: selectedTheme == "Christmas"
                            ? BookAddStyles.christmasReadyText
                            : BookAddStyles.readyText,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 10 : 14),

        _buildLotusAnimation(isMobile),

        SizedBox(height: isMobile ? 8 : 10),

        _buildHeroPanel(isMobile),

        SizedBox(height: isMobile ? 14 : 18),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: ElevatedButton(
            onPressed: startChat,
            style: selectedTheme == "Christmas"
                ? BookAddStyles.christmasPrimaryButton
                : BookAddStyles.primaryButton,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                selectedTheme == "Christmas"
                    ? SizedBox(
                        width: 28,
                        height: 28,
                        child: Lottie.asset(
                          BookAddStyles.snowGlobeJson,
                          repeat: true,
                          fit: BoxFit.contain,
                        ),
                      )
                    : const Icon(Icons.spa_rounded, size: 20),
                SizedBox(width: 10),
                Text("Start Booking"),
                SizedBox(width: 10),
                Icon(Icons.arrow_forward_rounded, size: 22),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatOptionGrid(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gap = isMobile ? 8 : 14;
        final double itemWidth = (constraints.maxWidth - (gap * 2)) / 3;
        final double itemHeight = isMobile ? 112 : 126;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: gap,
          children: [
            _chatOption(
              Icons.event_available_rounded,
              "Booking",
              _openBookingFlow,
              itemWidth,
              itemHeight,
              isMobile,
            ),
            _chatOption(
              Icons.local_offer_rounded,
              "Promo",
              _openPromoFlow,
              itemWidth,
              itemHeight,
              isMobile,
            ),
            _chatOption(
              Icons.add_circle_rounded,
              "Add-Ons",
              _openAddOnsFlow,
              itemWidth,
              itemHeight,
              isMobile,
            ),
            _chatOption(
              Icons.weekend_rounded,
              "Seat View",
              _openSeatFlow,
              itemWidth,
              itemHeight,
              isMobile,
            ),
            _chatOption(
              Icons.fact_check_rounded,
              "Attendance",
              _openAttendanceFlow,
              itemWidth,
              itemHeight,
              isMobile,
            ),
            _chatOption(
              Icons.receipt_long_rounded,
              "Receipt",
              _openReceiptFlow,
              itemWidth,
              itemHeight,
              isMobile,
            ),
          ],
        );
      },
    );
  }

  Widget _chatOption(
    IconData icon,
    String label,
    VoidCallback onTap,
    double width,
    double height,
    bool isMobile,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: isBusy ? null : onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: width,
            height: height,
            decoration: selectedTheme == "Christmas"
                ? BookAddStyles.christmasOptionCard
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: Colors.white.withOpacity(0.48),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.70),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.13),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: isMobile ? 54 : 62,
                  height: isMobile ? 54 : 62,
                  decoration: selectedTheme == "Christmas"
                      ? BookAddStyles.christmasOptionIcon
                      : BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF6EDC6F),
                              Color(0xFF35A853),
                              Color(0xFF176B2C),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF35A853).withOpacity(0.42),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: isMobile ? 29 : 34,
                  ),
                ),
                SizedBox(height: isMobile ? 7 : 9),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: selectedTheme == "Christmas"
                      ? BookAddStyles.christmasOptionText.copyWith(
                          fontSize: isMobile ? 11.5 : 13,
                        )
                      : TextStyle(
                          fontSize: isMobile ? 11.5 : 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF173B1C),
                          letterSpacing: 0.1,
                          shadows: const [
                            Shadow(
                              color: Colors.white,
                              blurRadius: 8,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatState(bool isMobile) {
    return Center(
      key: const ValueKey("chat-state"),
      child: Container(
        width: isMobile ? double.infinity : 580,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 18 : 30,
          vertical: isMobile ? 10 : 24,
        ),
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () {
                setState(() {
                  started = false;
                  messages.clear();
                });
              },
              child: Lottie.asset(
                selectedTheme == "Christmas"
                    ? BookAddStyles.christmasTreeJson
                    : 'assets/lottie/flower.json',
                width: isMobile ? 72 : 88,
                height: isMobile ? 72 : 88,
                repeat: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Welcome to Me Tyme Lounge",
              textAlign: TextAlign.center,
              style: BookAddStyles.bigTitle.copyWith(
                fontSize: isMobile ? 24 : 30,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF21351F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please choose an option below",
              textAlign: TextAlign.center,
              style: BookAddStyles.subtitle.copyWith(
                color: Colors.black.withOpacity(0.62),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            _buildChatOptionGrid(isMobile),
          ],
        ),
      ),
    );
  }
}

class ChristmasLightsBorderPainter extends CustomPainter {
  final double progress;
  final double radius;

  ChristmasLightsBorderPainter({required this.progress, required this.radius});

  final List<Color> bulbColors = const [
    Color(0xFFE53935), // red
    Color(0xFF43A047), // green
    Color(0xFFFFC107), // gold
    Color(0xFF1E88E5), // blue
    Color(0xFFFF7043), // orange
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    final borderPaint = Paint()
      ..color = const Color(0xFFFFD166).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawRRect(rect.deflate(1.5), borderPaint);

    final bulbPaint = Paint()..style = PaintingStyle.fill;
    const double gap = 34;
    const double bulbSize = 4.8;

    void drawBulb(double x, double y, int index) {
      final color =
          bulbColors[(index + (progress * 10).floor()) % bulbColors.length];
      final glow = 0.45 + (sin((progress * 6.28) + index) * 0.25);

      bulbPaint.color = color.withOpacity(0.95);

      final glowPaint = Paint()
        ..color = color.withOpacity(glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

      canvas.drawCircle(Offset(x, y), bulbSize + 3, glowPaint);
      canvas.drawCircle(Offset(x, y), bulbSize, bulbPaint);
    }

    int i = 0;

    for (double x = 28; x < size.width - 28; x += gap) {
      drawBulb(x, 4, i++);
      drawBulb(x, size.height - 4, i++);
    }

    for (double y = 28; y < size.height - 28; y += gap) {
      drawBulb(4, y, i++);
      drawBulb(size.width - 4, y, i++);
    }
  }

  @override
  bool shouldRepaint(covariant ChristmasLightsBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class ChristmasSnowPainter extends CustomPainter {
  final double progress;

  ChristmasSnowPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const spacingX = 90.0;
    const spacingY = 70.0;

    int index = 0;

    for (double x = 20; x < size.width; x += spacingX) {
      for (double y = 0; y < size.height; y += spacingY) {
        final offsetY = ((progress * (30 + (index % 5) * 8)) + y) % size.height;

        final offsetX = x + sin(progress * 6.28 + index) * 6;

        _drawSnowflake(
          canvas,
          Offset(offsetX, offsetY),
          paint,
          3 + (index % 3),
        );

        index++;
      }
    }
  }

  void _drawSnowflake(
    Canvas canvas,
    Offset center,
    Paint paint,
    double radius,
  ) {
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx - radius * .7, center.dy - radius * .7),
      Offset(center.dx + radius * .7, center.dy + radius * .7),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx - radius * .7, center.dy + radius * .7),
      Offset(center.dx + radius * .7, center.dy - radius * .7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ChristmasSnowPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
