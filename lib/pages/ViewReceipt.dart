import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../styles/ViewReceipt_styles.dart';

class ViewReceipt extends StatefulWidget {
  const ViewReceipt({super.key});

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

  ReceiptData? _receipt;
  List<OrderRow> _addOnRows = [];
  List<OrderRow> _consignmentRows = [];

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

    _animController.forward();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scrollController.dispose();
    _animController.dispose();
    super.dispose();
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
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
    final hourAvail = (row['hour_avail'] ?? '').toString().trim().toUpperCase();
    final timeEndedRaw = row['time_ended']?.toString().trim() ?? '';

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

    final sessionId = (row['id'] ?? '').toString();
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 200,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadReceipt() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty || _isSearching) return;

    setState(() {
      _isSearching = true;
      _receipt = null;
      _addOnRows = [];
      _consignmentRows = [];
    });

    try {
      final result = await _findReceiptByCode(code);

      if (result == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No receipt found for that code.')),
        );
        return;
      }

      setState(() {
        _receipt = result.receipt.copyWith(
          orderTotal: _sumOrders(result.allRows),
          orderGcashPaid: _sumOrderGcash(result.allRows),
          orderCashPaid: _sumOrderCash(result.allRows),
        );
        _addOnRows = result.addOnRows;
        _consignmentRows = result.consignmentRows;
      });

      _scrollToBottom();
    } catch (e) {
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
      final orderBundle = await _loadOrderRowsForReceipt(receipt);
      return ReceiptLookupResult(
        receipt: receipt,
        addOnRows: orderBundle.addOnRows,
        consignmentRows: orderBundle.consignmentRows,
      );
    }

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
      final orderBundle = await _loadOrderRowsForReceipt(receipt);
      return ReceiptLookupResult(
        receipt: receipt,
        addOnRows: orderBundle.addOnRows,
        consignmentRows: orderBundle.consignmentRows,
      );
    }

    return null;
  }

  Future<OrderRowsBundle> _loadOrderRowsForReceipt(ReceiptData receipt) async {
    final List<OrderRow> addOnRows = [];
    final List<OrderRow> consignmentRows = [];

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

    return OrderRowsBundle(
      addOnRows: addOnRows,
      consignmentRows: consignmentRows,
    );
  }

  Future<void> _showPaymentModal() async {
    if (_receipt == null) return;

    final receipt = _receipt!;
    final unpaidOrderRows = [
      ..._addOnRows,
      ..._consignmentRows,
    ].where((e) => !e.isPaid).toList();

    final double systemDue = receipt.systemBalance;
    final double orderDue = _sumUnpaidOrders(unpaidOrderRows);

    final systemGcashController = TextEditingController(text: '0');
    final systemCashController = TextEditingController(text: '0');
    final orderGcashController = TextEditingController(text: '0');
    final orderCashController = TextEditingController(text: '0');

    await showDialog(
      context: context,
      barrierDismissible: !_isSavingSystem && !_isSavingOrders,
      builder: (context) {
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
                if (refreshed != null) {
                  setState(() {
                    _receipt = refreshed.receipt.copyWith(
                      orderTotal: _sumOrders(refreshed.allRows),
                      orderGcashPaid: _sumOrderGcash(refreshed.allRows),
                      orderCashPaid: _sumOrderCash(refreshed.allRows),
                    );
                    _addOnRows = refreshed.addOnRows;
                    _consignmentRows = refreshed.consignmentRows;
                  });
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('System payment saved.')),
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
                setModalState(() => _isSavingSystem = false);
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
                if (refreshed != null) {
                  setState(() {
                    _receipt = refreshed.receipt.copyWith(
                      orderTotal: _sumOrders(refreshed.allRows),
                      orderGcashPaid: _sumOrderGcash(refreshed.allRows),
                      orderCashPaid: _sumOrderCash(refreshed.allRows),
                    );
                    _addOnRows = refreshed.addOnRows;
                    _consignmentRows = refreshed.consignmentRows;
                  });
                }

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order payment saved.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save order payment: $e')),
                  );
                }
              } finally {
                setModalState(() => _isSavingOrders = false);
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
                          onSave: _isSavingSystem ? null : saveSystemPayment,
                          isSaving: _isSavingSystem,
                        ),
                        if (orderDue > 0) ...[
                          const SizedBox(height: 18),
                          _paymentSection(
                            title: 'Order Payment',
                            dueText: 'Balance: ${_peso2(orderDue)}',
                            gcashController: orderGcashController,
                            cashController: orderCashController,
                            onSave: _isSavingOrders ? null : saveOrderPayment,
                            isSaving: _isSavingOrders,
                          ),
                        ],
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
    final double newPaid = newGcash + newCash;
    final bool fullyPaid = newPaid >= receipt.systemTotal;

    final payload = {
      'gcash_amount': newGcash,
      'cash_amount': newCash,
      'is_paid': fullyPaid,
      'paid_at': DateTime.now().toIso8601String(),
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
    if (orderRows.isEmpty) return;

    final double totalUnpaid = orderRows.fold(0.0, (s, e) => s + e.total);
    if (totalUnpaid <= 0) return;

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

      final double newGcash = row.gcashAmount + gcashShare;
      final double newCash = row.cashAmount + cashShare;
      final double newTotalPaid = newGcash + newCash;
      final bool fullyPaid = newTotalPaid >= row.total;

      await supabase
          .from(row.table)
          .update({
            'gcash_amount': newGcash,
            'cash_amount': newCash,
            'is_paid': fullyPaid,
            'paid_at': DateTime.now().toIso8601String(),
          })
          .eq('id', row.id);
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

  Widget _buildReceiptCard(ReceiptData receipt) {
    final allRows = [..._addOnRows, ..._consignmentRows];
    final double orderDue = _sumUnpaidOrders(allRows);

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
            'OFFICIAL RECEIPT',
            style: ViewReceiptStyles.receiptSubTitle,
          ),
          const SizedBox(height: 18),
          const Divider(),
          _receiptRow(
            'Date',
            _formatDateTime(receipt.paidAt ?? receipt.createdAt),
          ),
          _receiptRow('Customer', receipt.fullName),
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
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: ViewReceiptStyles.sessionInfoBox,
            child: Column(
              children: [
                _titleAmountRow(receipt.itemTitle, _peso2(receipt.systemTotal)),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    receipt.itemSubtitle,
                    style: ViewReceiptStyles.sessionInfoSubText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Divider(),
          _receiptRow('System Cost', _peso2(receipt.systemTotal)),
          _receiptRow(
            'Discount',
            receipt.discountAmount > 0
                ? '- ${_peso2(receipt.discountAmount)}'
                : '—',
          ),
          _receiptRow('Orders Total', _peso2(receipt.orderTotal)),
          _receiptRow(
            'GCash',
            _peso2(receipt.systemGcash + receipt.orderGcashPaid),
          ),
          _receiptRow(
            'Cash',
            _peso2(receipt.systemCash + receipt.orderCashPaid),
          ),
          _receiptRow(
            'Total Paid',
            _peso2(receipt.systemPaidTotal + receipt.orderPaidTotal),
          ),
          _receiptRow(
            'Change',
            _peso2(
              ((receipt.systemPaidTotal - receipt.systemTotal) > 0
                      ? (receipt.systemPaidTotal - receipt.systemTotal)
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
              'TOTAL',
              _peso2(receipt.systemTotal + receipt.orderTotal),
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
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _buildUserBubble(
                                    'You selected View Receipt 🧾',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: _buildAiBubble(
                                    'Please paste your booking code or promo code below to view your receipt.',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: SizedBox(
                                    width: isMobile ? double.infinity : 620,
                                    child: _buildCodeInput(),
                                  ),
                                ),
                                if (_receipt != null) ...[
                                  const SizedBox(height: 18),
                                  _buildReceiptCard(_receipt!),
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

enum ReceiptSource { customerSession, promoBooking }

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
    required this.orderTotal,
    required this.orderGcashPaid,
    required this.orderCashPaid,
  });

  double get systemPaidTotal => systemGcash + systemCash;
  double get orderPaidTotal => orderGcashPaid + orderCashPaid;

  double get systemBalance {
    final value = systemTotal - systemPaidTotal;
    return value > 0 ? value : 0;
  }

  bool get isFullyPaid =>
      systemPaidTotal >= systemTotal && orderPaidTotal >= orderTotal;

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

class OrderRowsBundle {
  final List<OrderRow> addOnRows;
  final List<OrderRow> consignmentRows;

  const OrderRowsBundle({
    required this.addOnRows,
    required this.consignmentRows,
  });

  List<OrderRow> get allRows => [...addOnRows, ...consignmentRows];
}

class ReceiptLookupResult {
  final ReceiptData receipt;
  final List<OrderRow> addOnRows;
  final List<OrderRow> consignmentRows;

  const ReceiptLookupResult({
    required this.receipt,
    required this.addOnRows,
    required this.consignmentRows,
  });

  List<OrderRow> get allRows => [...addOnRows, ...consignmentRows];
}
