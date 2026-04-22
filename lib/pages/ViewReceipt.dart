import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../styles/Attendance_styles.dart';
import '../styles/ViewReceipt_styles.dart';
import 'ViewReceipt.dart';

class ViewReceipt extends StatefulWidget {
  final String? initialCode;
  final bool autoLoadOnOpen;

  const ViewReceipt({super.key, this.initialCode, this.autoLoadOnOpen = false});

  @override
  State<ViewReceipt> createState() => _ViewReceiptState();
}

class ViewReceiptPage extends StatelessWidget {
  const ViewReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ViewReceipt();
  }
}

class _ViewReceiptState extends State<ViewReceipt>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  static const double _hourlyRate = 20.0;
  static const int _freeMinutes = 0;

  final TextEditingController _codeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _isSearching = false;
  bool _isSavingSystem = false;
  bool _isSavingOrders = false;

  final List<_ChatMessage> _chatMessages = [];

  ReceiptData? _receipt;
  List<OrderRow> _addOnRows = [];
  List<OrderRow> _consignmentRows = [];
  List<OrderLine> _orderLines = [];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _chatMessages.addAll(const [
      _ChatMessage.user('You selected View Receipt 🧾'),
      _ChatMessage.ai(
        'Please paste your booking code or promo code below to view your receipt.',
      ),
    ]);

    if ((widget.initialCode ?? '').trim().isNotEmpty) {
      _codeController.text = widget.initialCode!.trim().toUpperCase();
    }

    _animController.forward();
    _scrollToBottom();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.autoLoadOnOpen &&
          (widget.initialCode ?? '').trim().isNotEmpty) {
        _loadReceipt();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _addAiMessage(String text) {
    if (!mounted) return;
    setState(() {
      _chatMessages.add(_ChatMessage.ai(text));
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (!mounted) return;
    setState(() {
      _chatMessages.add(_ChatMessage.user(text));
    });
    _scrollToBottom();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _toText(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  String _peso(double value) => '₱${value.toStringAsFixed(0)}';
  String _peso2(double value) => '₱${value.toStringAsFixed(2)}';

  String _formatDateTime(dynamic iso) {
    if (iso == null) return '—';
    final parsed = DateTime.tryParse(iso.toString());
    if (parsed == null) return '—';

    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';

    return '${local.month}/${local.day}/${local.year}, $hour:$minute $ampm';
  }

  String _formatDateOnly(dynamic iso) {
    if (iso == null) return '—';
    final parsed = DateTime.tryParse(iso.toString());
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    return '${_monthShort(local.month)} ${local.day}, ${local.year}';
  }

  String _monthShort(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return months[month];
  }

  int _minutesBetween(DateTime start, DateTime end) {
    final diff = end.difference(start).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  double _computeOpenSessionAmount(int minutes) {
    final billableMinutes = math.max(0, minutes - _freeMinutes);
    if (billableMinutes <= 0) return 0;
    final raw = (billableMinutes / 60.0) * _hourlyRate;
    return raw.ceilToDouble();
  }

  bool _isOpenSession(Map<String, dynamic> row) {
    final hourAvail = _toText(row['hour_avail']).trim().toUpperCase();
    final timeEndedRaw = _toText(row['time_ended']).trim();

    if (hourAvail == 'CLOSED') return false;
    if (hourAvail == 'OPEN') return true;
    if (timeEndedRaw.isEmpty) return true;

    final parsedEnd = DateTime.tryParse(timeEndedRaw);
    if (parsedEnd == null) return true;

    return parsedEnd.year >= 2999;
  }

  Future<Map<String, dynamic>> _finalizeOpenSessionIfNeeded(
    Map<String, dynamic> row,
  ) async {
    if (!_isOpenSession(row)) return row;

    final sessionId = _toText(row['id']);
    final startedRaw = row['time_started'];

    if (sessionId.isEmpty || startedRaw == null) return row;

    final startedAt = DateTime.tryParse(startedRaw.toString())?.toLocal();
    if (startedAt == null) return row;

    final now = DateTime.now();
    final totalMinutes = _minutesBetween(startedAt, now);
    final totalAmount = _computeOpenSessionAmount(totalMinutes);

    await supabase
        .from('customer_sessions')
        .update({
          'time_ended': now.toIso8601String(),
          'total_time': totalMinutes,
          'total_amount': totalAmount,
          'hour_avail': 'CLOSED',
          'expected_end_at': null,
        })
        .eq('id', sessionId);

    final refreshed = await supabase
        .from('customer_sessions')
        .select()
        .eq('id', sessionId)
        .limit(1)
        .single();

    return Map<String, dynamic>.from(refreshed);
  }

  double _sumOrders(List<OrderRow> rows) {
    return rows.fold(0.0, (sum, row) => sum + row.total);
  }

  double _sumUnpaidOrders(List<OrderRow> rows) {
    return rows
        .where((row) => !row.isPaid)
        .fold(0.0, (sum, row) => sum + row.total);
  }

  double _sumOrderGcash(List<OrderRow> rows) {
    return rows.fold(0.0, (sum, row) => sum + row.gcashAmount);
  }

  double _sumOrderCash(List<OrderRow> rows) {
    return rows.fold(0.0, (sum, row) => sum + row.cashAmount);
  }

  ReceiptData _buildComposedReceipt(ReceiptLookupResult result) {
    final paymentRow = result.orderPaymentRow;
    final double finalOrderTotal = math.max(
      result.orderDisplayTotal,
      paymentRow?.orderTotal ?? 0,
    );

    return result.receipt.copyWith(
      orderTotal: finalOrderTotal,
      orderGcashPaid: paymentRow?.gcashAmount ?? 0,
      orderCashPaid: paymentRow?.cashAmount ?? 0,
    );
  }

  void _syncReceiptState(ReceiptLookupResult result) {
    final composed = _buildComposedReceipt(result);
    setState(() {
      _receipt = composed;
      _addOnRows = result.addOnRows;
      _consignmentRows = result.consignmentRows;
      _orderLines = result.orderLines;
    });
  }

  double _currentOrderRemainingFromRows(
    List<OrderRow> rows,
    ReceiptData? receipt,
  ) {
    if (receipt == null) return _sumUnpaidOrders(rows);

    return math.max(0, receipt.orderTotal - receipt.orderPaidTotal);
  }

  Future<CustomerOrderPaymentRow?> _getExistingOrderPaymentRow(
    String bookingCode,
  ) async {
    if (bookingCode.trim().isEmpty) return null;

    final existing = await supabase
        .from('customer_order_payments')
        .select('*')
        .eq('booking_code', bookingCode.trim().toUpperCase())
        .maybeSingle();

    if (existing == null) return null;
    return CustomerOrderPaymentRow.fromMap(Map<String, dynamic>.from(existing));
  }

  Future<void> _syncFinalSessionPaidStatus({
    required ReceiptData receipt,
    required double systemPaidTotal,
    required double orderPaidTotal,
    required double systemDue,
    required double orderDue,
  }) async {
    final bool systemPaid = receipt.discountedSystemTotal <= 0
        ? true
        : systemPaidTotal >= receipt.discountedSystemTotal;
    final bool orderPaid = orderDue <= 0 ? true : orderPaidTotal >= orderDue;
    final bool finalPaid = systemPaid && orderPaid;

    final payload = {
      'is_paid': finalPaid,
      'paid_at': finalPaid ? DateTime.now().toIso8601String() : null,
    };

    if (receipt.source == ReceiptSource.customerSession) {
      await supabase
          .from('customer_sessions')
          .update(payload)
          .eq('id', receipt.id);
    } else {
      await supabase
          .from('promo_bookings')
          .update(payload)
          .eq('id', receipt.id);
    }
  }

  void _appendPaymentFeedback({
    required ReceiptData receipt,
    required bool paidSystemNow,
    required bool paidOrderNow,
  }) {
    final double systemRemaining = math.max(0, receipt.systemBalance);
    final double orderRemaining = math.max(
      0,
      receipt.orderTotal - receipt.orderPaidTotal,
    );
    final double totalAmountDue = math.max(0, systemRemaining + orderRemaining);

    final bool fullyPaid = systemRemaining <= 0 && orderRemaining <= 0;

    final List<String> lines = [];

    if (paidOrderNow && !paidSystemNow) {
      if (fullyPaid) {
        lines.add('Order payment successful ✅');
        lines.add('');
        lines.add(
          'Discount: ${receipt.discountAmount > 0 ? _peso2(receipt.discountAmount) : "₱0.00"}',
        );
        if (receipt.source == ReceiptSource.customerSession) {
          lines.add('Time Consumed: ${receipt.timeConsumedText}');
        }
        lines.add('Total Amount Due: ${_peso2(totalAmountDue)}');
        lines.add('');
        lines.add('Your receipt is now fully paid.');
        lines.add('');
        lines.add('Thank you! 😊');
      } else {
        lines.add('Order payment successful ✅');
        lines.add('');
        lines.add(
          'Discount: ${receipt.discountAmount > 0 ? _peso2(receipt.discountAmount) : "₱0.00"}',
        );
        if (orderRemaining > 0) {
          lines.add('Remaining order payment: ${_peso2(orderRemaining)}');
        } else {
          lines.add('Order payment is fully paid.');
        }
        if (systemRemaining > 0) {
          lines.add('Remaining system payment: ${_peso2(systemRemaining)}');
        }
        lines.add('Total Amount Due: ${_peso2(totalAmountDue)}');
        lines.add('');
        lines.add('Thank you! 😊');
      }
    } else if (paidSystemNow && !paidOrderNow) {
      if (fullyPaid) {
        lines.add('System payment successful ✅');
        lines.add('');
        lines.add(
          'Discount: ${receipt.discountAmount > 0 ? _peso2(receipt.discountAmount) : "₱0.00"}',
        );
        lines.add('Total Amount Due: ${_peso2(totalAmountDue)}');
        lines.add('');
        lines.add('Your receipt is now fully paid.');
        lines.add('');
        lines.add('Thank you! 😊');
      } else {
        lines.add('System payment successful ✅');
        lines.add('');
        lines.add(
          'Discount: ${receipt.discountAmount > 0 ? _peso2(receipt.discountAmount) : "₱0.00"}',
        );
        if (systemRemaining > 0) {
          lines.add('Remaining system payment: ${_peso2(systemRemaining)}');
        } else {
          lines.add('System payment is fully paid.');
        }
        if (orderRemaining > 0) {
          lines.add('Remaining order payment: ${_peso2(orderRemaining)}');
        }
        lines.add('Total Amount Due: ${_peso2(totalAmountDue)}');
        lines.add('');
        lines.add('Thank you! 😊');
      }
    } else if (paidSystemNow && paidOrderNow) {
      if (fullyPaid) {
        lines.add('Payment successful ✅');
        lines.add('');
        lines.add(
          'Discount: ${receipt.discountAmount > 0 ? _peso2(receipt.discountAmount) : "₱0.00"}',
        );
        lines.add('Total Amount Due: ${_peso2(totalAmountDue)}');
        lines.add('');
        lines.add('Your receipt is now fully paid.');
        lines.add('');
        lines.add('Thank you! 😊');
      } else {
        lines.add('Payment successful ✅');
        lines.add('');
        lines.add(
          'Discount: ${receipt.discountAmount > 0 ? _peso2(receipt.discountAmount) : "₱0.00"}',
        );
        if (systemRemaining > 0) {
          lines.add('Remaining system payment: ${_peso2(systemRemaining)}');
        }
        if (orderRemaining > 0) {
          lines.add('Remaining order payment: ${_peso2(orderRemaining)}');
        }
        lines.add('Total Amount Due: ${_peso2(totalAmountDue)}');
        lines.add('');
        lines.add('Thank you! 😊');
      }
    } else {
      lines.add('Payment saved successfully ✅');
      lines.add('');
      lines.add(
        'Discount: ${receipt.discountAmount > 0 ? _peso2(receipt.discountAmount) : "₱0.00"}',
      );
      if (systemRemaining > 0) {
        lines.add('Remaining system payment: ${_peso2(systemRemaining)}');
      }
      if (orderRemaining > 0) {
        lines.add('Remaining order payment: ${_peso2(orderRemaining)}');
      }
      lines.add('Total Amount Due: ${_peso2(totalAmountDue)}');
      lines.add('');
      lines.add('Thank you! 😊');
    }

    _addAiMessage(lines.join('\n'));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 220,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadReceipt() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || _isSearching) return;

    _addUserMessage(code);

    setState(() {
      _isSearching = true;
      _receipt = null;
      _addOnRows = [];
      _consignmentRows = [];
      _orderLines = [];
    });

    try {
      final result = await _findReceiptByCode(code);

      if (result == null) {
        _addAiMessage(
          'No receipt found for that code.\n\nPlease check your booking code or promo code and try again.',
        );
        return;
      }

      _syncReceiptState(result);

      final composed = _buildComposedReceipt(result);

      final double orderRemainingValue = math.max(
        0.0,
        composed.orderTotal - composed.orderPaidTotal,
      );

      final double totalAmountDue =
          math.max(0.0, composed.systemBalance) +
          math.max(0.0, orderRemainingValue);

      final int addonCount = result.orderLines
          .where((e) => e.source == OrderSource.addon)
          .length;

      final int specialItemCount = result.orderLines
          .where((e) => e.source == OrderSource.consignment)
          .length;

      final String receiptLoadedMessage =
          'Receipt loaded successfully ✅\n\n'
          '${composed.source == ReceiptSource.customerSession ? 'Time Consumed: ${composed.timeConsumedText}\n' : ''}'
          'System total: ${_peso2(composed.systemTotal)}\n'
          'Discount: ${composed.discountAmount > 0 ? _peso2(composed.discountAmount) : "₱0.00"}\n'
          'Orders total: ${_peso2(composed.orderTotal)}\n'
          'Add-Ons found: $addonCount\n'
          'Special Item found: $specialItemCount\n'
          'Remaining system: ${_peso2(composed.systemBalance)}\n'
          'Remaining orders: ${_peso2(orderRemainingValue)}\n'
          'Total Amount Due: ${_peso2(totalAmountDue)}';

      _addAiMessage(receiptLoadedMessage);
    } catch (e) {
      _addAiMessage('Failed to load receipt.\n\nPlease try again.');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load receipt: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  Future<ReceiptLookupResult?> _findReceiptByCode(String code) async {
    final promo = await supabase
        .from('promo_bookings')
        .select()
        .eq('promo_code', code)
        .limit(1)
        .maybeSingle();

    if (promo != null) {
      final receipt = ReceiptData.fromPromoBooking(
        Map<String, dynamic>.from(promo),
      );
      final bundle = await _loadOrderBundleForReceipt(receipt);
      final orderPaymentRow = await _getExistingOrderPaymentRow(receipt.code);

      return ReceiptLookupResult(
        receipt: receipt,
        addOnRows: bundle.addOnRows,
        consignmentRows: bundle.consignmentRows,
        orderLines: bundle.orderLines,
        orderDisplayTotal: bundle.orderDisplayTotal,
        orderPaymentRow: orderPaymentRow,
      );
    }

    final walkIn = await supabase
        .from('customer_sessions')
        .select()
        .eq('booking_code', code)
        .limit(1)
        .maybeSingle();

    if (walkIn != null) {
      final finalizedWalkIn = await _finalizeOpenSessionIfNeeded(
        Map<String, dynamic>.from(walkIn),
      );

      final receipt = ReceiptData.fromCustomerSession(finalizedWalkIn);
      final bundle = await _loadOrderBundleForReceipt(receipt);
      final orderPaymentRow = await _getExistingOrderPaymentRow(receipt.code);

      return ReceiptLookupResult(
        receipt: receipt,
        addOnRows: bundle.addOnRows,
        consignmentRows: bundle.consignmentRows,
        orderLines: bundle.orderLines,
        orderDisplayTotal: bundle.orderDisplayTotal,
        orderPaymentRow: orderPaymentRow,
      );
    }

    return null;
  }

  Future<_OrderBundleForReceipt> _loadOrderBundleForReceipt(
    ReceiptData receipt,
  ) async {
    final bookingCode = receipt.code.trim().toUpperCase();
    final List<OrderLine> orderLines = [];
    final List<OrderRow> addOnRows = [];
    final List<OrderRow> consignmentRows = [];

    double orderDisplayTotal = 0;

    if (bookingCode.isNotEmpty) {
      try {
        final addonOrdersRes = await supabase
            .from('addon_orders')
            .select('''
            id,
            booking_code,
            full_name,
            seat_number,
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
            .eq('booking_code', bookingCode);

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

            final qty = _toInt(item['quantity']);
            final price = _toDouble(item['price']);
            final subtotal = _toDouble(item['subtotal']) > 0
                ? _toDouble(item['subtotal'])
                : qty * price;

            orderLines.add(
              OrderLine(
                source: OrderSource.addon,
                name: _toText(item['item_name']).isNotEmpty
                    ? _toText(item['item_name'])
                    : _toText(addOns?['name']),
                qty: qty,
                price: price,
                subtotal: subtotal,
                category: _toText(addOns?['category']),
                size: _toText(addOns?['size']).isEmpty
                    ? null
                    : _toText(addOns?['size']),
                imageUrl: _toText(addOns?['image_url']).isEmpty
                    ? null
                    : _toText(addOns?['image_url']),
              ),
            );
          }

          orderDisplayTotal += _toDouble(map['total_amount']);
        }
      } catch (_) {}

      try {
        final consignmentOrdersRes = await supabase
            .from('consignment_orders')
            .select('''
            id,
            booking_code,
            full_name,
            seat_number,
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
            .eq('booking_code', bookingCode);

        for (final raw in (consignmentOrdersRes as List<dynamic>)) {
          final map = Map<String, dynamic>.from(raw as Map);
          final items =
              (map['consignment_order_items'] as List<dynamic>? ?? []);

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

            final qty = _toInt(item['quantity']);
            final price = _toDouble(item['price']);
            final subtotal = _toDouble(item['subtotal']) > 0
                ? _toDouble(item['subtotal'])
                : qty * price;

            orderLines.add(
              OrderLine(
                source: OrderSource.consignment,
                name: _toText(item['item_name']).isNotEmpty
                    ? _toText(item['item_name'])
                    : _toText(consignment?['item_name']),
                qty: qty,
                price: price,
                subtotal: subtotal,
                category: _toText(consignment?['category']),
                size: _toText(consignment?['size']).isEmpty
                    ? null
                    : _toText(consignment?['size']),
                imageUrl: _toText(consignment?['image_url']).isEmpty
                    ? null
                    : _toText(consignment?['image_url']),
              ),
            );
          }

          orderDisplayTotal += _toDouble(map['total_amount']);
        }
      } catch (_) {}

      // fallback + merge para siguradong lahat ng consignment lines makita
      try {
        final fallbackConsignment = await supabase
            .from('customer_session_consignment')
            .select('''
      id,
      quantity,
      price,
      total,
      consignment_id,
      consignment (
        id,
        item_name,
        category,
        size,
        image_url
      )
    ''')
            .eq('full_name', receipt.fullName)
            .eq('seat_number', receipt.seatNumber)
            .eq('voided', false);

        for (final raw in (fallbackConsignment as List<dynamic>)) {
          final map = Map<String, dynamic>.from(raw as Map);
          final consignmentRaw = map['consignment'];
          Map<String, dynamic>? consignment;

          if (consignmentRaw is List && consignmentRaw.isNotEmpty) {
            consignment = Map<String, dynamic>.from(
              consignmentRaw.first as Map,
            );
          } else if (consignmentRaw is Map) {
            consignment = Map<String, dynamic>.from(consignmentRaw);
          }

          final qty = _toInt(map['quantity']);
          final price = _toDouble(map['price']);
          final subtotal = _toDouble(map['total']) > 0
              ? _toDouble(map['total'])
              : qty * price;

          final itemName = _toText(consignment?['item_name']).isNotEmpty
              ? _toText(consignment?['item_name'])
              : 'Consignment Item';

          final alreadyExists = orderLines.any(
            (e) =>
                e.source == OrderSource.consignment &&
                e.name.trim().toLowerCase() == itemName.trim().toLowerCase() &&
                e.qty == qty &&
                e.price == price &&
                e.subtotal == subtotal,
          );

          if (alreadyExists) continue;

          orderLines.add(
            OrderLine(
              source: OrderSource.consignment,
              name: itemName,
              qty: qty,
              price: price,
              subtotal: subtotal,
              category: _toText(consignment?['category']),
              size: _toText(consignment?['size']).isEmpty
                  ? null
                  : _toText(consignment?['size']),
              imageUrl: _toText(consignment?['image_url']).isEmpty
                  ? null
                  : _toText(consignment?['image_url']),
            ),
          );
        }
      } catch (_) {}

      // fallback + merge para siguradong lahat ng add-on lines makita
      try {
        final fallbackAddons = await supabase
            .from('customer_session_add_ons')
            .select('''
      id,
      quantity,
      price,
      total,
      add_on_id,
      add_ons (
        id,
        name,
        category,
        size,
        image_url
      )
    ''')
            .eq('full_name', receipt.fullName)
            .eq('seat_number', receipt.seatNumber)
            .eq('voided', false);

        for (final raw in (fallbackAddons as List<dynamic>)) {
          final map = Map<String, dynamic>.from(raw as Map);
          final addOnsRaw = map['add_ons'];
          Map<String, dynamic>? addOns;

          if (addOnsRaw is List && addOnsRaw.isNotEmpty) {
            addOns = Map<String, dynamic>.from(addOnsRaw.first as Map);
          } else if (addOnsRaw is Map) {
            addOns = Map<String, dynamic>.from(addOnsRaw);
          }

          final qty = _toInt(map['quantity']);
          final price = _toDouble(map['price']);
          final subtotal = _toDouble(map['total']) > 0
              ? _toDouble(map['total'])
              : qty * price;

          final itemName = _toText(addOns?['name']).isNotEmpty
              ? _toText(addOns?['name'])
              : 'Add-On';

          final alreadyExists = orderLines.any(
            (e) =>
                e.source == OrderSource.addon &&
                e.name.trim().toLowerCase() == itemName.trim().toLowerCase() &&
                e.qty == qty &&
                e.price == price &&
                e.subtotal == subtotal,
          );

          if (alreadyExists) continue;

          orderLines.add(
            OrderLine(
              source: OrderSource.addon,
              name: itemName,
              qty: qty,
              price: price,
              subtotal: subtotal,
              category: _toText(addOns?['category']),
              size: _toText(addOns?['size']).isEmpty
                  ? null
                  : _toText(addOns?['size']),
              imageUrl: _toText(addOns?['image_url']).isEmpty
                  ? null
                  : _toText(addOns?['image_url']),
            ),
          );
        }
      } catch (_) {}
    }

    try {
      var addOnQuery = supabase
          .from('customer_session_add_ons')
          .select(
            'id,total,is_paid,voided,paid_at,gcash_amount,cash_amount,full_name,seat_number',
          );

      if (receipt.fullName.isNotEmpty) {
        addOnQuery = addOnQuery.eq('full_name', receipt.fullName);
      }
      if (receipt.seatNumber.isNotEmpty) {
        addOnQuery = addOnQuery.eq('seat_number', receipt.seatNumber);
      }

      final addOnRes = await addOnQuery;
      for (final row in addOnRes) {
        final map = Map<String, dynamic>.from(row);
        if (map['voided'] == true) continue;
        addOnRows.add(OrderRow.fromMap(map, table: 'customer_session_add_ons'));
      }
    } catch (_) {}

    try {
      var consignmentQuery = supabase
          .from('customer_session_consignment')
          .select(
            'id,total,is_paid,voided,paid_at,gcash_amount,cash_amount,full_name,seat_number',
          );

      if (receipt.fullName.isNotEmpty) {
        consignmentQuery = consignmentQuery.eq('full_name', receipt.fullName);
      }
      if (receipt.seatNumber.isNotEmpty) {
        consignmentQuery = consignmentQuery.eq(
          'seat_number',
          receipt.seatNumber,
        );
      }

      final consignmentRes = await consignmentQuery;
      for (final row in consignmentRes) {
        final map = Map<String, dynamic>.from(row);
        if (map['voided'] == true) continue;
        consignmentRows.add(
          OrderRow.fromMap(map, table: 'customer_session_consignment'),
        );
      }
    } catch (_) {}

    // same total behavior as customer list: display sum of visible order lines if available
    if (orderLines.isNotEmpty) {
      orderDisplayTotal = orderLines.fold(
        0.0,
        (sum, line) => sum + line.subtotal,
      );
    }

    return _OrderBundleForReceipt(
      addOnRows: addOnRows,
      consignmentRows: consignmentRows,
      orderLines: orderLines,
      orderDisplayTotal: orderDisplayTotal,
    );
  }

  Future<void> _showPaymentModal() async {
    if (_receipt == null) return;

    final receipt = _receipt!;
    final unpaidOrderRows = [
      ..._addOnRows,
      ..._consignmentRows,
    ].where((e) => !e.isPaid).toList();

    final existingOrderPayment = await _getExistingOrderPaymentRow(
      receipt.code,
    );
    final double computedOrderTotal = _orderLines.fold(
      0.0,
      (sum, line) => sum + line.subtotal,
    );
    final double storedOrderTotal = existingOrderPayment?.orderTotal ?? 0;

    final double effectiveOrderTotal = math.max(
      computedOrderTotal,
      storedOrderTotal,
    );

    final double existingOrderPaid = existingOrderPayment?.totalPaid ?? 0;

    final double systemDue = receipt.systemBalance;
    final double orderDue = math.max(
      0,
      effectiveOrderTotal - existingOrderPaid,
    );

    final systemGcashController = TextEditingController(text: '0');
    final systemCashController = TextEditingController(text: '0');
    final orderGcashController = TextEditingController(text: '0');
    final orderCashController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      barrierDismissible: !_isSavingSystem && !_isSavingOrders,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> saveSystemPayment() async {
              final double gcash = _toDouble(systemGcashController.text);
              final double cash = _toDouble(systemCashController.text);
              final double total = gcash + cash;

              if (systemDue <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('System payment is already paid.'),
                  ),
                );
                return;
              }

              if (total <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter system payment amount.')),
                );
                return;
              }

              setModalState(() => _isSavingSystem = true);

              try {
                await _saveSystemPayment(
                  receipt: receipt,
                  addGcash: gcash,
                  addCash: cash,
                );

                final refreshed = await _findReceiptByCode(receipt.code);
                if (refreshed != null && mounted) {
                  _syncReceiptState(refreshed);
                  final composed = _buildComposedReceipt(refreshed);
                  await _syncFinalSessionPaidStatus(
                    receipt: composed,
                    systemPaidTotal: composed.systemPaidTotal,
                    orderPaidTotal: composed.orderPaidTotal,
                    systemDue: composed.discountedSystemTotal,
                    orderDue: composed.orderTotal,
                  );

                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }

                  _appendPaymentFeedback(
                    receipt: composed,
                    paidSystemNow: true,
                    paidOrderNow: false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save system payment: $e'),
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isSavingSystem = false);
                }
              }
            }

            Future<void> saveOrderPayment() async {
              final double gcash = _toDouble(orderGcashController.text);
              final double cash = _toDouble(orderCashController.text);
              final double total = gcash + cash;

              if (orderDue <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No unpaid order payment found.'),
                  ),
                );
                return;
              }

              if (total <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter order payment amount.')),
                );
                return;
              }

              setModalState(() => _isSavingOrders = true);

              try {
                await _saveOrderPayment(
                  orderRows: unpaidOrderRows,
                  addGcash: gcash,
                  addCash: cash,
                );

                final refreshed = await _findReceiptByCode(receipt.code);
                if (refreshed != null && mounted) {
                  _syncReceiptState(refreshed);
                  final composed = _buildComposedReceipt(refreshed);
                  await _syncFinalSessionPaidStatus(
                    receipt: composed,
                    systemPaidTotal: composed.systemPaidTotal,
                    orderPaidTotal: composed.orderPaidTotal,
                    systemDue: composed.systemTotal,
                    orderDue: composed.orderTotal,
                  );

                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }

                  _appendPaymentFeedback(
                    receipt: composed,
                    paidSystemNow: false,
                    paidOrderNow: true,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save order payment: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isSavingOrders = false);
                }
              }
            }

            Future<void> saveAllPayments() async {
              final double systemGcash = _toDouble(systemGcashController.text);
              final double systemCash = _toDouble(systemCashController.text);
              final double orderGcash = _toDouble(orderGcashController.text);
              final double orderCash = _toDouble(orderCashController.text);

              final double totalSystemInput = systemGcash + systemCash;
              final double totalOrderInput = orderGcash + orderCash;

              if (systemDue > 0 && totalSystemInput <= 0 && orderDue <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter payment amount.')),
                );
                return;
              }

              if (orderDue > 0 && totalOrderInput <= 0 && systemDue <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter payment amount.')),
                );
                return;
              }

              if (totalSystemInput <= 0 && totalOrderInput <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter payment amount.')),
                );
                return;
              }

              setModalState(() {
                _isSavingSystem = true;
                _isSavingOrders = true;
              });

              try {
                if (systemDue > 0 && totalSystemInput > 0) {
                  await _saveSystemPayment(
                    receipt: receipt,
                    addGcash: systemGcash,
                    addCash: systemCash,
                  );
                }

                if (orderDue > 0 && totalOrderInput > 0) {
                  await _saveOrderPayment(
                    orderRows: unpaidOrderRows,
                    addGcash: orderGcash,
                    addCash: orderCash,
                  );
                }

                final refreshed = await _findReceiptByCode(receipt.code);
                if (refreshed != null && mounted) {
                  _syncReceiptState(refreshed);
                  final composed = _buildComposedReceipt(refreshed);
                  await _syncFinalSessionPaidStatus(
                    receipt: composed,
                    systemPaidTotal: composed.systemPaidTotal,
                    orderPaidTotal: composed.orderPaidTotal,
                    systemDue: composed.systemTotal,
                    orderDue: composed.orderTotal,
                  );

                  if (Navigator.of(dialogContext).canPop()) {
                    Navigator.of(dialogContext).pop();
                  }

                  _appendPaymentFeedback(
                    receipt: composed,
                    paidSystemNow: totalSystemInput > 0,
                    paidOrderNow: totalOrderInput > 0,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save payment: $e')),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isSavingSystem = false;
                    _isSavingOrders = false;
                  });
                }
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(22),
                  decoration: ViewReceiptStyles.paymentDialog,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _paymentSection(
                          title: 'System Payment',
                          dueText: systemDue > 0
                              ? 'Balance: ${_peso2(systemDue)}'
                              : 'Already Paid',
                          gcashController: systemGcashController,
                          cashController: systemCashController,
                          onSave: null,
                          isSaving: false,
                        ),
                        if (orderDue > 0) ...[
                          const SizedBox(height: 18),
                          _paymentSection(
                            title: 'Order Payment',
                            dueText: 'Balance: ${_peso2(orderDue)}',
                            gcashController: orderGcashController,
                            cashController: orderCashController,
                            onSave: null,
                            isSaving: false,
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (_isSavingSystem || _isSavingOrders)
                                ? null
                                : saveAllPayments,
                            style: ViewReceiptStyles.saveButtonStyle,
                            child: (_isSavingSystem || _isSavingOrders)
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save',
                                    style: ViewReceiptStyles.saveButtonText,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: (_isSavingSystem || _isSavingOrders)
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text(
                              'Close',
                              style: ViewReceiptStyles.dialogCloseText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    systemGcashController.dispose();
    systemCashController.dispose();
    orderGcashController.dispose();
    orderCashController.dispose();
  }

  Widget _paymentSection({
    required String title,
    required String dueText,
    required TextEditingController gcashController,
    required TextEditingController cashController,
    required VoidCallback? onSave,
    required bool isSaving,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ViewReceiptStyles.paymentSectionBox,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: ViewReceiptStyles.paymentTitle),
          const SizedBox(height: 4),
          Text(dueText, style: ViewReceiptStyles.paymentDueText),
          const SizedBox(height: 14),
          const Text('GCASH', style: ViewReceiptStyles.paymentLabel),
          const SizedBox(height: 8),
          _paymentField(gcashController),
          const SizedBox(height: 14),
          const Text('CASH', style: ViewReceiptStyles.paymentLabel),
          const SizedBox(height: 8),
          _paymentField(cashController),
          if (onSave != null) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: onSave,
                  style: ViewReceiptStyles.saveButtonStyle,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Save',
                          style: ViewReceiptStyles.saveButtonText,
                        ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _paymentField(TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: ViewReceiptStyles.paymentInputDecoration('0'),
    );
  }

  Future<void> _saveSystemPayment({
    required ReceiptData receipt,
    required double addGcash,
    required double addCash,
  }) async {
    final double newGcash = receipt.systemGcash + addGcash;
    final double newCash = receipt.systemCash + addCash;
    final double newSystemPaid = newGcash + newCash;

    final existingOrder = await _getExistingOrderPaymentRow(receipt.code);
    final double orderPaidTotal =
        existingOrder?.totalPaid ?? receipt.orderPaidTotal;
    final double orderDue = existingOrder?.orderTotal ?? receipt.orderTotal;

    final bool systemPaid = receipt.discountedSystemTotal <= 0
        ? true
        : newSystemPaid >= receipt.discountedSystemTotal;
    final bool orderPaid = orderDue <= 0 ? true : orderPaidTotal >= orderDue;
    final bool finalPaid = systemPaid && orderPaid;

    final payload = {
      'gcash_amount': newGcash,
      'cash_amount': newCash,
      'is_paid': finalPaid,
      'paid_at': finalPaid ? DateTime.now().toIso8601String() : null,
    };

    if (receipt.source == ReceiptSource.customerSession) {
      await supabase
          .from('customer_sessions')
          .update(payload)
          .eq('id', receipt.id);
    } else {
      await supabase
          .from('promo_bookings')
          .update(payload)
          .eq('id', receipt.id);
    }
  }

  Future<void> _saveOrderPayment({
    required List<OrderRow> orderRows,
    required double addGcash,
    required double addCash,
  }) async {
    final String bookingCode = (_receipt?.code ?? '').trim().toUpperCase();
    final String fullName = (_receipt?.fullName ?? '').trim();
    final String seatNumber = (_receipt?.seatNumber ?? '').trim();

    if (bookingCode.isEmpty) {
      throw Exception('Missing booking code for order payment.');
    }

    final existingPayment = await _getExistingOrderPaymentRow(bookingCode);

    final double currentOrdersTotal = _orderLines.fold(
      0.0,
      (sum, line) => sum + line.subtotal,
    );

    final double storedOrderTotal = existingPayment?.orderTotal ?? 0;
    final double orderTotal = math.max(currentOrdersTotal, storedOrderTotal);

    final double newOrderGcash = (existingPayment?.gcashAmount ?? 0) + addGcash;
    final double newOrderCash = (existingPayment?.cashAmount ?? 0) + addCash;
    final double newOrderPaid = newOrderGcash + newOrderCash;
    final bool orderFullyPaid = orderTotal <= 0
        ? true
        : newOrderPaid >= orderTotal;

    final double totalUnpaid = orderRows.fold(0.0, (s, e) => s + e.total);

    if (totalUnpaid > 0) {
      for (int i = 0; i < orderRows.length; i++) {
        final row = orderRows[i];
        final double ratio = row.total / totalUnpaid;

        double gcashShare = addGcash * ratio;
        double cashShare = addCash * ratio;

        if (i == orderRows.length - 1) {
          final distributedGcash = orderRows
              .take(i)
              .fold(0.0, (s, e) => s + (addGcash * (e.total / totalUnpaid)));
          final distributedCash = orderRows
              .take(i)
              .fold(0.0, (s, e) => s + (addCash * (e.total / totalUnpaid)));

          gcashShare = addGcash - distributedGcash;
          cashShare = addCash - distributedCash;
        }

        final double rowNewGcash = row.gcashAmount + gcashShare;
        final double rowNewCash = row.cashAmount + cashShare;
        final double rowNewPaid = rowNewGcash + rowNewCash;
        final bool rowFullyPaid = rowNewPaid >= row.total;

        await supabase
            .from(row.table)
            .update({
              'gcash_amount': rowNewGcash,
              'cash_amount': rowNewCash,
              'is_paid': rowFullyPaid,
              'paid_at': rowFullyPaid ? DateTime.now().toIso8601String() : null,
            })
            .eq('id', row.id);
      }
    }

    final upsertResult = await supabase.from('customer_order_payments').upsert({
      'booking_code': bookingCode,
      'full_name': fullName,
      'seat_number': seatNumber,
      'order_total': orderTotal,
      'gcash_amount': newOrderGcash,
      'cash_amount': newOrderCash,
      'is_paid': orderFullyPaid,
      'paid_at': orderFullyPaid ? DateTime.now().toIso8601String() : null,
    }, onConflict: 'booking_code').select();

    if ((upsertResult as List).isEmpty) {
      throw Exception('Order payment was not recorded.');
    }

    if (_receipt != null) {
      await _syncFinalSessionPaidStatus(
        receipt: _receipt!,
        systemPaidTotal: _receipt!.systemPaidTotal,
        orderPaidTotal: newOrderPaid,
        systemDue: _receipt!.discountedSystemTotal,
        orderDue: orderTotal,
      );
    }
  }

  Widget _buildAiBubble(String text, {bool showAvatar = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            Container(
              width: 38,
              height: 38,
              decoration: ViewReceiptStyles.aiAvatarBox,
              child: ClipOval(
                child: Image.asset(
                  'assets/study_hub.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: ViewReceiptStyles.aiBubble,
              child: Text(text, style: ViewReceiptStyles.aiBubbleText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: ViewReceiptStyles.userBubble,
              child: Text(text, style: ViewReceiptStyles.userBubbleText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeInput() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: ViewReceiptStyles.codeInputWrap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Booking Code / Promo Code',
            style: ViewReceiptStyles.codeLabel,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _loadReceipt(),
            decoration: ViewReceiptStyles.codeInputDecoration(
              'Paste code here...',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSearching ? null : _loadReceipt,
              style: ViewReceiptStyles.primaryButtonStyle,
              child: _isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Load Receipt',
                      style: ViewReceiptStyles.primaryButtonText,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: ViewReceiptStyles.receiptLabel)),
          Text(
            value,
            style: ViewReceiptStyles.receiptValue.copyWith(
              color: valueColor ?? ViewReceiptStyles.receiptValue.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleAmountRow(String title, String amount, {bool big = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: big
                ? ViewReceiptStyles.totalTitle
                : ViewReceiptStyles.receiptTitleAmount,
          ),
        ),
        Text(
          amount,
          style: big
              ? ViewReceiptStyles.totalTitle
              : ViewReceiptStyles.receiptTitleAmount,
        ),
      ],
    );
  }

  Widget _buildOrderLineCard(OrderLine line) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3E9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5DAC8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((line.imageUrl ?? '').isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                line.imageUrl!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _orderPlaceholder(line),
              ),
            )
          else
            _orderPlaceholder(line),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2B1D16),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${line.qty} × ${_peso(line.price)}',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF9B6E39),
                  ),
                ),
                if ((line.size ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Size: ${line.size}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF7F6A58),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _peso(line.subtotal),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2B1D16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderPlaceholder(OrderLine line) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: line.source == OrderSource.addon
            ? const Color(0xFFEAF4E6)
            : const Color(0xFFF6EEE3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        line.source == OrderSource.addon
            ? Icons.fastfood_rounded
            : Icons.shopping_bag_rounded,
        color: line.source == OrderSource.addon
            ? const Color(0xFF4A9B45)
            : const Color(0xFFB8843B),
      ),
    );
  }

  Widget _buildReceiptCard(ReceiptData receipt) {
    final allRows = [..._addOnRows, ..._consignmentRows];
    final double orderDue = math.max(
      0,
      receipt.orderTotal - receipt.orderPaidTotal,
    );
    final double totalAmountDue =
        math.max(0, receipt.systemBalance) + math.max(0, orderDue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ViewReceiptStyles.receiptCardBox,
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: ViewReceiptStyles.receiptLogoWrap,
            child: ClipOval(
              child: Image.asset(
                'assets/study_hub.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'ME TYME LOUNGE',
            style: ViewReceiptStyles.receiptMainTitle,
          ),
          const SizedBox(height: 2),
          const Text(
            'Customer Receipt',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3A1F11),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ViewReceiptStyles.sessionInfoBox,
            child: Column(
              children: [
                _receiptRow('Name', receipt.fullName),
                _receiptRow('Date', _formatDateOnly(receipt.createdAt)),
                _receiptRow(
                  'Seat',
                  receipt.seatNumber.isEmpty ? '—' : receipt.seatNumber,
                ),
                _receiptRow(
                  receipt.source == ReceiptSource.customerSession
                      ? 'Booking Code'
                      : 'Promo Code',
                  receipt.code,
                ),
                _receiptRow(
                  'Time Start',
                  _formatDateTime(receipt.timeStartedAt),
                ),
                _receiptRow('Time End', _formatDateTime(receipt.timeEndedAt)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),

          if (_orderLines.isNotEmpty) ...[
            for (final line in _orderLines) _buildOrderLineCard(line),
            const Divider(),
          ],

          if (receipt.source == ReceiptSource.customerSession)
            _receiptRow('Time Consumed', receipt.timeConsumedText),
          _receiptRow('System Cost', _peso2(receipt.systemTotal)),
          _receiptRow(
            'Discount',
            receipt.discountAmount > 0
                ? '- ${_peso2(receipt.discountAmount)}'
                : '₱0.00',
          ),
          _receiptRow('Orders Total', _peso(receipt.orderTotal)),
          _receiptRow('Down Payment', '₱0'),
          _receiptRow(
            'GCash',
            _peso(receipt.systemGcash + receipt.orderGcashPaid),
          ),
          _receiptRow(
            'Cash',
            _peso(receipt.systemCash + receipt.orderCashPaid),
          ),
          _receiptRow(
            'Total Paid',
            _peso2(receipt.systemPaidTotal + receipt.orderPaidTotal),
          ),
          _receiptRow('Total Amount Due', _peso2(totalAmountDue)),
          _receiptRow(
            'Change',
            _peso2(
              ((receipt.systemPaidTotal - receipt.discountedSystemTotal) > 0
                      ? (receipt.systemPaidTotal -
                            receipt.discountedSystemTotal)
                      : 0) +
                  ((receipt.orderPaidTotal - receipt.orderTotal) > 0
                      ? (receipt.orderPaidTotal - receipt.orderTotal)
                      : 0),
            ),
          ),
          _receiptRow(
            'Status',
            receipt.isFullyPaid ? 'PAID' : 'UNPAID',
            valueColor: receipt.isFullyPaid
                ? const Color(0xFF2D8A34)
                : const Color(0xFFB88421),
          ),
          _receiptRow('Paid at', _formatDateTime(receipt.paidAt)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: ViewReceiptStyles.totalBox,
            child: _titleAmountRow(
              'TOTAL AMOUNT DUE',
              _peso2(totalAmountDue),
              big: true,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Thank you for choosing\nMe Tyme Lounge',
            textAlign: TextAlign.center,
            style: ViewReceiptStyles.thankYouText,
          ),
          const SizedBox(height: 18),
          if (!receipt.isFullyPaid || orderDue > 0)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showPaymentModal,
                style: ViewReceiptStyles.primaryButtonStyle,
                child: const Text(
                  'Pay Now',
                  style: ViewReceiptStyles.primaryButtonText,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ViewReceiptStyles.primaryButtonStyle,
                child: const Text(
                  'Close',
                  style: ViewReceiptStyles.primaryButtonText,
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
    final isMobile = screen.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF1EEE9),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: ViewReceiptStyles.pageBackground,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: Container(
                  width: isMobile ? screen.width * 0.96 : 600,
                  height: isMobile ? screen.height * 0.92 : 760,
                  padding: const EdgeInsets.all(20),
                  decoration: ViewReceiptStyles.mainCard,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: ViewReceiptStyles.topHeaderCard,
                        child: Row(
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: ViewReceiptStyles.topHeaderAvatar,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/study_hub.png',
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Receipt Assistant',
                                    style: ViewReceiptStyles.headerTitle,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Paste your code to view and pay your receipt below.',
                                    style: ViewReceiptStyles.headerSubtitle,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: ViewReceiptStyles.headerChip,
                              child: const Text(
                                'View Receipt',
                                style: ViewReceiptStyles.headerChipText,
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF3A3534),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: ViewReceiptStyles.chatAreaCard,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              children: [
                                const SizedBox(height: 10),
                                Center(
                                  child: SizedBox(
                                    width: isMobile ? double.infinity : 620,
                                    child: _buildCodeInput(),
                                  ),
                                ),

                                if (_receipt == null) ...[
                                  const SizedBox(height: 16),
                                  for (final message in _chatMessages) ...[
                                    Align(
                                      alignment: message.isAI
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      child: message.isAI
                                          ? _buildAiBubble(message.text)
                                          : _buildUserBubble(message.text),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ],

                                if (_receipt != null) ...[
                                  const SizedBox(height: 18),
                                  _buildReceiptCard(_receipt!),
                                  const SizedBox(height: 16),
                                  for (final message in _chatMessages) ...[
                                    Align(
                                      alignment: message.isAI
                                          ? Alignment.centerLeft
                                          : Alignment.centerRight,
                                      child: message.isAI
                                          ? _buildAiBubble(message.text)
                                          : _buildUserBubble(message.text),
                                    ),
                                    const SizedBox(height: 6),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ViewReceiptStyles.bottomCloseButtonStyle,
                          child: const Text(
                            'Close',
                            style: ViewReceiptStyles.bottomCloseButtonText,
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

class _ChatMessage {
  final bool isAI;
  final String text;

  const _ChatMessage({required this.isAI, required this.text});

  const _ChatMessage.ai(this.text) : isAI = true;
  const _ChatMessage.user(this.text) : isAI = false;
}

enum ReceiptSource { customerSession, promoBooking }

enum OrderSource { addon, consignment }

class ReceiptData {
  final String id;
  final ReceiptSource source;
  final String code;
  final String fullName;
  final String seatNumber;
  final String createdAt;
  final String? paidAt;

  final double systemTotal;
  final double discountAmount;
  final double systemGcash;
  final double systemCash;

  final String itemTitle;
  final String itemSubtitle;

  final int timeConsumedMinutes;
  final String? timeStartedAt;
  final String? timeEndedAt;

  final double orderTotal;
  final double orderGcashPaid;
  final double orderCashPaid;

  const ReceiptData({
    required this.id,
    required this.source,
    required this.code,
    required this.fullName,
    required this.seatNumber,
    required this.createdAt,
    required this.paidAt,
    required this.systemTotal,
    required this.discountAmount,
    required this.systemGcash,
    required this.systemCash,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.timeConsumedMinutes,
    required this.timeStartedAt,
    required this.timeEndedAt,
    required this.orderTotal,
    required this.orderGcashPaid,
    required this.orderCashPaid,
  });

  double get systemPaidTotal => systemGcash + systemCash;
  double get orderPaidTotal => orderGcashPaid + orderCashPaid;

  String get timeConsumedText {
    final mins = timeConsumedMinutes < 0 ? 0 : timeConsumedMinutes;
    final hours = mins ~/ 60;
    final minutes = mins % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    }
    if (hours > 0) {
      return '${hours}h';
    }
    return '${minutes}m';
  }

  double get discountedSystemTotal {
    final value = systemTotal - discountAmount;
    return value > 0 ? value : 0;
  }

  double get systemBalance {
    final value = discountedSystemTotal - systemPaidTotal;
    return value > 0 ? value : 0;
  }

  bool get isFullyPaid =>
      systemPaidTotal >= discountedSystemTotal && orderPaidTotal >= orderTotal;

  ReceiptData copyWith({
    double? orderTotal,
    double? orderGcashPaid,
    double? orderCashPaid,
  }) {
    return ReceiptData(
      id: id,
      source: source,
      code: code,
      fullName: fullName,
      seatNumber: seatNumber,
      createdAt: createdAt,
      paidAt: paidAt,
      systemTotal: systemTotal,
      discountAmount: discountAmount,
      systemGcash: systemGcash,
      systemCash: systemCash,
      itemTitle: itemTitle,
      itemSubtitle: itemSubtitle,
      timeConsumedMinutes: timeConsumedMinutes,
      timeStartedAt: timeStartedAt,
      timeEndedAt: timeEndedAt,
      orderTotal: orderTotal ?? this.orderTotal,
      orderGcashPaid: orderGcashPaid ?? this.orderGcashPaid,
      orderCashPaid: orderCashPaid ?? this.orderCashPaid,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static ReceiptData fromCustomerSession(Map<String, dynamic> map) {
    final totalAmount = _toDouble(map['total_amount']);
    final discountKind = (map['discount_kind'] ?? 'none').toString();
    final discountValue = _toDouble(map['discount_value']);

    double discountAmount = 0;
    if (discountKind == 'percent') {
      discountAmount = totalAmount * (discountValue / 100);
    } else if (discountKind == 'amount') {
      discountAmount = discountValue;
    }

    final totalTime = _toDouble(map['total_time']);
    final minutes = totalTime.round();

    return ReceiptData(
      id: (map['id'] ?? '').toString(),
      source: ReceiptSource.customerSession,
      code: (map['booking_code'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      seatNumber: (map['seat_number'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      paidAt: map['paid_at']?.toString(),
      systemTotal: totalAmount,
      discountAmount: discountAmount,
      systemGcash: _toDouble(map['gcash_amount']),
      systemCash: _toDouble(map['cash_amount']),
      itemTitle: 'Study Hub Session',
      itemSubtitle: '$minutes mins used • $minutes mins charged',
      timeConsumedMinutes: minutes,
      timeStartedAt: map['time_started']?.toString(),
      timeEndedAt: map['time_ended']?.toString(),
      orderTotal: 0,
      orderGcashPaid: 0,
      orderCashPaid: 0,
    );
  }

  static ReceiptData fromPromoBooking(Map<String, dynamic> map) {
    final price = _toDouble(map['price']);
    final discountKind = (map['discount_kind'] ?? 'none').toString();
    final discountValue = _toDouble(map['discount_value']);

    double discountAmount = 0;
    if (discountKind == 'percent') {
      discountAmount = price * (discountValue / 100);
    } else if (discountKind == 'amount') {
      discountAmount = discountValue;
    }

    final area = (map['area'] ?? '').toString();
    final title = area == 'conference_room'
        ? 'Conference Room Promo'
        : 'Promo Booking';

    return ReceiptData(
      id: (map['id'] ?? '').toString(),
      source: ReceiptSource.promoBooking,
      code: (map['promo_code'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      seatNumber: (map['seat_number'] ?? '').toString(),
      createdAt: (map['created_at'] ?? '').toString(),
      paidAt: map['paid_at']?.toString(),
      systemTotal: price,
      discountAmount: discountAmount,
      systemGcash: _toDouble(map['gcash_amount']),
      systemCash: _toDouble(map['cash_amount']),
      itemTitle: title,
      itemSubtitle: 'Promo / reservation receipt',
      timeConsumedMinutes: 0,
      timeStartedAt: map['start_at']?.toString(),
      timeEndedAt: map['end_at']?.toString(),
      orderTotal: 0,
      orderGcashPaid: 0,
      orderCashPaid: 0,
    );
  }
}

class OrderRow {
  final String id;
  final String table;
  final double total;
  final bool isPaid;
  final double gcashAmount;
  final double cashAmount;

  const OrderRow({
    required this.id,
    required this.table,
    required this.total,
    required this.isPaid,
    required this.gcashAmount,
    required this.cashAmount,
  });

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  factory OrderRow.fromMap(Map<String, dynamic> map, {required String table}) {
    return OrderRow(
      id: (map['id'] ?? '').toString(),
      table: table,
      total: _toDouble(map['total']),
      isPaid: map['is_paid'] == true,
      gcashAmount: _toDouble(map['gcash_amount']),
      cashAmount: _toDouble(map['cash_amount']),
    );
  }
}

class OrderLine {
  final OrderSource source;
  final String name;
  final int qty;
  final double price;
  final double subtotal;
  final String category;
  final String? size;
  final String? imageUrl;

  const OrderLine({
    required this.source,
    required this.name,
    required this.qty,
    required this.price,
    required this.subtotal,
    required this.category,
    required this.size,
    required this.imageUrl,
  });
}

class _OrderBundleForReceipt {
  final List<OrderRow> addOnRows;
  final List<OrderRow> consignmentRows;
  final List<OrderLine> orderLines;
  final double orderDisplayTotal;

  const _OrderBundleForReceipt({
    required this.addOnRows,
    required this.consignmentRows,
    required this.orderLines,
    required this.orderDisplayTotal,
  });
}

class ReceiptLookupResult {
  final ReceiptData receipt;
  final List<OrderRow> addOnRows;
  final List<OrderRow> consignmentRows;
  final List<OrderLine> orderLines;
  final double orderDisplayTotal;
  final CustomerOrderPaymentRow? orderPaymentRow;

  const ReceiptLookupResult({
    required this.receipt,
    required this.addOnRows,
    required this.consignmentRows,
    required this.orderLines,
    required this.orderDisplayTotal,
    required this.orderPaymentRow,
  });

  List<OrderRow> get allRows => [...addOnRows, ...consignmentRows];
}

class CustomerOrderPaymentRow {
  final String bookingCode;
  final double orderTotal;
  final double gcashAmount;
  final double cashAmount;
  final bool isPaid;
  final String? paidAt;

  const CustomerOrderPaymentRow({
    required this.bookingCode,
    required this.orderTotal,
    required this.gcashAmount,
    required this.cashAmount,
    required this.isPaid,
    required this.paidAt,
  });

  double get totalPaid => gcashAmount + cashAmount;

  factory CustomerOrderPaymentRow.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return CustomerOrderPaymentRow(
      bookingCode: (map['booking_code'] ?? '').toString().trim().toUpperCase(),
      orderTotal: toDouble(map['order_total']),
      gcashAmount: toDouble(map['gcash_amount']),
      cashAmount: toDouble(map['cash_amount']),
      isPaid: map['is_paid'] == true,
      paidAt: map['paid_at']?.toString(),
    );
  }
}
