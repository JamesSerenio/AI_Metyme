import 'package:flutter/material.dart';
import 'styles/Book_Add_styles.dart';

class BookAddPage extends StatefulWidget {
  const BookAddPage({super.key});

  @override
  State<BookAddPage> createState() => _BookAddPageState();
}

class _BookAddPageState extends State<BookAddPage> {
  bool started = false;

  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final List<Map<String, dynamic>> messages = [];

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
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

    Future.delayed(const Duration(milliseconds: 400), () {
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
        scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget chatBubble(Map<String, dynamic> msg, bool isMobile) {
    final bool isAI = msg["isAI"] == true;

    return Row(
      mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAI) ...[
          CircleAvatar(
            radius: isMobile ? 16 : 18,
            backgroundColor: Colors.white,
            backgroundImage: const AssetImage("assets/study_hub.png"),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: isMobile ? 260 : 420),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 14,
              vertical: isMobile ? 10 : 12,
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
      cardWidth = 700;
    } else {
      cardWidth = 900;
    }

    double cardHeight;
    if (isMobile) {
      cardHeight = screen.height * 0.86;
    } else if (isTablet) {
      cardHeight = 660;
    } else {
      cardHeight = 720;
    }

    return Scaffold(
      backgroundColor: BookAddStyles.bgColor,
      body: SafeArea(
        child: Center(
          child: Container(
            width: cardWidth,
            height: cardHeight,
            margin: EdgeInsets.all(isMobile ? 12 : 20),
            padding: EdgeInsets.all(isMobile ? 14 : 18),
            decoration: BookAddStyles.mainCard,
            child: !started
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 14),
                        decoration: BookAddStyles.headerCard,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 22 : 26,
                              backgroundColor: Colors.white,
                              backgroundImage: const AssetImage(
                                "assets/study_hub.png",
                              ),
                            ),
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
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 26 : 32),
                      Text(
                        "Start Your Booking Assistant",
                        textAlign: TextAlign.center,
                        style: isMobile
                            ? BookAddStyles.bigTitle.copyWith(fontSize: 22)
                            : BookAddStyles.bigTitle,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 6 : 24,
                        ),
                        child: Text(
                          "Click Start to choose Booking, Promo, Add-Ons, or Seat View through chat.",
                          textAlign: TextAlign.center,
                          style: BookAddStyles.subtitle,
                        ),
                      ),
                      SizedBox(height: isMobile ? 26 : 34),
                      ElevatedButton(
                        onPressed: startChat,
                        style: BookAddStyles.primaryButton,
                        child: const Text("Start"),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 14),
                        decoration: BookAddStyles.headerCard,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: isMobile ? 20 : 22,
                              backgroundColor: Colors.white,
                              backgroundImage: const AssetImage(
                                "assets/study_hub.png",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "AI Assistant",
                                    style: BookAddStyles.title,
                                  ),
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
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BookAddStyles.onlineChip,
                              child: Text(
                                "Online",
                                style: BookAddStyles.onlineText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isMobile ? 10 : 14),
                          decoration: BookAddStyles.chatContainer,
                          child: ListView.builder(
                            controller: scrollController,
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
                            height: 52,
                            width: 52,
                            child: ElevatedButton(
                              onPressed: () => sendMessage(controller.text),
                              style: BookAddStyles.sendButton,
                              child: const Icon(Icons.send),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
