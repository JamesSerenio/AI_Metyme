import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
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

  late final List<String> displayImages;

  static const int _loopStartPage = 10000;
  int currentAbsolutePage = _loopStartPage;
  int currentDisplayIndex = 0;

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
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void startChat() {
    if (started) return;

    setState(() {
      started = true;
      messages.add({
        "isAI": true,
        "text":
            "Welcome to Me Tyme Lounge! ✨\n\nPlease choose one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo\n6. View Receipt",
      });
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
      MaterialPageRoute(builder: (_) => const BookingModalPage()),
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
      MaterialPageRoute(builder: (_) => const PromoModalPage()),
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
    return Container(
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
    );
  }

  Widget _leafInside({
    required double width,
    required double angle,
    required bool invertY,
  }) {
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
        child: Opacity(
          opacity: 0.95,
          child: Image.asset(
            'assets/leave.png',
            width: width,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
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
                animation: ambientFloatAnim,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(ambientFloatAnim.value * 0.9, 0),
                    child: child,
                  );
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.10, end: 1.0),
                  duration: const Duration(milliseconds: 1400),
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) {
                    return Transform.scale(scale: scale, child: child);
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
                  Colors.white.withOpacity(0.36),
                  Colors.white.withOpacity(0.16),
                  Colors.white.withOpacity(0.34),
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
                  const Color(0xFFF7EEDB).withOpacity(0.58),
                  const Color(0xFFF7EEDB).withOpacity(0.25),
                  const Color(0xFFF2E7D3).withOpacity(0.56),
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
                colors: [
                  Colors.white.withOpacity(0.04),
                  Colors.black.withOpacity(0.08),
                ],
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
            vertical: isMobile ? 18 : 24,
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
                            ? BookAddStyles.bigTitle.copyWith(fontSize: 26)
                            : BookAddStyles.bigTitle)
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
              child: Text(
                msg["text"]?.toString() ?? "",
                style: isAI
                    ? BookAddStyles.chatTextAI
                    : BookAddStyles.chatTextUser,
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
        ? screen.height * 0.80
        : isTablet
        ? 500
        : 520;

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
                          decoration: BookAddStyles.mainCard,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(32),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _buildDisplayBackground(isMobile),
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
                        top: isMobile ? -8 : -10,
                        left: isMobile ? -6 : -10,
                        child: _leafInside(
                          width: leafWidth,
                          angle: 0,
                          invertY: true,
                        ),
                      ),
                      Positioned(
                        top: isMobile ? -8 : -10,
                        right: isMobile ? -6 : -10,
                        child: _leafInside(
                          width: leafWidth,
                          angle: 3.14159,
                          invertY: false,
                        ),
                      ),
                      Positioned(
                        bottom: isMobile ? -8 : -10,
                        left: isMobile ? -6 : -10,
                        child: _leafInside(
                          width: leafWidth,
                          angle: 0,
                          invertY: false,
                        ),
                      ),
                      Positioned(
                        bottom: isMobile ? -8 : -10,
                        right: isMobile ? -6 : -10,
                        child: _leafInside(
                          width: leafWidth,
                          angle: -1.5708,
                          invertY: false,
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

  Widget _buildStartState(bool isMobile) {
    return Column(
      key: const ValueKey("start-state"),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BookAddStyles.headerCard,
          child: Row(
            children: [
              _buildLogo(isMobile ? 46 : 52),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to Me Tyme Lounge!",
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
                  decoration: BookAddStyles.readyChip,
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
                      Text("Ready for booking", style: BookAddStyles.readyText),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 34 : 46),
        _buildHeroPanel(isMobile),
        SizedBox(height: isMobile ? 26 : 34),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: ElevatedButton(
            onPressed: startChat,
            style: BookAddStyles.primaryButton,
            child: const Text("Start"),
          ),
        ),
      ],
    );
  }

  Widget _buildChatState(bool isMobile) {
    return Column(
      key: const ValueKey("chat-state"),
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BookAddStyles.headerCard,
          child: Row(
            children: [
              _buildLogo(isMobile ? 40 : 46),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI Assistant", style: BookAddStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      isBusy
                          ? "Opening your selected view..."
                          : "Reply with 1 to 6 to continue.",
                      style: BookAddStyles.helperText,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BookAddStyles.onlineChip,
                child: Text(
                  isBusy ? "Loading" : "Online",
                  style: BookAddStyles.onlineText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 12 : 18),
            decoration: BookAddStyles.chatContainer,
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return chatBubble(messages[index], isMobile);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                enabled: !isBusy,
                textInputAction: TextInputAction.send,
                onSubmitted: sendMessage,
                style: BookAddStyles.inputText,
                decoration: BookAddStyles.inputDecoration(
                  hintText: isBusy
                      ? "Opening your selected view..."
                      : "Type 1-6...",
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              width: 56,
              child: ElevatedButton(
                onPressed: isBusy ? null : () => sendMessage(controller.text),
                style: BookAddStyles.sendButton,
                child: const Icon(Icons.send_rounded),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
