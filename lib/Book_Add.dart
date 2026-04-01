import 'package:flutter/material.dart';
import 'styles/Book_Add_styles.dart';

class BookAddPage extends StatefulWidget {
  const BookAddPage({super.key});

  @override
  State<BookAddPage> createState() => _BookAddPageState();
}

class _BookAddPageState extends State<BookAddPage>
    with TickerProviderStateMixin {
  bool started = false;

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];

  late final AnimationController pageController;
  late final AnimationController floatController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;
  late final Animation<double> floatAnim;

  @override
  void initState() {
    super.initState();

    pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    fadeAnim = CurvedAnimation(
      parent: pageController,
      curve: Curves.easeOutCubic,
    );

    slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: pageController, curve: Curves.easeOutCubic),
        );

    floatAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: floatController, curve: Curves.easeInOut),
    );

    pageController.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    pageController.dispose();
    floatController.dispose();
    super.dispose();
  }

  void startChat() {
    if (started) return;

    setState(() {
      started = true;
      messages.add({
        "isAI": true,
        "text":
            "Welcome to Me Tyme Lounge!\n\nPlease choose:\n1 Booking\n2 Promo\n3 Add-Ons\n4 Seat View",
      });
    });

    _scrollToBottom();
  }

  void sendMessage(String text) {
    final value = text.trim();
    if (value.isEmpty) return;

    setState(() {
      messages.add({"isAI": false, "text": value});
    });

    controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 420), () {
      handleAIResponse(value);
    });
  }

  void handleAIResponse(String input) {
    final value = input.trim().toLowerCase();
    String reply;

    switch (value) {
      case "1":
      case "booking":
        reply = "You selected Booking ✅";
        break;
      case "2":
      case "promo":
        reply = "You selected Promo 🎉";
        break;
      case "3":
      case "add-ons":
      case "addons":
      case "add ons":
        reply = "You selected Add-Ons 🍔";
        break;
      case "4":
      case "seat view":
      case "seatview":
        reply = "You selected Seat View 🪑";
        break;
      default:
        reply =
            "Invalid choice ❌\n\nPlease choose:\n1 Booking\n2 Promo\n3 Add-Ons\n4 Seat View";
    }

    setState(() {
      messages.add({"isAI": true, "text": reply});
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 120,
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
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
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

  Widget _leaf({
    required Alignment alignment,
    required double width,
    required double rotation,
    required EdgeInsets margin,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        child: AnimatedBuilder(
          animation: floatAnim,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, floatAnim.value),
              child: Transform.rotate(
                angle: rotation,
                child: Opacity(opacity: 0.95, child: child),
              ),
            );
          },
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

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 280),
      opacity: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
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
              child: Container(
                constraints: BoxConstraints(maxWidth: isMobile ? 255 : 430),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final bool isMobile = screen.width < 600;
    final bool isTablet = screen.width >= 600 && screen.width < 1024;

    double cardWidth;
    if (isMobile) {
      cardWidth = screen.width;
    } else if (isTablet) {
      cardWidth = 760;
    } else {
      cardWidth = 900;
    }

    double cardHeight;
    if (isMobile) {
      cardHeight = screen.height * 0.88;
    } else if (isTablet) {
      cardHeight = 700;
    } else {
      cardHeight = 760;
    }

    final horizontalPad = isMobile ? 12.0 : 20.0;
    final leafWidth = isMobile ? 120.0 : 220.0;

    return Scaffold(
      backgroundColor: BookAddStyles.bgColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(decoration: BookAddStyles.pageBackground),
          ),

          _leaf(
            alignment: Alignment.topLeft,
            width: leafWidth,
            rotation: -0.1,
            margin: EdgeInsets.only(
              top: isMobile ? 10 : 14,
              left: isMobile ? 6 : 12,
            ),
          ),
          _leaf(
            alignment: Alignment.topRight,
            width: leafWidth,
            rotation: 0.05,
            margin: EdgeInsets.only(
              top: isMobile ? 10 : 14,
              right: isMobile ? 6 : 12,
            ),
          ),
          _leaf(
            alignment: Alignment.bottomLeft,
            width: leafWidth,
            rotation: 0.1,
            margin: EdgeInsets.only(
              bottom: isMobile ? 10 : 14,
              left: isMobile ? 6 : 12,
            ),
          ),
          _leaf(
            alignment: Alignment.bottomRight,
            width: leafWidth,
            rotation: -0.05,
            margin: EdgeInsets.only(
              bottom: isMobile ? 10 : 14,
              right: isMobile ? 6 : 12,
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: fadeAnim,
              child: SlideTransition(
                position: slideAnim,
                child: Center(
                  child: Container(
                    width: cardWidth,
                    height: cardHeight,
                    margin: EdgeInsets.all(horizontalPad),
                    padding: EdgeInsets.all(isMobile ? 14 : 18),
                    decoration: BookAddStyles.mainCard,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: !started
                          ? _buildStartState(isMobile)
                          : _buildChatState(isMobile),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartState(bool isMobile) {
    return Column(
      key: const ValueKey("start-state"),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 12 : 14),
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
        SizedBox(height: isMobile ? 30 : 40),
        Text(
          "Start Your Booking Assistant",
          textAlign: TextAlign.center,
          style: isMobile
              ? BookAddStyles.bigTitle.copyWith(fontSize: 24)
              : BookAddStyles.bigTitle,
        ),
        const SizedBox(height: 10),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 6 : 42),
          child: Text(
            "Click Start to choose Booking, Promo, Add-Ons, or Seat View through chat.",
            textAlign: TextAlign.center,
            style: BookAddStyles.subtitle,
          ),
        ),
        SizedBox(height: isMobile ? 26 : 34),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.95, end: 1),
          duration: const Duration(milliseconds: 900),
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
          padding: EdgeInsets.all(isMobile ? 12 : 14),
          decoration: BookAddStyles.headerCard,
          child: Row(
            children: [
              _buildLogo(isMobile ? 42 : 46),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("AI Assistant", style: BookAddStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      "Reply with 1 to 4 to continue.",
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
                child: Text("Online", style: BookAddStyles.onlineText),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            decoration: BookAddStyles.chatContainer,
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 6),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return chatBubble(messages[index], isMobile);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: sendMessage,
                style: BookAddStyles.inputText,
                decoration: BookAddStyles.inputDecoration(
                  hintText: "Type 1-4...",
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 54,
              width: 54,
              child: ElevatedButton(
                onPressed: () => sendMessage(controller.text),
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
