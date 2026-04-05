import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'styles/Noisy_styles.dart';

enum ReportType { concern, feedback, suggestion, complaint, request, other }

class NoisyPage extends StatefulWidget {
  const NoisyPage({super.key});

  @override
  State<NoisyPage> createState() => _NoisyPageState();
}

class _NoisyPageState extends State<NoisyPage> {
  final supabase = Supabase.instance.client;

  final TextEditingController codeController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isVerifying = false;
  bool isVerified = false;
  bool isSubmitting = false;
  bool submitted = false;

  String fullName = '';
  String seatNumber = '';

  ReportType reportType = ReportType.concern;

  String get code => codeController.text.trim().toUpperCase();

  void showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ================= VERIFY CODE =================
  Future<void> verifyCode() async {
    if (code.isEmpty) {
      showSnack("Enter code first");
      return;
    }

    setState(() => isVerifying = true);

    try {
      final now = DateTime.now();

      // check session
      final session = await supabase
          .from('customer_sessions')
          .select('full_name, seat_number, time_started, time_ended')
          .eq('booking_code', code)
          .maybeSingle();

      if (session != null) {
        final start = DateTime.tryParse(session['time_started']);
        final end = DateTime.tryParse(session['time_ended']);

        bool active = false;

        if (start != null) {
          if (end == null) {
            active = now.isAfter(start);
          } else {
            active = now.isAfter(start) && now.isBefore(end);
          }
        }

        if (!active) {
          showSnack("Code not active yet or expired");
          return;
        }

        setState(() {
          isVerified = true;
          fullName = session['full_name'];
          seatNumber = session['seat_number'];
        });

        return;
      }

      // check promo
      final promo = await supabase
          .from('promo_bookings')
          .select('full_name, seat_number, start_at, end_at')
          .eq('promo_code', code)
          .maybeSingle();

      if (promo != null) {
        final start = DateTime.tryParse(promo['start_at']);
        final end = DateTime.tryParse(promo['end_at']);

        bool active = false;

        if (start != null && end != null) {
          active = now.isAfter(start) && now.isBefore(end);
        }

        if (!active) {
          showSnack("Promo not active or expired");
          return;
        }

        setState(() {
          isVerified = true;
          fullName = promo['full_name'];
          seatNumber = promo['seat_number'] ?? '';
        });

        return;
      }

      showSnack("Invalid code");
    } catch (e) {
      showSnack("Verification error");
    } finally {
      setState(() => isVerifying = false);
    }
  }

  // ================= SUBMIT =================
  Future<void> submitReport() async {
    final msg = messageController.text.trim();

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
    } catch (e) {
      showSnack("Failed to submit");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  // ================= UI =================
  Widget aiBubble(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: NoisyStyles.aiBubble,
      child: Text(text, style: NoisyStyles.aiText),
    );
  }

  Widget userBubble(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: NoisyStyles.userBubble,
        child: Text(text, style: NoisyStyles.userText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NoisyStyles.pageBg,
      body: SafeArea(
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(20),
            decoration: NoisyStyles.card,
            child: Column(
              children: [
                Text("Noisy / Concern Assistant", style: NoisyStyles.title),

                const SizedBox(height: 10),

                Expanded(
                  child: ListView(
                    children: [
                      userBubble("I want to report something"),
                      aiBubble(
                        "Please enter your booking or promo code first.",
                      ),

                      const SizedBox(height: 10),

                      // CODE INPUT
                      TextField(
                        controller: codeController,
                        decoration: NoisyStyles.input("Enter Code"),
                      ),

                      const SizedBox(height: 10),

                      ElevatedButton(
                        onPressed: isVerifying ? null : verifyCode,
                        child: Text(
                          isVerifying ? "VERIFYING..." : "VERIFY CODE",
                        ),
                      ),

                      // IF VERIFIED
                      if (isVerified) ...[
                        const SizedBox(height: 16),

                        aiBubble(
                          "Hi $fullName, you can now submit your concern.",
                        ),

                        const SizedBox(height: 10),

                        DropdownButtonFormField<ReportType>(
                          value: reportType,
                          decoration: NoisyStyles.input("Type"),
                          items: ReportType.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => reportType = v!),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: messageController,
                          maxLines: 4,
                          decoration: NoisyStyles.input("Message"),
                        ),

                        const SizedBox(height: 10),

                        ElevatedButton(
                          onPressed: isSubmitting ? null : submitReport,
                          child: Text(
                            isSubmitting ? "Submitting..." : "Submit",
                          ),
                        ),
                      ],

                      if (submitted) ...[
                        const SizedBox(height: 14),
                        aiBubble(
                          "Your report has been submitted successfully.",
                        ),
                      ],
                    ],
                  ),
                ),

                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
