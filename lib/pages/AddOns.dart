import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../styles/AddOns_styles.dart';

enum CatalogKind { addOn, otherItems }

class CatalogItem {
  final String id;
  final CatalogKind kind;
  final String category;
  final String name;
  final double price;
  final int stocks;
  final String? size;
  final String? imageUrl;

  const CatalogItem({
    required this.id,
    required this.kind,
    required this.category,
    required this.name,
    required this.price,
    required this.stocks,
    required this.size,
    required this.imageUrl,
  });
}

class OrderRowData {
  String? category;
  CatalogItem? item;
  int quantity;

  OrderRowData({this.category, this.item, this.quantity = 1});

  double get subtotal => (item?.price ?? 0) * quantity;
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool showAvatar;
  final Widget? bottomAction;

  const ChatMessage({
    required this.text,
    required this.isUser,
    this.showAvatar = true,
    this.bottomAction,
  });
}

class SubmittedOrderSummary {
  final String? bookingCode;
  final String fullName;
  final String seatNumber;
  final double orderTotal;
  final int addOnCount;
  final int specialItemCount;
  final List<String> addOnRowIds;
  final List<String> consignmentRowIds;
  final String submittedAtIso;

  const SubmittedOrderSummary({
    required this.bookingCode,
    required this.fullName,
    required this.seatNumber,
    required this.orderTotal,
    required this.addOnCount,
    required this.specialItemCount,
    required this.addOnRowIds,
    required this.consignmentRowIds,
    required this.submittedAtIso,
  });
}

class AddOnsPage extends StatefulWidget {
  const AddOnsPage({super.key});

  @override
  State<AddOnsPage> createState() => _AddOnsPageState();
}

class _AddOnsPageState extends State<AddOnsPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final TextEditingController fullNameController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final TextEditingController gcashController = TextEditingController(
    text: '0',
  );
  final TextEditingController cashController = TextEditingController(text: '0');

  String? selectedSeat;
  bool isLoading = true;
  bool isSubmitting = false;
  bool showForm = false;
  bool paymentSaving = false;
  bool formLocked = false;

  List<CatalogItem> addOnItems = [];
  List<CatalogItem> otherItems = [];
  List<OrderRowData> orderRows = [OrderRowData()];
  List<ChatMessage> chatMessages = [];

  SubmittedOrderSummary? submittedOrder;

  late final AnimationController pageController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;

  final Map<String, List<String>> seatGroups = const {
    '1stF': [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7A',
      '7B',
      '8A',
      '8B',
      '9',
      '10',
      '11',
    ],
    'TATAMI AREA': ['12A', '12B', '12C'],
    '2ndF': [
      '13',
      '14',
      '15',
      '16',
      '17',
      '18',
      '19',
      '20',
      '21',
      '22',
      '23',
      '24',
      '25',
    ],
    'CONFERENCE ROOM': ['CONFERENCE ROOM'],
  };

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
    _loadCatalog();

    chatMessages = [];

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {
        showForm = true;
      });
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    scrollController.dispose();
    gcashController.dispose();
    cashController.dispose();
    pageController.dispose();
    super.dispose();
  }

  double get totalAmount {
    return orderRows.fold(0, (sum, row) => sum + row.subtotal);
  }

  List<String> get categories {
    final values = <String>{};

    for (final item in addOnItems) {
      if (item.category.trim().isNotEmpty) {
        values.add(item.category.trim());
      }
    }

    if (otherItems.isNotEmpty) {
      values.add('SPECIAL ITEM');
    }

    final list = values.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  bool get isValid {
    if (fullNameController.text.trim().isEmpty) return false;
    if (selectedSeat == null || selectedSeat!.trim().isEmpty) return false;
    if (orderRows.isEmpty) return false;

    for (final row in orderRows) {
      if ((row.category ?? '').trim().isEmpty) return false;
      if (row.item == null) return false;
      if (row.quantity <= 0) return false;
    }
    return true;
  }

  Future<void> _loadCatalog() async {
    setState(() {
      isLoading = true;
    });

    try {
      final addOnsResponse = await supabase
          .from('add_ons')
          .select('id, category, name, price, image_url, stocks, size')
          .gt('stocks', 0)
          .order('category')
          .order('name');

      final otherItemsResponse = await supabase
          .from('consignment')
          .select(
            'id, item_name, price, image_url, stocks, size, approval_status',
          )
          .eq('approval_status', 'approved')
          .gt('stocks', 0)
          .order('item_name');

      addOnItems = (addOnsResponse as List<dynamic>).map((row) {
        return CatalogItem(
          id: row['id'].toString(),
          kind: CatalogKind.addOn,
          category: (row['category'] ?? '').toString(),
          name: (row['name'] ?? '').toString(),
          price: _toDouble(row['price']),
          stocks: _toInt(row['stocks']),
          size: row['size']?.toString(),
          imageUrl: row['image_url']?.toString(),
        );
      }).toList();

      otherItems = (otherItemsResponse as List<dynamic>).map((row) {
        return CatalogItem(
          id: row['id'].toString(),
          kind: CatalogKind.otherItems,
          category: 'SPECIAL ITEM',
          name: (row['item_name'] ?? '').toString(),
          price: _toDouble(row['price']),
          stocks: _toInt(row['stocks']),
          size: row['size']?.toString(),
          imageUrl: row['image_url']?.toString(),
        );
      }).toList();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
    }

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });
  }

  double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    return double.tryParse(value.toString()) ?? 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  double _moneyFromText(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  double _round2(num value) {
    return double.parse(value.toStringAsFixed(2));
  }

  String _money(double value) => '₱${_round2(value).toStringAsFixed(2)}';

  List<CatalogItem> itemsForCategory(String category) {
    if (category == 'SPECIAL ITEM') return otherItems;
    return addOnItems.where((e) => e.category == category).toList();
  }

  Future<void> pickSeat() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SeatPickerSheet(
          seatGroups: seatGroups,
          selectedSeat: selectedSeat,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedSeat = result;
      });
    }
  }

  Future<void> pickCategory(int index) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SelectionSheet<String>(
          title: 'Select Category',
          items: categories
              .map((e) => _SheetOption(label: e, value: e))
              .toList(),
        );
      },
    );

    if (result != null) {
      debugPrint('PICKED CATEGORY => $result');

      setState(() {
        orderRows[index].category = result;
        orderRows[index].item = null;
        orderRows[index].quantity = 1;
      });
    }
  }

  Future<void> pickItem(int index) async {
    final category = orderRows[index].category;
    if (category == null || category.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select category first.')));
      return;
    }

    final result = await showModalBottomSheet<CatalogItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ItemPickerSheet(
          title: category == 'SPECIAL ITEM'
              ? 'Choose Other Item'
              : 'Choose Add-On',
          items: itemsForCategory(category),
        );
      },
    );

    if (result != null) {
      debugPrint(
        'PICKED ITEM => id=${result.id}, name=${result.name}, category=${result.category}, kind=${result.kind}',
      );

      setState(() {
        orderRows[index].item = result;
        orderRows[index].quantity = 1;
      });
    }
  }

  void changeQty(int index, int nextQty) {
    final currentItem = orderRows[index].item;
    if (currentItem == null) return;

    final safeQty = nextQty < 1 ? 1 : nextQty;
    final maxQty = currentItem.stocks;
    final finalQty = safeQty > maxQty ? maxQty : safeQty;

    setState(() {
      orderRows[index].quantity = finalQty;
    });
  }

  void addMoreOrder() {
    setState(() {
      orderRows.add(OrderRowData());
    });
    _scrollToBottom();
  }

  void resetOrder() {
    setState(() {
      fullNameController.clear();
      selectedSeat = null;
      orderRows = [OrderRowData()];
      submittedOrder = null;
      gcashController.text = '0';
      cashController.text = '0';
      showForm = true;
      formLocked = false;

      chatMessages = [];
    });
    _scrollToBottom();
  }

  String? _extractBookingCode(dynamic value) {
    if (value == null) return null;

    if (value is String) {
      final raw = value.trim();
      final isUuid = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(raw);

      if (isUuid) return null;

      final code = raw.toUpperCase();
      return code.isEmpty ? null : code;
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final code = (map['booking_code'] ?? '').toString().trim().toUpperCase();
      return code.isEmpty ? null : code;
    }

    if (value is List && value.isNotEmpty) {
      final first = value.first;

      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        final code = (map['booking_code'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        return code.isEmpty ? null : code;
      }

      if (first is String) {
        final code = first.trim().toUpperCase();
        return code.isEmpty ? null : code;
      }
    }

    return null;
  }

  String? _extractUuid(dynamic value) {
    if (value == null) return null;

    final raw = value.toString().trim();
    final isUuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(raw);

    return isUuid ? raw : null;
  }

  Future<String?> _findLatestBookingCode({required bool forAddOns}) async {
    try {
      final table = forAddOns ? 'addon_orders' : 'consignment_orders';

      final rows = await supabase
          .from(table)
          .select('booking_code, created_at')
          .order('created_at', ascending: false)
          .limit(10);

      if (rows is! List || rows.isEmpty) return null;

      rows.sort((a, b) {
        final aMap = Map<String, dynamic>.from(a as Map);
        final bMap = Map<String, dynamic>.from(b as Map);

        final aTime =
            DateTime.tryParse(
              '${aMap['created_at']}',
            )?.millisecondsSinceEpoch ??
            0;
        final bTime =
            DateTime.tryParse(
              '${bMap['created_at']}',
            )?.millisecondsSinceEpoch ??
            0;

        return bTime.compareTo(aTime);
      });

      return _extractBookingCode(rows.first);
    } catch (_) {
      return null;
    }
  }

  int get _submittedAddOnCount {
    int count = 0;
    for (final row in orderRows) {
      if (row.item?.kind == CatalogKind.addOn) count += row.quantity;
    }
    return count;
  }

  int get _submittedSpecialItemCount {
    int count = 0;
    for (final row in orderRows) {
      if (row.item?.kind == CatalogKind.otherItems) count += row.quantity;
    }
    return count;
  }

  Future<List<String>> _findLatestAddOnRowIds({
    required String fullName,
    required String seatNumber,
    required double expectedTotal,
    String? submittedAtIso,
  }) async {
    var query = supabase
        .from('customer_session_add_ons')
        .select('id, total, created_at, full_name, seat_number, is_paid')
        .eq('full_name', fullName)
        .eq('seat_number', seatNumber)
        .eq('is_paid', false);

    if (submittedAtIso != null && submittedAtIso.trim().isNotEmpty) {
      final submittedAt = DateTime.tryParse(submittedAtIso);
      if (submittedAt != null) {
        final fromIso = submittedAt
            .subtract(const Duration(seconds: 20))
            .toUtc()
            .toIso8601String();
        query = query.gte('created_at', fromIso);
      }
    }

    final rows = await query.order('created_at', ascending: false);

    final ids = <String>[];
    double runningTotal = 0;

    for (final row in (rows as List<dynamic>)) {
      final id = (row['id'] ?? '').toString();
      final rowTotal = _toDouble(row['total']);

      if (id.isEmpty) continue;

      ids.add(id);
      runningTotal = _round2(runningTotal + rowTotal);

      if (runningTotal == expectedTotal) {
        break;
      }
    }

    debugPrint(
      '_findLatestAddOnRowIds => fullName=$fullName seat=$seatNumber total=$expectedTotal ids=$ids',
    );

    return ids;
  }

  Future<List<String>> _findLatestConsignmentRowIds({
    required String fullName,
    required String seatNumber,
    required double expectedTotal,
    String? submittedAtIso,
  }) async {
    var query = supabase
        .from('customer_session_consignment')
        .select(
          'id, total, created_at, full_name, seat_number, is_paid, voided',
        )
        .eq('full_name', fullName)
        .eq('seat_number', seatNumber)
        .eq('is_paid', false)
        .eq('voided', false);

    if (submittedAtIso != null && submittedAtIso.trim().isNotEmpty) {
      final submittedAt = DateTime.tryParse(submittedAtIso);
      if (submittedAt != null) {
        final fromIso = submittedAt
            .subtract(const Duration(seconds: 20))
            .toUtc()
            .toIso8601String();
        query = query.gte('created_at', fromIso);
      }
    }

    final rows = await query.order('created_at', ascending: false);

    final ids = <String>[];
    double runningTotal = 0;

    for (final row in (rows as List<dynamic>)) {
      final id = (row['id'] ?? '').toString();
      final rowTotal = _toDouble(row['total']);

      if (id.isEmpty) continue;

      ids.add(id);
      runningTotal = _round2(runningTotal + rowTotal);

      if (runningTotal == expectedTotal) {
        break;
      }
    }

    debugPrint(
      '_findLatestConsignmentRowIds => fullName=$fullName seat=$seatNumber total=$expectedTotal ids=$ids',
    );

    return ids;
  }

  Future<void> submitOrder() async {
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all order information.')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final addOnPayload = <Map<String, dynamic>>[];
      final otherItemsPayload = <Map<String, dynamic>>[];

      for (final row in orderRows) {
        if (row.item == null) continue;
        if (row.item!.kind == CatalogKind.addOn) {
          debugPrint(
            'ADD-ON payload => id=${row.item!.id}, name=${row.item!.name}, qty=${row.quantity}, kind=${row.item!.kind}',
          );

          addOnPayload.add({
            'add_on_id': row.item!.id,
            'quantity': row.quantity,
          });
        } else {
          otherItemsPayload.add({
            'consignment_id': row.item!.id,
            'quantity': row.quantity,
          });
        }
      }

      final fullName = fullNameController.text.trim();
      final seat = (selectedSeat ?? '').trim();
      final computedTotal = _round2(totalAmount);
      final submittedAtIso = DateTime.now()
          .subtract(const Duration(seconds: 2))
          .toUtc()
          .toIso8601String();

      String? addOnBookingCode;
      String? consignmentBookingCode;
      String? addOnOrderId;

      if (addOnPayload.isNotEmpty) {
        final addOnIds = addOnPayload
            .map((e) => (e['add_on_id'] ?? '').toString())
            .where((e) => e.isNotEmpty)
            .toList();

        final existingRows = await supabase
            .from('add_ons')
            .select('id, name')
            .inFilter('id', addOnIds);

        final existingIds = (existingRows as List<dynamic>)
            .map((e) => (e['id'] ?? '').toString())
            .toSet();

        final missingIds = addOnIds
            .where((id) => !existingIds.contains(id))
            .toList();

        debugPrint('ADD-ON ids from payload: $addOnIds');
        debugPrint('ADD-ON ids found in DB: $existingIds');
        debugPrint('ADD-ON ids missing in DB: $missingIds');

        if (missingIds.isNotEmpty) {
          throw Exception(
            'These add-on ids do not exist in add_ons: $missingIds',
          );
        }

        final addOnRes = await supabase.rpc(
          'place_addon_order',
          params: {
            'p_full_name': fullName,
            'p_seat_number': seat,
            'p_items': addOnPayload,
          },
        );

        addOnOrderId = _extractUuid(addOnRes);
        addOnBookingCode = _extractBookingCode(addOnRes);

        debugPrint('place_addon_order result: $addOnRes');
        debugPrint('addOnOrderId: $addOnOrderId');
        debugPrint('addOnBookingCode: $addOnBookingCode');
      }

      if (otherItemsPayload.isNotEmpty) {
        final consignmentRes = await supabase.rpc(
          'place_consignment_order',
          params: {
            'p_full_name': fullName,
            'p_seat_number': seat,
            'p_items': otherItemsPayload,
          },
        );

        consignmentBookingCode = _extractBookingCode(consignmentRes);
      }

      String? resolvedBookingCode = addOnBookingCode ?? consignmentBookingCode;
      resolvedBookingCode ??= await _findLatestBookingCode(
        forAddOns: addOnPayload.isNotEmpty,
      );

      final addOnRowIds = addOnPayload.isNotEmpty
          ? await _findLatestAddOnRowIds(
              fullName: fullName,
              seatNumber: seat,
              expectedTotal: computedTotal,
              submittedAtIso: submittedAtIso,
            )
          : <String>[];

      final consignmentRowIds = otherItemsPayload.isNotEmpty
          ? await _findLatestConsignmentRowIds(
              fullName: fullName,
              seatNumber: seat,
              expectedTotal: computedTotal,
              submittedAtIso: submittedAtIso,
            )
          : <String>[];

      await _loadCatalog();

      if (!mounted) return;

      final summary = SubmittedOrderSummary(
        bookingCode: resolvedBookingCode,
        fullName: fullName,
        seatNumber: seat,
        orderTotal: computedTotal,
        addOnCount: _submittedAddOnCount,
        specialItemCount: _submittedSpecialItemCount,
        addOnRowIds: addOnRowIds,
        consignmentRowIds: consignmentRowIds,
        submittedAtIso: submittedAtIso,
      );

      setState(() {
        submittedOrder = summary;
        gcashController.text = '0';
        cashController.text = '0';
        formLocked = true;
        showForm = true;

        chatMessages = [
          ChatMessage(
            text:
                'Order submitted successfully ✅\n\n'
                'Customer: ${summary.fullName}\n'
                'Seat: ${summary.seatNumber}\n'
                'Add-Ons found: ${summary.addOnCount}\n'
                'Special Item found: ${summary.specialItemCount}\n'
                'Total Order: ${_money(summary.orderTotal)}\n'
                'Amount Due: ${_money(summary.orderTotal)}',
            isUser: false,
            bottomAction: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  String? code = summary.bookingCode;
                  code ??= await _findLatestBookingCode(
                    forAddOns: summary.addOnCount > 0,
                  );

                  if (!mounted) return;

                  if (code == null || code.isEmpty) {
                    debugPrint(
                      'No booking code found for add-on order. Proceeding with direct row payment.',
                    );
                  }

                  setState(() {
                    submittedOrder = SubmittedOrderSummary(
                      bookingCode: code ?? summary.bookingCode,
                      fullName: summary.fullName,
                      seatNumber: summary.seatNumber,
                      orderTotal: summary.orderTotal,
                      addOnCount: summary.addOnCount,
                      specialItemCount: summary.specialItemCount,
                      addOnRowIds: summary.addOnRowIds,
                      consignmentRowIds: summary.consignmentRowIds,
                      submittedAtIso: summary.submittedAtIso,
                    );
                  });

                  await _showPaymentDialog();
                },
                style: AddOnsStyles.primaryButton,
                child: const Text('PAY NOW'),
              ),
            ),
          ),
        ];
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    }

    if (!mounted) return;
    setState(() {
      isSubmitting = false;
    });
  }

  Future<void> _savePayment() async {
    final order = submittedOrder;
    if (order == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No submitted order found.')),
      );
      return;
    }

    final due = _round2(order.orderTotal);
    final gcashRaw = _round2(_moneyFromText(gcashController.text));
    final cashRaw = _round2(_moneyFromText(cashController.text));

    final gcash = gcashRaw > due ? due : gcashRaw;
    final remainingAfterGcash = _round2(due - gcash);
    final cash = cashRaw > remainingAfterGcash ? remainingAfterGcash : cashRaw;

    final totalPaid = _round2(gcash + cash);
    final isPaid = totalPaid >= due;
    final paidAt = isPaid ? DateTime.now().toUtc().toIso8601String() : null;
    final diff = _round2(totalPaid - due);

    try {
      setState(() {
        paymentSaving = true;
      });

      if (order.bookingCode != null && order.bookingCode!.isNotEmpty) {
        await supabase.from('customer_order_payments').upsert({
          'booking_code': order.bookingCode,
          'full_name': order.fullName,
          'seat_number': order.seatNumber,
          'order_total': _round2(
            order.addOnRowIds.isNotEmpty && order.specialItemCount == 0
                ? totalAmount
                : order.orderTotal,
          ),
          'gcash_amount': gcash,
          'cash_amount': _round2(
            cash > order.orderTotal ? order.orderTotal - gcash : cash,
          ),
          'is_paid': isPaid,
          'paid_at': paidAt,
        }, onConflict: 'booking_code');

        try {
          if (order.addOnCount > 0) {
            await supabase
                .from('customer_session_add_ons')
                .update({
                  'gcash_amount': 0,
                  'cash_amount': 0,
                  'is_paid': isPaid,
                  'paid_at': paidAt,
                })
                .inFilter('id', order.addOnRowIds);
          }

          if (order.specialItemCount > 0) {
            await supabase.rpc(
              'pay_consignment_order_by_booking_code',
              params: {
                'p_booking_code': order.bookingCode,
                'p_full_name': order.fullName,
                'p_seat_number': order.seatNumber,
                'p_order_total': order.orderTotal,
                'p_gcash_amount': gcash,
                'p_cash_amount': cash,
              },
            );
          }
        } catch (e) {
          debugPrint('order payment sync failed: $e');
        }
      } else {
        debugPrint(
          'No booking code for add-ons; using direct customer_session_add_ons update only.',
        );
      }

      bool sessionRowsUpdated = false;
      List<String> idsToUpdate = List<String>.from(order.addOnRowIds);
      List<String> consignmentIdsToUpdate = List<String>.from(
        order.consignmentRowIds,
      );

      if (idsToUpdate.isEmpty && order.addOnCount > 0) {
        idsToUpdate = await _findLatestAddOnRowIds(
          fullName: order.fullName,
          seatNumber: order.seatNumber,
          expectedTotal: order.orderTotal,
          submittedAtIso: order.submittedAtIso,
        );
        debugPrint('Re-fetched addOnRowIds: $idsToUpdate');
      }

      if (consignmentIdsToUpdate.isEmpty && order.specialItemCount > 0) {
        consignmentIdsToUpdate = await _findLatestConsignmentRowIds(
          fullName: order.fullName,
          seatNumber: order.seatNumber,
          expectedTotal: order.orderTotal,
          submittedAtIso: order.submittedAtIso,
        );
        debugPrint('Re-fetched consignmentRowIds: $consignmentIdsToUpdate');
      }
      if (isPaid && idsToUpdate.isNotEmpty) {
        final rpcRes = await supabase.rpc(
          'mark_customer_session_addons_paid',
          params: {
            'p_ids': idsToUpdate,
            'p_gcash_amount': gcash,
            'p_cash_amount': cash,
          },
        );

        debugPrint('mark_customer_session_addons_paid => $rpcRes');

        if (rpcRes is Map && rpcRes['success'] == true) {
          sessionRowsUpdated = true;
        }
      }

      if (isPaid && consignmentIdsToUpdate.isNotEmpty) {
        final consignmentRpcRes = await supabase.rpc(
          'mark_customer_session_consignment_paid',
          params: {
            'p_ids': consignmentIdsToUpdate,
            'p_gcash_amount': gcash,
            'p_cash_amount': cash,
          },
        );

        debugPrint(
          'mark_customer_session_consignment_paid => $consignmentRpcRes',
        );

        if (consignmentRpcRes is Map && consignmentRpcRes['success'] == true) {
          sessionRowsUpdated = true;
        }
      }
      if (!sessionRowsUpdated && isPaid && order.addOnCount > 0) {
        final fallbackRows = await supabase
            .from('customer_session_add_ons')
            .select('id, total, created_at')
            .eq('full_name', order.fullName)
            .eq('seat_number', order.seatNumber)
            .eq('is_paid', false)
            .order('created_at', ascending: false);

        final fallbackIds = <String>[];
        double runningTotal = 0;

        for (final row in (fallbackRows as List<dynamic>)) {
          final id = (row['id'] ?? '').toString();
          final rowTotal = _toDouble(row['total']);

          if (id.isEmpty) continue;

          fallbackIds.add(id);
          runningTotal = _round2(runningTotal + rowTotal);

          if (runningTotal >= order.orderTotal) {
            break;
          }
        }

        debugPrint('Fallback add-on idsToUpdate: $fallbackIds');

        final fallbackRpcRes = await supabase.rpc(
          'mark_customer_session_addons_paid',
          params: {
            'p_ids': fallbackIds,
            'p_gcash_amount': gcash,
            'p_cash_amount': cash,
          },
        );

        debugPrint(
          'fallback mark_customer_session_addons_paid => $fallbackRpcRes',
        );

        if (fallbackRpcRes is Map && fallbackRpcRes['success'] == true) {
          sessionRowsUpdated = true;
        }

        if (sessionRowsUpdated) {
          idsToUpdate = fallbackIds;
        }
      }

      if (!sessionRowsUpdated && isPaid && order.addOnCount > 0) {
        final exactRows = await supabase
            .from('customer_session_add_ons')
            .select('id')
            .eq('full_name', order.fullName)
            .eq('seat_number', order.seatNumber)
            .eq('is_paid', false)
            .eq('total', order.orderTotal);

        final exactIds = (exactRows as List<dynamic>)
            .map((e) => (e['id'] ?? '').toString())
            .where((e) => e.isNotEmpty)
            .toList();

        if (exactIds.isNotEmpty) {
          final exactRpcRes = await supabase.rpc(
            'mark_customer_session_addons_paid',
            params: {
              'p_ids': exactIds,
              'p_gcash_amount': gcash,
              'p_cash_amount': cash,
            },
          );

          debugPrint('exact mark_customer_session_addons_paid => $exactRpcRes');

          if (exactRpcRes is Map && exactRpcRes['success'] == true) {
            sessionRowsUpdated = true;
            idsToUpdate = exactIds;
          }
        }
      }

      if (!sessionRowsUpdated && isPaid && order.specialItemCount > 0) {
        final consignmentFallbackRows = await supabase
            .from('customer_session_consignment')
            .select('id, total, created_at')
            .eq('full_name', order.fullName)
            .eq('seat_number', order.seatNumber)
            .eq('is_paid', false)
            .eq('voided', false)
            .order('created_at', ascending: false);

        final consignmentFallbackIds = <String>[];
        double runningTotal = 0;

        for (final row in (consignmentFallbackRows as List<dynamic>)) {
          final id = (row['id'] ?? '').toString();
          final rowTotal = _toDouble(row['total']);

          if (id.isEmpty) continue;

          consignmentFallbackIds.add(id);
          runningTotal = _round2(runningTotal + rowTotal);

          if (runningTotal >= order.orderTotal) {
            break;
          }
        }

        debugPrint('Fallback consignment idsToUpdate: $consignmentFallbackIds');

        final fallbackConsignmentRpcRes = await supabase.rpc(
          'mark_customer_session_consignment_paid',
          params: {
            'p_ids': consignmentFallbackIds,
            'p_gcash_amount': gcash,
            'p_cash_amount': cash,
          },
        );

        debugPrint(
          'fallback mark_customer_session_consignment_paid => $fallbackConsignmentRpcRes',
        );

        if (fallbackConsignmentRpcRes is Map &&
            fallbackConsignmentRpcRes['success'] == true) {
          sessionRowsUpdated = true;
          consignmentIdsToUpdate = consignmentFallbackIds;
        }
      }

      if (!sessionRowsUpdated && isPaid && order.specialItemCount > 0) {
        final exactConsignmentRows = await supabase
            .from('customer_session_consignment')
            .select('id')
            .eq('full_name', order.fullName)
            .eq('seat_number', order.seatNumber)
            .eq('is_paid', false)
            .eq('voided', false)
            .eq('total', order.orderTotal);

        final exactConsignmentIds = (exactConsignmentRows as List<dynamic>)
            .map((e) => (e['id'] ?? '').toString())
            .where((e) => e.isNotEmpty)
            .toList();

        if (exactConsignmentIds.isNotEmpty) {
          final exactConsignmentRpcRes = await supabase.rpc(
            'mark_customer_session_consignment_paid',
            params: {
              'p_ids': exactConsignmentIds,
              'p_gcash_amount': gcash,
              'p_cash_amount': cash,
            },
          );

          debugPrint(
            'exact mark_customer_session_consignment_paid => $exactConsignmentRpcRes',
          );

          if (exactConsignmentRpcRes is Map &&
              exactConsignmentRpcRes['success'] == true) {
            sessionRowsUpdated = true;
            consignmentIdsToUpdate = exactConsignmentIds;
          }
        }
      }

      if (!mounted) return;

      final reallyPaid = isPaid && sessionRowsUpdated;

      setState(() {
        formLocked = false;
        submittedOrder = SubmittedOrderSummary(
          bookingCode: order.bookingCode,
          fullName: order.fullName,
          seatNumber: order.seatNumber,
          orderTotal: order.orderTotal,
          addOnCount: order.addOnCount,
          specialItemCount: order.specialItemCount,
          addOnRowIds: idsToUpdate,
          consignmentRowIds: consignmentIdsToUpdate,
          submittedAtIso: order.submittedAtIso,
        );

        chatMessages = [
          ChatMessage(
            text: reallyPaid
                ? 'Order payment successful ✅\n\n'
                      'GCash: ${_money(gcash)}\n'
                      'Cash: ${_money(cash)}\n'
                      'Total Paid: ${_money(totalPaid)}\n'
                      'Change: ${_money(diff < 0 ? 0 : diff)}\n'
                      'Status: PAID\n\n'
                      'Thank you! 😊'
                : 'Payment saved but the order row was not marked paid yet ⚠️\n\n'
                      'GCash: ${_money(gcash)}\n'
                      'Cash: ${_money(cash)}\n'
                      'Total Paid: ${_money(totalPaid)}\n'
                      'Status: ${isPaid ? "SHOULD BE PAID" : "UNPAID"}\n\n'
                      'Please check the exact row ids / booking code.',
            isUser: false,
          ),
        ];
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save payment failed: $e')));
    } finally {
      if (mounted) {
        setState(() {
          paymentSaving = false;
        });
      }
    }
  }

  Future<void> _showPaymentDialog() async {
    final order = submittedOrder;
    if (order == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: !paymentSaving,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final due = _round2(order.orderTotal);
            final g = _round2(_moneyFromText(gcashController.text));
            final c = _round2(_moneyFromText(cashController.text));
            final totalPaid = _round2(g + c);
            final diff = _round2(totalPaid - due);
            final isPaidAuto = totalPaid >= due;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              child: Center(
                child: Container(
                  width: 420,
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.all(18),
                  decoration: AddOnsStyles.modalCard,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('PAYMENT', style: AddOnsStyles.title),
                      const SizedBox(height: 6),
                      Text(order.fullName, style: AddOnsStyles.subtitle),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AddOnsStyles.formCard,
                        child: Column(
                          children: [
                            _paymentLine('Payment Due', _money(due)),
                            const SizedBox(height: 12),
                            TextField(
                              controller: gcashController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: AddOnsStyles.inputDecoration(
                                hintText: 'GCash',
                              ).copyWith(labelText: 'GCash'),
                              onChanged: (_) => setModalState(() {}),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: cashController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: AddOnsStyles.inputDecoration(
                                hintText: 'Cash',
                              ).copyWith(labelText: 'Cash'),
                              onChanged: (_) => setModalState(() {}),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: AddOnsStyles.formCard,
                        child: Column(
                          children: [
                            _paymentLine('Total Paid', _money(totalPaid)),
                            const SizedBox(height: 8),
                            _paymentLine(
                              diff >= 0 ? 'Change' : 'Remaining',
                              _money(diff >= 0 ? diff : diff.abs()),
                            ),
                            const SizedBox(height: 8),
                            _paymentLine(
                              'Auto Status',
                              isPaidAuto ? 'PAID' : 'UNPAID',
                              valueColor: isPaidAuto
                                  ? AddOnsStyles.primaryDark
                                  : Colors.deepOrange,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: paymentSaving
                                  ? null
                                  : () => Navigator.pop(context),
                              style: AddOnsStyles.secondaryButton,
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: paymentSaving
                                  ? null
                                  : () async {
                                      Navigator.pop(context);
                                      await _savePayment();
                                    },
                              style: AddOnsStyles.primaryButton,
                              child: Text(paymentSaving ? 'Saving...' : 'Save'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _paymentLine(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AddOnsStyles.mutedText)),
        Text(
          value,
          style: AddOnsStyles.sectionTitle.copyWith(
            color: valueColor ?? AddOnsStyles.textDark,
          ),
        ),
      ],
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 360,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
      );
    });
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

  Widget buildAiBubble({
    required String text,
    bool showAvatar = true,
    Widget? bottomAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[buildLogo(38), const SizedBox(width: 8)],
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: AddOnsStyles.aiBubble,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(text, style: AddOnsStyles.aiText),
                  if (bottomAction != null) ...[
                    const SizedBox(height: 12),
                    bottomAction,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSuccessBubble(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: AddOnsStyles.successBubble,
              child: Text(text, style: AddOnsStyles.successText),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildField({
    required String label,
    required String valueText,
    required VoidCallback onTap,
    String? emptyText,
    IconData? icon,
  }) {
    final hasValue = valueText.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AddOnsStyles.label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: formLocked ? null : onTap,
          child: InputDecorator(
            decoration: AddOnsStyles.inputDecoration(
              hintText: hasValue ? valueText : (emptyText ?? 'Select $label'),
              suffixIcon: Icon(icon ?? Icons.keyboard_arrow_down_rounded),
            ),
            child: hasValue
                ? Text(
                    valueText == 'SPECIAL ITEM'
                        ? 'SPECIAL ITEM !!!'
                        : valueText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: valueText == 'SPECIAL ITEM'
                          ? Colors.orangeAccent
                          : AddOnsStyles.textDark,
                      shadows: valueText == 'SPECIAL ITEM'
                          ? [
                              Shadow(
                                color: Colors.orange.withOpacity(0.8),
                                blurRadius: 10,
                              ),
                              Shadow(
                                color: Colors.deepOrange.withOpacity(0.6),
                                blurRadius: 18,
                              ),
                            ]
                          : [],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget buildOrderRowCard(int index, bool isMobile) {
    final row = orderRows[index];
    final item = row.item;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: AddOnsStyles.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Order ${index + 1}',
                  style: AddOnsStyles.sectionTitle,
                ),
              ),
              if (orderRows.length > 1)
                SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: formLocked
                        ? null
                        : () {
                            setState(() {
                              orderRows.removeAt(index);
                            });
                          },
                    style: AddOnsStyles.dangerButton,
                    child: const Text('Remove'),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          buildField(
            label: 'Category',
            valueText: row.category ?? '',
            emptyText: 'Choose category',
            onTap: formLocked ? () {} : () => pickCategory(index),
          ),
          const SizedBox(height: 14),
          buildField(
            label: 'Item',
            valueText: item == null
                ? ''
                : item.size == null || item.size!.trim().isEmpty
                ? item.name
                : '${item.name} (${item.size})',
            emptyText: 'Choose item',
            icon: Icons.inventory_2_rounded,
            onTap: formLocked ? () {} : () => pickItem(index),
          ),
          if (item != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AddOnsStyles.formCard,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: AddOnsStyles.imageBox,
                    clipBehavior: Clip.antiAlias,
                    child:
                        item.imageUrl != null &&
                            item.imageUrl!.trim().isNotEmpty
                        ? Image.network(
                            item.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) {
                              return const Icon(
                                Icons.image_not_supported_outlined,
                              );
                            },
                          )
                        : const Icon(Icons.image_outlined, size: 34),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: AddOnsStyles.sectionTitle),
                        if (item.size != null &&
                            item.size!.trim().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${item.size}',
                            style: AddOnsStyles.mutedText,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Remaining: ${item.stocks}',
                          style: AddOnsStyles.mutedText,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₱${item.price.toStringAsFixed(2)}',
                          style: AddOnsStyles.priceText,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('Qty', style: AddOnsStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: formLocked
                        ? null
                        : () => changeQty(index, row.quantity - 1),
                    style: AddOnsStyles.secondaryButton,
                    child: const Icon(Icons.remove),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: AddOnsStyles.formCard,
                    child: Text(
                      '${row.quantity}',
                      style: AddOnsStyles.sectionTitle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: formLocked
                        ? null
                        : () => changeQty(index, row.quantity + 1),
                    style: AddOnsStyles.primaryButton,
                    child: const Icon(Icons.add),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: AddOnsStyles.formCard,
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Sub Total',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AddOnsStyles.textDark,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '₱${row.subtotal.toStringAsFixed(2)}',
                    style: AddOnsStyles.priceText,
                  ),
                ],
              ),
            ),
          ],
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
        ? 500
        : 600;

    final double modalHeight = isMobile
        ? screen.height * 0.92
        : isTablet
        ? 500
        : 620;

    return Scaffold(
      backgroundColor: AddOnsStyles.pageBg,
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
                decoration: AddOnsStyles.modalCard,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: AddOnsStyles.headerCard,
                      child: Row(
                        children: [
                          buildLogo(isMobile ? 42 : 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add-Ons Assistant',
                                  style: AddOnsStyles.title,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please complete the order details below.',
                                  style: AddOnsStyles.subtitle,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: AddOnsStyles.statusChip,
                            child: Text('Order', style: AddOnsStyles.chipText),
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
                        decoration: AddOnsStyles.chatArea,
                        child: isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView(
                                controller: scrollController,
                                children: [
                                  buildSuccessBubble('You selected Add-Ons 🍔'),
                                  buildAiBubble(
                                    text:
                                        'Please fill up the order details below.',
                                  ),

                                  if (showForm) ...[
                                    const SizedBox(height: 8),
                                    AnimatedOpacity(
                                      duration: const Duration(
                                        milliseconds: 350,
                                      ),
                                      opacity: 1,
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          isMobile ? 14 : 18,
                                        ),
                                        decoration: AddOnsStyles.formCard,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Order Information',
                                              style: AddOnsStyles.sectionTitle,
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              'Full Name',
                                              style: AddOnsStyles.label,
                                            ),
                                            const SizedBox(height: 8),
                                            TextField(
                                              controller: fullNameController,
                                              enabled: !formLocked,
                                              decoration:
                                                  AddOnsStyles.inputDecoration(
                                                    hintText: 'Enter full name',
                                                  ),
                                            ),
                                            const SizedBox(height: 14),
                                            buildField(
                                              label: 'Seat Number',
                                              valueText: selectedSeat ?? '',
                                              emptyText: 'Pick seat number',
                                              icon: Icons.event_seat_rounded,
                                              onTap: pickSeat,
                                            ),
                                            const SizedBox(height: 16),
                                            ...List.generate(
                                              orderRows.length,
                                              (index) => buildOrderRowCard(
                                                index,
                                                isMobile,
                                              ),
                                            ),
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.all(16),
                                              decoration: AddOnsStyles.formCard,
                                              child: Row(
                                                children: [
                                                  const Expanded(
                                                    child: Text(
                                                      'Total',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: AddOnsStyles
                                                            .textDark,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '₱${totalAmount.toStringAsFixed(2)}',
                                                    style: AddOnsStyles
                                                        .priceText
                                                        .copyWith(fontSize: 16),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: formLocked
                                                        ? null
                                                        : addMoreOrder,
                                                    style: AddOnsStyles
                                                        .secondaryButton,
                                                    child: const Text(
                                                      'ADD MORE ORDER',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed:
                                                        (isSubmitting ||
                                                            formLocked)
                                                        ? null
                                                        : submitOrder,
                                                    style: AddOnsStyles
                                                        .primaryButton,
                                                    child: Text(
                                                      isSubmitting
                                                          ? 'Submitting...'
                                                          : 'SUBMIT ORDER',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: resetOrder,
                                                    style: AddOnsStyles
                                                        .dangerButton,
                                                    child: const Text(
                                                      'RESET ORDER',
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  for (final msg in chatMessages)
                                    msg.isUser
                                        ? buildSuccessBubble(msg.text)
                                        : buildAiBubble(
                                            text: msg.text,
                                            showAvatar: msg.showAvatar,
                                            bottomAction: msg.bottomAction,
                                          ),
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
                            style: AddOnsStyles.secondaryButton,
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

class _SheetOption<T> {
  final String label;
  final T value;

  const _SheetOption({required this.label, required this.value});
}

class _SelectionSheet<T> extends StatelessWidget {
  final String title;
  final List<_SheetOption<T>> items;

  const _SelectionSheet({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final maxHeight = media.size.height * 0.72;

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AddOnsStyles.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AddOnsStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => Navigator.pop(context, item.value),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ),
                          child: Text(
                            item.label == 'SPECIAL ITEM'
                                ? 'SPECIAL ITEM !!!'
                                : item.label,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: item.label == 'SPECIAL ITEM'
                                  ? Colors.orangeAccent
                                  : AddOnsStyles.textDark,
                              shadows: item.label == 'SPECIAL ITEM'
                                  ? [
                                      Shadow(
                                        color: Colors.orange.withOpacity(0.9),
                                        blurRadius: 12,
                                      ),
                                      Shadow(
                                        color: Colors.deepOrange.withOpacity(
                                          0.7,
                                        ),
                                        blurRadius: 22,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeatPickerSheet extends StatefulWidget {
  final Map<String, List<String>> seatGroups;
  final String? selectedSeat;

  const _SeatPickerSheet({
    required this.seatGroups,
    required this.selectedSeat,
  });

  @override
  State<_SeatPickerSheet> createState() => _SeatPickerSheetState();
}

class _SeatPickerSheetState extends State<_SeatPickerSheet> {
  String? selected;

  @override
  void initState() {
    super.initState();
    selected = widget.selectedSeat;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: AddOnsStyles.cardBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Select Seat',
              style: AddOnsStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: widget.seatGroups.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: AddOnsStyles.seatPanel,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key, style: AddOnsStyles.seatGroupTitle),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: entry.value.map((seat) {
                              final isSelected = selected == seat;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selected = seat;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                  decoration: isSelected
                                      ? AddOnsStyles.selectedSeatBox
                                      : AddOnsStyles.seatBox,
                                  child: Text(
                                    seat,
                                    style: isSelected
                                        ? AddOnsStyles.selectedSeatText
                                        : AddOnsStyles.seatText,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: AddOnsStyles.secondaryButton,
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selected == null
                        ? null
                        : () => Navigator.pop(context, selected),
                    style: AddOnsStyles.primaryButton,
                    child: const Text('Select'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemPickerSheet extends StatelessWidget {
  final String title;
  final List<CatalogItem> items;

  const _ItemPickerSheet({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: AddOnsStyles.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: AddOnsStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 14),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.pop(context, item),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: AddOnsStyles.formCard,
                      child: Row(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: AddOnsStyles.imageBox,
                            clipBehavior: Clip.antiAlias,
                            child:
                                item.imageUrl != null &&
                                    item.imageUrl!.trim().isNotEmpty
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image_outlined),
                                  )
                                : const Icon(Icons.image_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: AddOnsStyles.sectionTitle,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.size == null || item.size!.trim().isEmpty
                                      ? item.category
                                      : '${item.category} • ${item.size}',
                                  style: AddOnsStyles.mutedText,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Stocks: ${item.stocks}',
                                  style: AddOnsStyles.mutedText,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '₱${item.price.toStringAsFixed(2)}',
                            style: AddOnsStyles.priceText,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
