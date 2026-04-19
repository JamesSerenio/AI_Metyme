import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../styles/Attendance_styles.dart';
import 'ViewReceipt.dart';

const double _hourlyRate = 20;
const int _freeMinutes = 0;

enum AttendanceReceiptSource { reservation, promo }

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
  bool hasSubmittedOnce = false;

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
      scroll: false,
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

  void addAI(String text, {bool scroll = true}) {
    setState(() {
      messages.add({'isAI': true, 'text': text});
    });
    if (scroll) _scrollToBottom();
  }

  void addUser(String text, {bool scroll = true}) {
    setState(() {
      messages.add({'isAI': false, 'text': text});
    });
    if (scroll) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 260,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
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

  double toDoubleSafe(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int toIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String peso2(num value) => '₱${value.toStringAsFixed(2)}';

  String formatDateTimeLocal(dynamic iso) {
    if (iso == null) return '—';
    final parsed = DateTime.tryParse(iso.toString());
    if (parsed == null) return '—';

    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.month}/${local.day}/${local.year}, $hour:$minute $ampm';
  }

  double applyDiscountValue({
    required double base,
    required String kind,
    required double value,
  }) {
    final double safeBase = base < 0 ? 0.0 : base;
    final double safeValue = value < 0 ? 0.0 : value;

    if (kind == 'percent') {
      final double pct = safeValue.clamp(0, 100).toDouble();
      return math.max(0.0, safeBase - ((safeBase * pct) / 100)).toDouble();
    }

    if (kind == 'amount') {
      return math.max(0.0, safeBase - safeValue).toDouble();
    }

    return safeBase.toDouble();
  }

  Future<Map<String, dynamic>?> loadCustomerOrderPaymentRow(String code) async {
    if (code.trim().isEmpty) return null;

    final row = await supabase
        .from('customer_order_payments')
        .select('*')
        .eq('booking_code', code.trim().toUpperCase())
        .maybeSingle();

    return row == null ? null : Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> loadAttendanceReceiptBundle(
    String bookingCode,
  ) async {
    final code = bookingCode.trim().toUpperCase();

    final List<Map<String, dynamic>> orderLines = [];
    double orderDisplayTotal = 0;

    if (code.isEmpty) {
      return {'orderLines': orderLines, 'orderDisplayTotal': 0.0};
    }

    try {
      final addonOrdersRes = await supabase
          .from('addon_orders')
          .select('''
        id,
        booking_code,
        total_amount,
        addon_order_items (
          id,
          created_at,
          add_on_id,
          item_name,
          price,
          quantity,
          subtotal,
          add_ons (
            id,
            name,
            category,
            size,
            image_url
          )
        )
      ''')
          .eq('booking_code', code);

      for (final raw in (addonOrdersRes as List<dynamic>)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final items = (map['addon_order_items'] as List<dynamic>? ?? []);

        for (final itemRaw in items) {
          final item = Map<String, dynamic>.from(itemRaw as Map);
          final addOnsRaw = item['add_ons'];
          Map<String, dynamic>? addOns;

          if (addOnsRaw is List && addOnsRaw.isNotEmpty) {
            addOns = Map<String, dynamic>.from(addOnsRaw.first as Map);
          } else if (addOnsRaw is Map) {
            addOns = Map<String, dynamic>.from(addOnsRaw);
          }

          final qty = toIntSafe(item['quantity']);
          final price = toDoubleSafe(item['price']);
          final subtotal = toDoubleSafe(item['subtotal']) > 0
              ? toDoubleSafe(item['subtotal'])
              : qty * price;

          orderLines.add({
            'source': 'addon',
            'name': (item['item_name']?.toString().trim().isNotEmpty ?? false)
                ? item['item_name'].toString()
                : (addOns?['name']?.toString() ?? 'Add-On'),
            'qty': qty,
            'price': price,
            'subtotal': subtotal,
          });
        }

        orderDisplayTotal += toDoubleSafe(map['total_amount']);
      }
    } catch (_) {}

    try {
      final consignmentOrdersRes = await supabase
          .from('consignment_orders')
          .select('''
        id,
        booking_code,
        total_amount,
        consignment_order_items (
          id,
          created_at,
          consignment_id,
          item_name,
          price,
          quantity,
          subtotal,
          consignment (
            id,
            item_name,
            category,
            size,
            image_url
          )
        )
      ''')
          .eq('booking_code', code);

      for (final raw in (consignmentOrdersRes as List<dynamic>)) {
        final map = Map<String, dynamic>.from(raw as Map);
        final items = (map['consignment_order_items'] as List<dynamic>? ?? []);

        for (final itemRaw in items) {
          final item = Map<String, dynamic>.from(itemRaw as Map);
          final consignmentRaw = item['consignment'];
          Map<String, dynamic>? consignment;

          if (consignmentRaw is List && consignmentRaw.isNotEmpty) {
            consignment = Map<String, dynamic>.from(
              consignmentRaw.first as Map,
            );
          } else if (consignmentRaw is Map) {
            consignment = Map<String, dynamic>.from(consignmentRaw);
          }

          final qty = toIntSafe(item['quantity']);
          final price = toDoubleSafe(item['price']);
          final subtotal = toDoubleSafe(item['subtotal']) > 0
              ? toDoubleSafe(item['subtotal'])
              : qty * price;

          orderLines.add({
            'source': 'consignment',
            'name': (item['item_name']?.toString().trim().isNotEmpty ?? false)
                ? item['item_name'].toString()
                : (consignment?['item_name']?.toString() ?? 'Special Item'),
            'qty': qty,
            'price': price,
            'subtotal': subtotal,
          });
        }

        orderDisplayTotal += toDoubleSafe(map['total_amount']);
      }
    } catch (_) {}

    if (orderLines.isNotEmpty) {
      orderDisplayTotal = orderLines.fold<double>(
        0.0,
        (sum, line) => sum + toDoubleSafe(line['subtotal']),
      );
    }

    return {'orderLines': orderLines, 'orderDisplayTotal': orderDisplayTotal};
  }

  Future<void> showAttendanceReceiptIfNeeded({
    required AttendanceReceiptSource source,
    required Map<String, dynamic> row,
  }) async {
    final fullName = formatName(row['full_name']);
    final seatNumber = source == AttendanceReceiptSource.promo
        ? ((row['seat_number'] ?? '').toString().trim().isEmpty
              ? 'CONFERENCE ROOM'
              : row['seat_number'].toString().trim())
        : ((row['seat_number'] ?? '').toString().trim().isEmpty
              ? 'N/A'
              : row['seat_number'].toString().trim());

    final code = source == AttendanceReceiptSource.promo
        ? (row['promo_code'] ?? '').toString().trim().toUpperCase()
        : (row['booking_code'] ?? '').toString().trim().toUpperCase();

    final bundle = await loadAttendanceReceiptBundle(code);
    final orderLines = List<Map<String, dynamic>>.from(
      bundle['orderLines'] ?? [],
    );
    final orderPaymentRow = await loadCustomerOrderPaymentRow(code);

    final double orderDisplayTotal = toDoubleSafe(bundle['orderDisplayTotal']);
    final double orderTotalFromPayment = toDoubleSafe(
      orderPaymentRow?['order_total'],
    );
    final double orderTotal = math
        .max(orderDisplayTotal, orderTotalFromPayment)
        .toDouble();

    final double orderGcashPaid = toDoubleSafe(
      orderPaymentRow?['gcash_amount'],
    );
    final double orderCashPaid = toDoubleSafe(orderPaymentRow?['cash_amount']);
    final double orderPaidTotal = orderGcashPaid + orderCashPaid;
    final double orderRemaining = math
        .max(0.0, orderTotal - orderPaidTotal)
        .toDouble();

    double systemBase = 0;
    double systemGcash = 0;
    double systemCash = 0;
    double systemPaidTotal = 0;
    double systemRemaining = 0;
    String paidAtText = '—';

    if (source == AttendanceReceiptSource.promo) {
      final rawPrice = toDoubleSafe(row['price']);
      final discountKind = (row['discount_kind'] ?? 'none')
          .toString()
          .trim()
          .toLowerCase();
      final discountValue = toDoubleSafe(row['discount_value']);

      systemBase = applyDiscountValue(
        base: rawPrice,
        kind: discountKind,
        value: discountValue,
      );
      systemGcash = toDoubleSafe(row['gcash_amount']);
      systemCash = toDoubleSafe(row['cash_amount']);
      systemPaidTotal = systemGcash + systemCash;
      systemRemaining = math.max(0.0, systemBase - systemPaidTotal).toDouble();
      paidAtText = formatDateTimeLocal(row['paid_at']);
    } else {
      systemBase = toDoubleSafe(row['total_amount']);
      systemGcash = toDoubleSafe(row['gcash_amount']);
      systemCash = toDoubleSafe(row['cash_amount']);
      systemPaidTotal = systemGcash + systemCash;
      systemRemaining = math.max(0.0, systemBase - systemPaidTotal).toDouble();
      paidAtText = formatDateTimeLocal(row['paid_at']);
    }

    final bool hasOrders = orderTotal > 0.0 || orderLines.isNotEmpty;
    final bool systemFullyPaid = systemRemaining <= 0;
    final bool ordersFullyPaid = !hasOrders ? false : orderRemaining <= 0;
    final bool fullyPaid = systemFullyPaid && (!hasOrders || ordersFullyPaid);

    if (fullyPaid) return;

    final int addonCount = orderLines
        .where((e) => (e['source'] ?? '') == 'addon')
        .length;
    final int specialItemCount = orderLines
        .where((e) => (e['source'] ?? '') == 'consignment')
        .length;

    final String receiptLoadedMessage =
        'Receipt loaded successfully ✅\n\n'
        'System total: ${peso2(systemBase)}\n'
        'Orders total: ${peso2(orderTotal)}\n'
        'Add-Ons found: $addonCount\n'
        'Special Item found: $specialItemCount\n'
        'Remaining system: ${peso2(systemRemaining)}\n'
        'Remaining orders: ${peso2(orderRemaining)}';

    addAI(receiptLoadedMessage);

    final String infoMessage =
        '${source == AttendanceReceiptSource.promo ? "Promo Code" : "Booking Code"}: $code\n'
        'Customer: $fullName\n'
        'Seat: $seatNumber\n'
        'System payment: ${systemFullyPaid ? "PAID" : "UNPAID"}\n'
        'Order payment: ${hasOrders ? (ordersFullyPaid ? "PAID" : "UNPAID") : "NO ORDER"}\n'
        'Paid at: $paidAtText';

    addAI(infoMessage);

    if (hasOrders && systemFullyPaid && !ordersFullyPaid) {
      addAI(
        'Order payment successful ✅\n\n'
        'Promo / Reservation is already paid.\n'
        'Remaining order payment: ${peso2(orderRemaining)}\n\n'
        'Thank you! 😊',
      );
      return;
    }

    if (!hasOrders && !systemFullyPaid) {
      addAI(
        'System payment pending.\n\n'
        'Remaining system payment: ${peso2(systemRemaining)}\n\n'
        'Thank you! 😊',
      );
      return;
    }

    if (hasOrders && !systemFullyPaid && ordersFullyPaid) {
      addAI(
        'Order payment is already fully paid ✅\n\n'
        'But your promo / reservation payment is not yet fully paid.\n'
        'Remaining system payment: ${peso2(systemRemaining)}\n\n'
        'Thank you! 😊',
      );
      return;
    }

    if (hasOrders && !systemFullyPaid && !ordersFullyPaid) {
      addAI(
        'Payment saved successfully ✅\n\n'
        'Remaining system payment: ${peso2(systemRemaining)}\n'
        'Remaining order payment: ${peso2(orderRemaining)}\n\n'
        'Thank you! 😊',
      );
      return;
    }
  }

  String formatName(dynamic value) {
    final v = (value ?? '').toString().trim();
    return v.isEmpty ? 'Customer' : v;
  }

  Future<void> openReceiptAfterOut(String code) async {
    final normalized = code.trim().toUpperCase();
    if (normalized.isEmpty) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.92,
          height: MediaQuery.of(context).size.height * 0.92,
          child: ViewReceipt(initialCode: normalized, autoLoadOnOpen: true),
        ),
      ),
    );
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

    setState(() {
      hasSubmittedOnce = true;
    });

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

    final refreshedSession = await supabase
        .from('customer_sessions')
        .select('''
      id,
      full_name,
      booking_code,
      seat_number,
      total_amount,
      gcash_amount,
      cash_amount,
      is_paid,
      paid_at,
      reservation,
      reservation_date,
      reservation_end_date,
      hour_avail,
      time_started,
      time_ended,
      expected_end_at,
      total_time
    ''')
        .eq('id', sessionId)
        .limit(1)
        .single();

    await openReceiptAfterOut(
      (refreshedSession['booking_code'] ?? '').toString(),
    );
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

    final refreshedPromo = await supabase
        .from('promo_bookings')
        .select('''
      id,
      full_name,
      promo_code,
      seat_number,
      price,
      gcash_amount,
      cash_amount,
      is_paid,
      paid_at,
      discount_kind,
      discount_value,
      discount_reason,
      start_at,
      end_at,
      validity_end_at
    ''')
        .eq('id', promoId)
        .limit(1)
        .single();

    await openReceiptAfterOut((refreshedPromo['promo_code'] ?? '').toString());
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

  Widget buildTopIntroArea(bool isMobile) {
    if (messages.isEmpty) return const SizedBox.shrink();

    final introMessages = hasSubmittedOnce ? [messages.first] : messages;

    return Column(
      children: [
        ...introMessages.map((e) => bubble(e, isMobile)),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget buildResponseArea(bool isMobile) {
    if (!hasSubmittedOnce || messages.length <= 1) {
      return const SizedBox.shrink();
    }

    final responseMessages = messages.skip(1).toList();

    return Column(
      children: [
        const SizedBox(height: 16),
        ...responseMessages.map((e) => bubble(e, isMobile)),
      ],
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
        ? 500
        : 600;

    final double modalHeight = isMobile
        ? screen.height * 0.92
        : isTablet
        ? 500
        : 620;

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
                            buildTopIntroArea(isMobile),

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

                            buildResponseArea(isMobile),
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
