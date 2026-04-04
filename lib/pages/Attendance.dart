import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../styles/Attendance_styles.dart';

const double _hourlyRate = 20;
const int _freeMinutes = 0;

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final TextEditingController codeController = TextEditingController();
  final TextEditingController noteController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late final AnimationController pageController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;

  bool isSubmitting = false;

  String attendanceAction = 'IN'; // IN / OUT
  final List<Map<String, dynamic>> messages = [];

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

    addAI(
      'Welcome to Attendance Assistant.\n\nEnter your Booking Code or Promo Code, then choose IN or OUT.',
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    noteController.dispose();
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  void addAI(String text) {
    setState(() {
      messages.add({'isAI': true, 'text': text});
    });
    _scrollToBottom();
  }

  void addUser(String text) {
    setState(() {
      messages.add({'isAI': false, 'text': text});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 220,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  String normalizeCode(String raw) {
    return raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  DateTime getManilaNow() {
    final now = DateTime.now().toUtc().add(const Duration(hours: 8));
    return DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
      now.microsecond,
    );
  }

  String getManilaYMD() {
    final m = getManilaNow();
    final mm = m.month.toString().padLeft(2, '0');
    final dd = m.day.toString().padLeft(2, '0');
    return '${m.year}-$mm-$dd';
  }

  int diffMinutes(DateTime start, DateTime end) {
    return end.difference(start).inMinutes < 0
        ? 0
        : end.difference(start).inMinutes;
  }

  double billAmountFromMinutes(int minutes) {
    final billableMin = minutes - _freeMinutes;
    final safeBillable = billableMin < 0 ? 0 : billableMin;
    return (safeBillable / 60) * _hourlyRate;
  }

  String formatName(dynamic value) {
    final v = (value ?? '').toString().trim();
    return v.isEmpty ? 'Customer' : v;
  }

  Future<Map<String, dynamic>?> findCustomerSessionByCode(String code) async {
    final data = await supabase
        .from('customer_sessions')
        .select(
          'id, full_name, booking_code, reservation, reservation_date, reservation_end_date, hour_avail, time_started, time_ended, expected_end_at, total_time, total_amount',
        )
        .eq('booking_code', code)
        .limit(1)
        .maybeSingle();

    return data;
  }

  Future<Map<String, dynamic>?> findPromoBookingByCode(String code) async {
    final data = await supabase
        .from('promo_bookings')
        .select(
          'id, full_name, promo_code, attempts_left, max_attempts, validity_end_at, start_at, end_at',
        )
        .eq('promo_code', code)
        .limit(1)
        .maybeSingle();

    return data;
  }

  Future<Map<String, dynamic>?> findOpenCustomerAttendanceLogToday(
    String sessionId,
    String ymd,
  ) async {
    final data = await supabase
        .from('customer_session_attendance')
        .select(
          'id, session_id, booking_code, attendance_date, in_at, out_at, note, auto_closed, created_at',
        )
        .eq('session_id', sessionId)
        .eq('attendance_date', ymd)
        .filter('out_at', 'is', null)
        .limit(1)
        .maybeSingle();

    return data;
  }

  Future<Map<String, dynamic>?> findLatestCustomerAttendanceLogToday(
    String sessionId,
    String ymd,
  ) async {
    final rows = await supabase
        .from('customer_session_attendance')
        .select(
          'id, session_id, booking_code, attendance_date, in_at, out_at, note, auto_closed, created_at',
        )
        .eq('session_id', sessionId)
        .eq('attendance_date', ymd)
        .order('in_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return (rows as List).first as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> findOpenPromoAttendanceLogToday(
    String promoBookingId,
    String ymd,
  ) async {
    final data = await supabase
        .from('promo_booking_attendance')
        .select(
          'id, created_at, promo_booking_id, local_day, in_at, out_at, auto_out, note',
        )
        .eq('promo_booking_id', promoBookingId)
        .eq('local_day', ymd)
        .filter('out_at', 'is', null)
        .limit(1)
        .maybeSingle();

    return data;
  }

  Future<Map<String, dynamic>?> findLatestPromoAttendanceLogToday(
    String promoBookingId,
    String ymd,
  ) async {
    final rows = await supabase
        .from('promo_booking_attendance')
        .select(
          'id, created_at, promo_booking_id, local_day, in_at, out_at, auto_out, note',
        )
        .eq('promo_booking_id', promoBookingId)
        .eq('local_day', ymd)
        .order('in_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return (rows as List).first as Map<String, dynamic>;
  }

  bool isPromoExpired(Map<String, dynamic> promo) {
    final expiryIso = promo['validity_end_at']?.toString();
    final endIso = promo['end_at']?.toString();
    final check = expiryIso ?? endIso;
    if (check == null || check.isEmpty) return false;

    final expiry = DateTime.tryParse(check)?.toUtc();
    if (expiry == null) return false;

    return DateTime.now().toUtc().isAfter(expiry);
  }

  bool isPromoNotStarted(Map<String, dynamic> promo) {
    final startIso = promo['start_at']?.toString();
    if (startIso == null || startIso.isEmpty) return false;

    final start = DateTime.tryParse(startIso)?.toUtc();
    if (start == null) return false;

    return DateTime.now().toUtc().isBefore(start);
  }

  bool isAttendanceRequiredForSession(Map<String, dynamic> session) {
    final reservation = (session['reservation'] ?? '').toString().toLowerCase();
    final hourAvail = (session['hour_avail'] ?? '').toString().toUpperCase();

    if (reservation == 'yes') return true;
    if (hourAvail == 'OPEN') return true;

    return false;
  }

  Future<void> handleAttendance() async {
    final rawCode = codeController.text;
    final code = normalizeCode(rawCode);
    final note = noteController.text.trim();

    if (code.isEmpty) {
      addAI('⚠️ Please enter your code first.');
      return;
    }

    addUser('$attendanceAction • $code');

    setState(() {
      isSubmitting = true;
    });

    try {
      final session = await findCustomerSessionByCode(code);

      if (session != null) {
        await handleCustomerAttendance(session, code, note);
        setState(() {
          isSubmitting = false;
        });
        return;
      }

      final promo = await findPromoBookingByCode(code);

      if (promo != null) {
        await handlePromoAttendance(promo, code, note);
        setState(() {
          isSubmitting = false;
        });
        return;
      }

      addAI('❌ Code not found.');
    } catch (e) {
      addAI('❌ Error: $e');
    }

    setState(() {
      isSubmitting = false;
    });
  }

  Future<void> handleCustomerAttendance(
    Map<String, dynamic> session,
    String code,
    String note,
  ) async {
    final sessionId = session['id'].toString();
    final customerName = formatName(session['full_name']);
    final manilaYmd = getManilaYMD();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    if (!isAttendanceRequiredForSession(session)) {
      addAI(
        '⚠️ Attendance is only required for Reservation bookings or Open Time bookings.',
      );
      return;
    }

    if (attendanceAction == 'IN') {
      final openLog = await findOpenCustomerAttendanceLogToday(
        sessionId,
        manilaYmd,
      );

      if (openLog != null) {
        addAI('⚠️ You are already IN attendance, $customerName.');
        addAI(
          'Please proceed with OUT attendance when your session is finished.',
        );
        return;
      }

      await supabase.from('customer_session_attendance').insert({
        'session_id': sessionId,
        'booking_code': code,
        'attendance_date': manilaYmd,
        'in_at': nowIso,
        'out_at': null,
        'note': note.isEmpty ? null : note,
        'auto_closed': false,
      });

      addAI('✅ Reservation / Booking Attendance IN successful.');
      addAI('Your attendance IN has been recorded for $customerName.');
      addAI('Thank you! 😊');
      return;
    }

    final openLog = await findOpenCustomerAttendanceLogToday(
      sessionId,
      manilaYmd,
    );

    if (openLog == null) {
      final latest = await findLatestCustomerAttendanceLogToday(
        sessionId,
        manilaYmd,
      );

      if (latest != null && latest['out_at'] != null) {
        addAI('⚠️ Your attendance is already OUT for today, $customerName.');
      } else {
        addAI('⚠️ No active IN attendance found.');
        addAI('Please do IN attendance first.');
      }
      return;
    }

    await supabase
        .from('customer_session_attendance')
        .update({
          'out_at': nowIso,
          'note': note.isEmpty ? openLog['note'] : note,
          'auto_closed': false,
        })
        .eq('id', openLog['id']);

    final inAt = DateTime.tryParse(openLog['in_at'].toString())?.toUtc();
    final outAt = DateTime.tryParse(nowIso)?.toUtc();

    if (inAt != null && outAt != null) {
      final minutes = diffMinutes(inAt, outAt);
      final hoursDecimal = double.parse((minutes / 60).toStringAsFixed(2));
      final amount = billAmountFromMinutes(minutes);

      final oldTotalTime =
          double.tryParse((session['total_time'] ?? '0').toString()) ?? 0;
      final oldTotalAmount =
          double.tryParse((session['total_amount'] ?? '0').toString()) ?? 0;

      await supabase
          .from('customer_sessions')
          .update({
            'total_time': double.parse(
              (oldTotalTime + hoursDecimal).toStringAsFixed(2),
            ),
            'total_amount': double.parse(
              (oldTotalAmount + amount).toStringAsFixed(2),
            ),
          })
          .eq('id', sessionId);
    }

    addAI('✅ Reservation / Booking Attendance OUT successful.');
    addAI('Your attendance OUT has been recorded for $customerName.');
    addAI('Thank you! 😊');
  }

  Future<void> handlePromoAttendance(
    Map<String, dynamic> promo,
    String code,
    String note,
  ) async {
    final promoId = promo['id'].toString();
    final customerName = formatName(promo['full_name']);
    final manilaYmd = getManilaYMD();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    if (attendanceAction == 'IN') {
      if (isPromoNotStarted(promo)) {
        addAI('⚠️ This promo code is not active yet.');
        addAI('Please wait until your promo booking time starts.');
        return;
      }

      if (isPromoExpired(promo)) {
        addAI('❌ This promo code is already expired.');
        return;
      }

      final openLog = await findOpenPromoAttendanceLogToday(promoId, manilaYmd);

      if (openLog != null) {
        addAI('⚠️ You are already IN attendance for promo, $customerName.');
        addAI(
          'Please proceed with OUT attendance when your promo session is finished.',
        );
        return;
      }

      await supabase.from('promo_booking_attendance').insert({
        'promo_booking_id': promoId,
        'local_day': manilaYmd,
        'in_at': nowIso,
        'out_at': null,
        'auto_out': false,
        'note': note.isEmpty ? null : note,
      });

      addAI('✅ Promo Attendance IN successful.');
      addAI('Your promo attendance IN has been recorded for $customerName.');
      addAI('Thank you! 😊');
      return;
    }

    final openLog = await findOpenPromoAttendanceLogToday(promoId, manilaYmd);

    if (openLog == null) {
      final latest = await findLatestPromoAttendanceLogToday(
        promoId,
        manilaYmd,
      );

      if (latest != null && latest['out_at'] != null) {
        addAI(
          '⚠️ Your promo attendance is already OUT for today, $customerName.',
        );
      } else {
        addAI('⚠️ No active promo IN attendance found.');
        addAI('Please do IN attendance first.');
      }
      return;
    }

    await supabase
        .from('promo_booking_attendance')
        .update({
          'out_at': nowIso,
          'note': note.isEmpty ? openLog['note'] : note,
          'auto_out': false,
        })
        .eq('id', openLog['id']);

    addAI('✅ Promo Attendance OUT successful.');
    addAI('Your promo attendance OUT has been recorded for $customerName.');
    addAI('Thank you! 😊');
  }

  Widget buildLogo(double size) {
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

  Widget bubble(Map<String, dynamic> msg, bool isMobile) {
    final isAI = msg['isAI'] == true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isAI
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            buildLogo(isMobile ? 34 : 38),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: isMobile ? 255 : 500),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 12 : 14,
              ),
              decoration: isAI
                  ? AttendanceStyles.aiBubble
                  : AttendanceStyles.userBubble,
              child: Text(
                msg['text']?.toString() ?? '',
                style: isAI
                    ? AttendanceStyles.aiText
                    : AttendanceStyles.userText,
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
    final isMobile = screen.width < 640;
    final isTablet = screen.width >= 640 && screen.width < 1100;

    final double modalWidth = isMobile
        ? screen.width - 20
        : isTablet
        ? 760
        : 860;

    final double modalHeight = isMobile
        ? screen.height * 0.92
        : isTablet
        ? 760
        : 820;

    return Scaffold(
      backgroundColor: AttendanceStyles.pageBg,
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
                decoration: AttendanceStyles.modalCard,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: AttendanceStyles.headerCard,
                      child: Row(
                        children: [
                          buildLogo(isMobile ? 42 : 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Attendance Assistant',
                                  style: AttendanceStyles.title,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Use Booking Code or Promo Code for attendance IN / OUT.',
                                  style: AttendanceStyles.subtitle,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: AttendanceStyles.statusChip,
                            child: Text(
                              'Attendance',
                              style: AttendanceStyles.chipText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 12 : 18),
                        decoration: AttendanceStyles.chatArea,
                        child: ListView(
                          controller: scrollController,
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 14 : 18),
                              decoration: AttendanceStyles.formCard,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Attendance Form',
                                    style: AttendanceStyles.sectionTitle,
                                  ),
                                  const SizedBox(height: 14),

                                  Text('Code', style: AttendanceStyles.label),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: codeController,
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    decoration: AttendanceStyles.inputDecoration(
                                      hintText:
                                          'Enter Booking Code or Promo Code',
                                      suffixIcon: const Icon(
                                        Icons.qr_code_rounded,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),
                                  Text(
                                    'Note (Optional)',
                                    style: AttendanceStyles.label,
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: noteController,
                                    maxLines: 3,
                                    decoration:
                                        AttendanceStyles.inputDecoration(
                                          hintText: 'Enter note if needed',
                                        ),
                                  ),

                                  const SizedBox(height: 14),
                                  Text('Action', style: AttendanceStyles.label),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              attendanceAction = 'IN';
                                            });
                                          },
                                          style: attendanceAction == 'IN'
                                              ? AttendanceStyles.primaryButton
                                              : AttendanceStyles
                                                    .secondaryButton,
                                          child: const Text('IN'),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              attendanceAction = 'OUT';
                                            });
                                          },
                                          style: attendanceAction == 'OUT'
                                              ? AttendanceStyles.dangerButton
                                              : AttendanceStyles
                                                    .secondaryButton,
                                          child: const Text('OUT'),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: isSubmitting
                                              ? null
                                              : handleAttendance,
                                          style: attendanceAction == 'IN'
                                              ? AttendanceStyles.primaryButton
                                              : AttendanceStyles.dangerButton,
                                          child: Text(
                                            isSubmitting
                                                ? 'Submitting...'
                                                : 'Submit Attendance',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            ...messages.map((e) => bubble(e, isMobile)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: AttendanceStyles.secondaryButton,
                            child: const Text('Close'),
                          ),
                        ),
                      ],
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
}
