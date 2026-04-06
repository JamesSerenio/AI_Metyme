import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'styles/Noisy_styles.dart';

enum ReportType { concern, feedback, suggestion, complaint, request, other }

class NoisyPage extends StatefulWidget {
  const NoisyPage({super.key});

  @override
  State<NoisyPage> createState() => _NoisyPageState();
}

class _NoisyPageState extends State<NoisyPage> with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController codeController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool isVerifying = false;
  bool isVerified = false;
  bool isSubmitting = false;
  bool submitted = false;

  late final AnimationController pageController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;

  String fullName = '';
  String seatNumber = '';
  ReportType reportType = ReportType.concern;

  String get code => codeController.text.trim().toUpperCase();

  @override
  void initState() {
    super.initState();

    pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    fadeAnim = CurvedAnimation(
      parent: pageController,
      curve: Curves.easeOutCubic,
    );

    slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: pageController, curve: Curves.easeOutCubic),
        );

    pageController.forward();
  }

  @override
  void dispose() {
    codeController.dispose();
    messageController.dispose();
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 240,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
  }

  String reportLabel(ReportType type) {
    switch (type) {
      case ReportType.concern:
        return 'Concern';
      case ReportType.feedback:
        return 'Feedback';
      case ReportType.suggestion:
        return 'Suggestion';
      case ReportType.complaint:
        return 'Complaint';
      case ReportType.request:
        return 'Request';
      case ReportType.other:
        return 'Other';
    }
  }

  Future<void> verifyCode() async {
    if (code.isEmpty) {
      showSnack("Enter code first");
      return;
    }

    setState(() {
      isVerifying = true;
      submitted = false;
    });

    try {
      final DateTime now = DateTime.now();

      final Map<String, dynamic>? session = await supabase
          .from('customer_sessions')
          .select('full_name, seat_number, time_started, time_ended')
          .eq('booking_code', code)
          .maybeSingle();

      if (session != null) {
        final DateTime? start = DateTime.tryParse(
          (session['time_started'] ?? '').toString(),
        );
        final DateTime? end = DateTime.tryParse(
          (session['time_ended'] ?? '').toString(),
        );

        bool active = false;

        if (start != null) {
          if (end == null) {
            active = !now.isBefore(start);
          } else {
            active = !now.isBefore(start) && now.isBefore(end);
          }
        }

        if (!active) {
          showSnack("Code not active yet or expired");
          return;
        }

        setState(() {
          isVerified = true;
          fullName = (session['full_name'] ?? '').toString();
          seatNumber = (session['seat_number'] ?? '').toString();
        });

        scrollToBottom();
        return;
      }

      final Map<String, dynamic>? promo = await supabase
          .from('promo_bookings')
          .select('full_name, seat_number, area, start_at, end_at')
          .eq('promo_code', code)
          .maybeSingle();

      if (promo != null) {
        final DateTime? start = DateTime.tryParse(
          (promo['start_at'] ?? '').toString(),
        );
        final DateTime? end = DateTime.tryParse(
          (promo['end_at'] ?? '').toString(),
        );

        bool active = false;

        if (start != null && end != null) {
          active = !now.isBefore(start) && now.isBefore(end);
        }

        if (!active) {
          showSnack("Promo not active or expired");
          return;
        }

        final String area = (promo['area'] ?? '').toString();
        final String rawSeat = (promo['seat_number'] ?? '').toString();

        setState(() {
          isVerified = true;
          fullName = (promo['full_name'] ?? '').toString();
          seatNumber = area == 'conference_room' ? 'CONFERENCE ROOM' : rawSeat;
        });

        scrollToBottom();
        return;
      }

      showSnack("Invalid code");
    } catch (e) {
      showSnack("Verification error");
    } finally {
      if (!mounted) return;
      setState(() => isVerifying = false);
    }
  }

  Future<void> submitReport() async {
    final String msg = messageController.text.trim();

    if (!isVerified) {
      showSnack("Verify code first");
      return;
    }

    if (msg.isEmpty) {
      showSnack("Message required");
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await supabase.from('noisy_reports').insert({
        "name": fullName,
        "seat_number": seatNumber,
        "report_type": reportType.name,
        "message": msg,
        "concern": msg,
        "status": "pending",
        "is_read": false,
      });

      setState(() {
        submitted = true;
        messageController.clear();
      });

      scrollToBottom();
    } catch (e) {
      showSnack("Failed to submit");
    } finally {
      if (!mounted) return;
      setState(() => isSubmitting = false);
    }
  }

  Widget buildAiBubble({required String text, bool showAvatar = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            Container(
              width: 38,
              height: 38,
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
                  errorBuilder: (_, __, ___) {
                    return const Icon(Icons.campaign_outlined);
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: NoisyStyles.aiBubble,
              child: Text(text, style: NoisyStyles.aiText),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: NoisyStyles.successBubble,
              child: Text(text, style: NoisyStyles.successText),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: NoisyStyles.infoInnerCard,
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: NoisyStyles.mutedText.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: NoisyStyles.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVerificationCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: NoisyStyles.formCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter Code', style: NoisyStyles.sectionTitle),
          const SizedBox(height: 14),
          Text(
            'Use your walk-in, reservation, or promo code first.',
            style: NoisyStyles.mutedText,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: NoisyStyles.textDark,
              letterSpacing: 1.2,
            ),
            decoration: NoisyStyles.inputDecoration(
              hintText: 'Enter your code',
              suffixIcon: const Icon(Icons.qr_code_2_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isVerifying ? null : verifyCode,
                  style: NoisyStyles.primaryButton,
                  child: Text(isVerifying ? 'VERIFYING...' : 'VERIFY CODE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildReportForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: NoisyStyles.formCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Noisy Report Form', style: NoisyStyles.sectionTitle),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: NoisyStyles.infoCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: NoisyStyles.primaryDark,
                    ),
                    const SizedBox(width: 8),
                    Text('Verified Customer', style: NoisyStyles.sectionTitle),
                  ],
                ),
                const SizedBox(height: 14),
                buildInfoRow('Code', code),
                const SizedBox(height: 10),
                buildInfoRow('Full Name', fullName),
                const SizedBox(height: 10),
                buildInfoRow('Seat', seatNumber),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReportType>(
            value: reportType,
            decoration: NoisyStyles.inputDecoration(hintText: 'Select type'),
            borderRadius: BorderRadius.circular(18),
            items: ReportType.values
                .map(
                  (e) => DropdownMenuItem<ReportType>(
                    value: e,
                    child: Text(reportLabel(e)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => reportType = v);
            },
          ),
          const SizedBox(height: 14),
          TextField(
            controller: messageController,
            maxLines: 5,
            decoration: NoisyStyles.inputDecoration(
              hintText: 'Write your message here...',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitReport,
                  style: NoisyStyles.primaryButton,
                  child: Text(isSubmitting ? 'SUBMITTING...' : 'SUBMIT REPORT'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      messageController.clear();
                      submitted = false;
                    });
                  },
                  style: NoisyStyles.secondaryButton,
                  child: const Text('CLEAR MESSAGE'),
                ),
              ),
            ],
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

    final double modalWidth = isMobile
        ? screen.width - 20
        : isTablet
        ? 500
        : 620;

    final double modalHeight = isMobile
        ? screen.height * 0.92
        : isTablet
        ? 560
        : 680;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: NoisyStyles.pageBg,
        body: SafeArea(
          child: FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Center(
                child: Container(
                  width: modalWidth,
                  height: modalHeight,
                  margin: EdgeInsets.all(isMobile ? 10 : 18),
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  decoration: NoisyStyles.modalCard,
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: NoisyStyles.headerCard,
                        child: Row(
                          children: [
                            Container(
                              width: isMobile ? 42 : 48,
                              height: isMobile ? 42 : 48,
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
                                  errorBuilder: (_, __, ___) {
                                    return const Icon(Icons.volume_up_outlined);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Noisy Report Assistant',
                                    style: NoisyStyles.title,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Code first, then submit your concern or report.',
                                    style: NoisyStyles.subtitle,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 7,
                              ),
                              decoration: NoisyStyles.statusChip,
                              child: Text(
                                'AI REPORT',
                                style: NoisyStyles.chipText,
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
                          decoration: NoisyStyles.chatArea,
                          child: ListView(
                            controller: scrollController,
                            children: [
                              buildUserBubble(
                                'I want to report something noisy.',
                              ),
                              buildAiBubble(
                                text:
                                    'Hello! Please enter your walk-in, reservation, or promo code first so I can verify if your schedule is active.',
                              ),
                              const SizedBox(height: 8),
                              buildVerificationCard(isMobile),
                              if (isVerified) ...[
                                const SizedBox(height: 12),
                                buildAiBubble(
                                  text:
                                      'Hi $fullName, your code is active. You can now submit your report.',
                                ),
                                const SizedBox(height: 8),
                                buildReportForm(isMobile),
                              ],
                              if (submitted) ...[
                                const SizedBox(height: 12),
                                buildAiBubble(
                                  text:
                                      'Your report has been submitted successfully.',
                                ),
                                buildAiBubble(
                                  text:
                                      'Thank you. Our staff will review your message as soon as possible.',
                                ),
                              ],
                            ],
                          ),
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
}
