import 'package:flutter/material.dart';
import 'styles/Book_Add_styles.dart';
import 'pages/BookingModal.dart';
import 'pages/PromoModal.dart';

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

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];

  late final AnimationController pageController;
  late final AnimationController leafController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;
  late final Animation<double> leafFloatAnim;

  @override
  void initState() {
    super.initState();

    pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    leafController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    fadeAnim = CurvedAnimation(
      parent: pageController,
      curve: Curves.easeOutCubic,
    );

    slideAnim = Tween<Offset>(begin: const Offset(0, 0.035), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: pageController, curve: Curves.easeOutCubic),
        );

    leafFloatAnim = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(parent: leafController, curve: Curves.easeInOut));

    pageController.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    pageController.dispose();
    leafController.dispose();
    super.dispose();
  }

  bool get isBusy => openingBooking || openingPromo;

  void startChat() {
    if (started) return;

    setState(() {
      started = true;
      messages.add({
        "isAI": true,
        "text":
            "Welcome to Me Tyme Lounge! ✨\n\nPlease choose one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo",
      });
    });

    _scrollToBottom();
  }

  void sendMessage(String text) {
    final value = text.trim();
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
    });

    setState(() {
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
            "You may choose another service anytime.\n\nPlease select one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo",
      });
    });

    _scrollToBottom();
  }

  Future<void> _openPromoFlow() async {
    if (!mounted || isBusy) return;

    setState(() {
      openingPromo = true;
    });

    setState(() {
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
            "You may choose another service anytime.\n\nPlease select one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo",
      });
    });

    _scrollToBottom();
  }

  void handleAIResponse(String input) {
    final value = input.trim().toLowerCase();

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
        setState(() {
          messages.add({
            "isAI": true,
            "text":
                "You selected Add-Ons 🍔\n\nYou may proceed with food, drinks, and other available add-ons here soon.",
          });
        });
        _scrollToBottom();
        return;

      case "4":
      case "seat view":
      case "seatview":
        setState(() {
          messages.add({
            "isAI": true,
            "text":
                "You selected Seat View 🪑\n\nYou will be able to view available seats here soon.",
          });
        });
        _scrollToBottom();
        return;

      case "5":
      case "attendance":
      case "attendance for reservation and promo":
      case "reservation attendance":
      case "promo attendance":
        setState(() {
          messages.add({
            "isAI": true,
            "text":
                "You selected Attendance for Reservation and Promo ✅\n\nThis option will help you manage attendance for reservation and promo customers, including IN and OUT records.",
          });
        });
        _scrollToBottom();
        return;

      default:
        setState(() {
          messages.add({
            "isAI": true,
            "text":
                "I’m sorry, I could not recognize that selection.\n\nPlease choose one of the following options:\n\n1. Booking\n2. Promo\n3. Add-Ons\n4. Seat View\n5. Attendance for Reservation and Promo",
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
          "assets/study_hub.png",
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
            "assets/leave.png",
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
    final screen = MediaQuery.of(context).size;
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
      body: SafeArea(
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
                        padding: EdgeInsets.all(isMobile ? 14 : 20),
                        decoration: BookAddStyles.mainCard,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 420),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: !started
                              ? _buildStartState(isMobile)
                              : _buildChatState(isMobile),
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
                      style: BookAddStyles.title,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Rest, relax, and focus in a peaceful environment.",
                      style: BookAddStyles.subtitle,
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
        Text(
          "Start Your Booking Assistant",
          textAlign: TextAlign.center,
          style: isMobile
              ? BookAddStyles.bigTitle.copyWith(fontSize: 26)
              : BookAddStyles.bigTitle,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 80),
          child: Text(
            "Click Start to choose Booking, Promo, Add-Ons, Seat View, or Attendance for Reservation and Promo through chat.",
            textAlign: TextAlign.center,
            style: BookAddStyles.subtitle,
          ),
        ),
        SizedBox(height: isMobile ? 28 : 36),
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
                          ? "Opening your selected form..."
                          : "Reply with 1 to 5 to continue.",
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
                      ? "Opening your selected form..."
                      : "Type 1-5...",
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
