import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'styles/Add_Ons_styles.dart';

enum CatalogKind { addOn, consignment }

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

enum VerifiedSourceKind { session, promo }

class VerifiedCustomerData {
  final VerifiedSourceKind kind;
  final String code;
  final String fullName;
  final String phoneNumber;
  final String? message;

  const VerifiedCustomerData({
    required this.kind,
    required this.code,
    required this.fullName,
    required this.phoneNumber,
    this.message,
  });
}

class AddOnsPage extends StatefulWidget {
  const AddOnsPage({super.key});

  @override
  State<AddOnsPage> createState() => _AddOnsPageState();
}

class _AddOnsPageState extends State<AddOnsPage> with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;

  final TextEditingController codeController = TextEditingController();
  final ScrollController scrollController = ScrollController();

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
  };

  bool isLoading = true;
  bool isSubmitting = false;
  bool isVerifying = false;
  bool isVerified = false;
  bool submitted = false;

  VerifiedCustomerData? verifiedCustomer;
  String? selectedSeatNumber;

  List<CatalogItem> addOnItems = <CatalogItem>[];
  List<CatalogItem> consignmentItems = <CatalogItem>[];
  List<OrderRowData> orderRows = <OrderRowData>[OrderRowData()];

  late final AnimationController pageController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;

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
  }

  @override
  void dispose() {
    codeController.dispose();
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  String get normalizedCode => codeController.text.trim().toUpperCase();

  double get totalAmount {
    return orderRows.fold<double>(0, (double sum, OrderRowData row) {
      return sum + row.subtotal;
    });
  }

  List<String> get allSeatNumbers {
    final List<String> seats = <String>[];
    for (final List<String> groupSeats in seatGroups.values) {
      seats.addAll(groupSeats);
    }
    return seats;
  }

  List<String> get categories {
    final Set<String> values = <String>{};

    for (final CatalogItem item in addOnItems) {
      final String category = item.category.trim();
      if (category.isNotEmpty) {
        values.add(category);
      }
    }

    if (consignmentItems.isNotEmpty) {
      values.add('SPECIAL ITEM');
    }

    final List<String> list = values.toList()
      ..sort((String a, String b) => a.compareTo(b));
    return list;
  }

  bool get isValidOrder {
    if (!isVerified || verifiedCustomer == null) return false;
    if ((selectedSeatNumber ?? '').trim().isEmpty) return false;
    if (orderRows.isEmpty) return false;

    for (final OrderRowData row in orderRows) {
      if ((row.category ?? '').trim().isEmpty) return false;
      if (row.item == null) return false;
      if (row.quantity <= 0) return false;

      final int maxQty = maxQtyForRow(row);
      if (row.quantity > maxQty) return false;
    }

    return true;
  }

  Future<void> _loadCatalog() async {
    setState(() {
      isLoading = true;
    });

    try {
      final List<dynamic> addOnsResponse = await supabase
          .from('add_ons')
          .select('id, category, name, price, image_url, stocks, size')
          .gt('stocks', 0)
          .order('category')
          .order('name');

      final List<dynamic> consignmentResponse = await supabase
          .from('consignment')
          .select(
            'id, item_name, price, image_url, stocks, size, approval_status',
          )
          .eq('approval_status', 'approved')
          .gt('stocks', 0)
          .order('item_name');

      addOnItems = addOnsResponse.map((dynamic row) {
        return CatalogItem(
          id: (row['id'] ?? '').toString(),
          kind: CatalogKind.addOn,
          category: (row['category'] ?? '').toString(),
          name: (row['name'] ?? '').toString(),
          price: _toDouble(row['price']),
          stocks: _toInt(row['stocks']),
          size: row['size']?.toString(),
          imageUrl: row['image_url']?.toString(),
        );
      }).toList();

      consignmentItems = consignmentResponse.map((dynamic row) {
        return CatalogItem(
          id: (row['id'] ?? '').toString(),
          kind: CatalogKind.consignment,
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
      _showSnack('Failed to load items: $e');
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

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _friendlyRpcError(Object error) {
    final String raw = error.toString();

    if (error is PostgrestException) {
      final String msg = (error.message).trim();

      if (msg.contains('consignment_notifications')) {
        return 'Consignment notification setup is incomplete. Check your public.consignment_notifications table and place_consignment_order function.';
      }

      if (msg.contains('add_on_notifications')) {
        return 'Add-on notification setup is incomplete. Check your public.add_on_notifications table and place_addon_order function.';
      }

      if (msg.contains('place_consignment_order')) {
        return 'place_consignment_order function needs updating.';
      }

      if (msg.contains('place_addon_order')) {
        return 'place_addon_order function needs updating.';
      }

      return msg.isNotEmpty ? msg : raw;
    }

    return raw;
  }

  List<CatalogItem> itemsForCategory(String category) {
    if (category == 'SPECIAL ITEM') {
      return consignmentItems;
    }
    return addOnItems.where((CatalogItem e) => e.category == category).toList();
  }

  int usedQtyForItem(String itemId, {OrderRowData? excluding}) {
    int total = 0;

    for (final OrderRowData row in orderRows) {
      if (excluding != null && identical(row, excluding)) continue;
      if (row.item?.id == itemId) {
        total += row.quantity;
      }
    }

    return total;
  }

  int maxQtyForItem(CatalogItem item, {OrderRowData? excluding}) {
    final int usedByOthers = usedQtyForItem(item.id, excluding: excluding);
    final int remaining = item.stocks - usedByOthers;
    return remaining < 0 ? 0 : remaining;
  }

  int maxQtyForRow(OrderRowData row) {
    final CatalogItem? item = row.item;
    if (item == null) return 0;
    return maxQtyForItem(item, excluding: row);
  }

  int remainingAfterCurrentSelection(OrderRowData row) {
    final CatalogItem? item = row.item;
    if (item == null) return 0;

    final int maxQty = maxQtyForRow(row);
    final int remaining = maxQty - row.quantity;
    return remaining < 0 ? 0 : remaining;
  }

  void normalizeRowQuantities() {
    for (final OrderRowData row in orderRows) {
      if (row.item == null) continue;

      final int maxQty = maxQtyForRow(row);

      if (maxQty <= 0) {
        row.quantity = 1;
        row.item = null;
        continue;
      }

      if (row.quantity > maxQty) {
        row.quantity = maxQty;
      }

      if (row.quantity < 1) {
        row.quantity = 1;
      }
    }
  }

  Future<void> verifyCode() async {
    final String code = normalizedCode;

    if (code.isEmpty) {
      _showSnack('Please enter your code first.');
      return;
    }

    setState(() {
      isVerifying = true;
      submitted = false;
    });

    try {
      final DateTime now = DateTime.now();

      final Map<String, dynamic>? sessionRow = await supabase
          .from('customer_sessions')
          .select(
            'id, full_name, phone_number, booking_code, time_started, time_ended, reservation, reservation_date, reservation_end_date',
          )
          .eq('booking_code', code)
          .limit(1)
          .maybeSingle();

      if (sessionRow != null) {
        final String fullName = (sessionRow['full_name'] ?? '')
            .toString()
            .trim();
        final String phoneNumber = (sessionRow['phone_number'] ?? '')
            .toString()
            .trim();

        final DateTime? startAt = DateTime.tryParse(
          (sessionRow['time_started'] ?? '').toString(),
        );
        final DateTime? endAt = DateTime.tryParse(
          (sessionRow['time_ended'] ?? '').toString(),
        );

        bool isActive = false;

        if (startAt != null) {
          if (endAt == null) {
            isActive = !now.isBefore(startAt);
          } else {
            isActive = !now.isBefore(startAt) && now.isBefore(endAt);
          }
        }

        if (!isActive) {
          if (!mounted) return;
          setState(() {
            isVerified = false;
            verifiedCustomer = null;
            selectedSeatNumber = null;
          });
          _showSnack('This booking code is not active right now.');
          return;
        }

        final VerifiedCustomerData verified = VerifiedCustomerData(
          kind: VerifiedSourceKind.session,
          code: code,
          fullName: fullName,
          phoneNumber: phoneNumber,
          message: 'Hi $fullName, you can order now.',
        );

        if (!mounted) return;
        setState(() {
          isVerified = true;
          verifiedCustomer = verified;
          selectedSeatNumber = null;
          orderRows = <OrderRowData>[OrderRowData()];
        });
        _scrollToBottom();
        return;
      }

      final Map<String, dynamic>? promoRow = await supabase
          .from('promo_bookings')
          .select(
            'id, full_name, phone_number, promo_code, start_at, end_at, status',
          )
          .eq('promo_code', code)
          .limit(1)
          .maybeSingle();

      if (promoRow != null) {
        final String fullName = (promoRow['full_name'] ?? '').toString().trim();
        final String phoneNumber = (promoRow['phone_number'] ?? '')
            .toString()
            .trim();

        final DateTime? startAt = DateTime.tryParse(
          (promoRow['start_at'] ?? '').toString(),
        );
        final DateTime? endAt = DateTime.tryParse(
          (promoRow['end_at'] ?? '').toString(),
        );

        bool isActive = false;
        if (startAt != null && endAt != null) {
          isActive = !now.isBefore(startAt) && now.isBefore(endAt);
        }

        if (!isActive) {
          if (!mounted) return;
          setState(() {
            isVerified = false;
            verifiedCustomer = null;
            selectedSeatNumber = null;
          });
          _showSnack('This promo code is not active right now.');
          return;
        }

        final VerifiedCustomerData verified = VerifiedCustomerData(
          kind: VerifiedSourceKind.promo,
          code: code,
          fullName: fullName,
          phoneNumber: phoneNumber,
          message: 'Hi $fullName, you can order now.',
        );

        if (!mounted) return;
        setState(() {
          isVerified = true;
          verifiedCustomer = verified;
          selectedSeatNumber = null;
          orderRows = <OrderRowData>[OrderRowData()];
        });
        _scrollToBottom();
        return;
      }

      if (!mounted) return;
      setState(() {
        isVerified = false;
        verifiedCustomer = null;
        selectedSeatNumber = null;
      });
      _showSnack(
        'Code not found. Please enter a valid walk-in, reservation, or promo code.',
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Code verification failed: ${_friendlyRpcError(e)}');
    } finally {
      if (!mounted) return;
      setState(() {
        isVerifying = false;
      });
    }
  }

  void clearVerifiedState() {
    setState(() {
      isVerified = false;
      submitted = false;
      verifiedCustomer = null;
      selectedSeatNumber = null;
      orderRows = <OrderRowData>[OrderRowData()];
    });
  }

  Future<void> pickCategory(int index) async {
    if (categories.isEmpty) {
      _showSnack('No available categories right now.');
      return;
    }

    final String? result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _SelectionSheet<String>(
          title: 'Select Category',
          items: categories
              .map((String e) => _SheetOption<String>(label: e, value: e))
              .toList(),
        );
      },
    );

    if (result != null) {
      setState(() {
        orderRows[index].category = result;
        orderRows[index].item = null;
        orderRows[index].quantity = 1;
      });
    }
  }

  Future<void> pickItem(int index) async {
    final String? category = orderRows[index].category;

    if (category == null || category.isEmpty) {
      _showSnack('Select category first.');
      return;
    }

    final List<CatalogItem> items = itemsForCategory(category);

    if (items.isEmpty) {
      _showSnack('No available items in this category right now.');
      return;
    }

    final CatalogItem? result = await showModalBottomSheet<CatalogItem>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _ItemPickerSheet(
          title: category == 'SPECIAL ITEM'
              ? 'Choose Special Item'
              : 'Choose Add-On',
          items: items,
          remainingBuilder: (CatalogItem item) =>
              maxQtyForItem(item, excluding: orderRows[index]),
        );
      },
    );

    if (result != null) {
      final int maxQty = maxQtyForItem(result, excluding: orderRows[index]);

      if (maxQty <= 0) {
        _showSnack('That item is already fully allocated in your order.');
        return;
      }

      setState(() {
        orderRows[index].item = result;
        orderRows[index].quantity = 1;
        normalizeRowQuantities();
      });
    }
  }

  void changeQty(int index, int nextQty) {
    final CatalogItem? currentItem = orderRows[index].item;
    if (currentItem == null) return;

    final int maxQty = maxQtyForRow(orderRows[index]);

    int finalQty = nextQty;
    if (finalQty < 1) finalQty = 1;
    if (finalQty > maxQty) finalQty = maxQty;

    setState(() {
      orderRows[index].quantity = finalQty;
      normalizeRowQuantities();
    });
  }

  void addMoreOrder() {
    setState(() {
      submitted = false;
      orderRows.add(OrderRowData());
      normalizeRowQuantities();
    });
    _scrollToBottom();
  }

  void resetOrder() {
    setState(() {
      selectedSeatNumber = null;
      orderRows = <OrderRowData>[OrderRowData()];
      submitted = false;
    });
  }

  Future<void> submitOrder() async {
    if (!isValidOrder || verifiedCustomer == null) {
      _showSnack('Please complete your order first.');
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final List<Map<String, dynamic>> addOnPayload = [];
      final List<Map<String, dynamic>> consignmentPayload = [];

      for (final OrderRowData row in orderRows) {
        final CatalogItem? item = row.item;
        if (item == null) continue;

        if (item.kind == CatalogKind.addOn) {
          addOnPayload.add({'add_on_id': item.id, 'quantity': row.quantity});
        } else {
          consignmentPayload.add({
            'consignment_id': item.id,
            'quantity': row.quantity,
          });
        }
      }

      final String fullName = verifiedCustomer!.fullName;
      final String seatNumber = selectedSeatNumber!.trim();
      final String bookingCode = verifiedCustomer!.code;

      if (addOnPayload.isNotEmpty) {
        await supabase.rpc(
          'place_addon_order',
          params: {
            'p_full_name': fullName,
            'p_seat_number': seatNumber,
            'p_booking_code': bookingCode,
            'p_items': addOnPayload,
          },
        );
      }

      if (consignmentPayload.isNotEmpty) {
        await supabase.rpc(
          'place_consignment_order',
          params: {
            'p_full_name': fullName,
            'p_seat_number': seatNumber,
            'p_booking_code': bookingCode,
            'p_items': consignmentPayload,
          },
        );
      }

      await _loadCatalog();

      if (!mounted) return;

      setState(() {
        submitted = true;
        orderRows = <OrderRowData>[OrderRowData()];
      });

      _showSnack('Order submitted successfully!');
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Submit failed: ${_friendlyRpcError(e)}');
    } finally {
      if (!mounted) return;
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 260,
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
        boxShadow: <BoxShadow>[
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
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
                return const Icon(Icons.image_not_supported_outlined);
              },
        ),
      ),
    );
  }

  Widget buildAiBubble({required String text, bool showAvatar = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showAvatar) ...<Widget>[buildLogo(38), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: AddOnsStyles.aiBubble,
              child: Text(text, style: AddOnsStyles.aiText),
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
        children: <Widget>[
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
    final bool hasValue = valueText.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: AddOnsStyles.label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: InputDecorator(
            decoration: AddOnsStyles.inputDecoration(
              hintText: hasValue ? valueText : (emptyText ?? 'Select $label'),
              suffixIcon: Icon(icon ?? Icons.keyboard_arrow_down_rounded),
            ),
            child: hasValue
                ? Text(
                    valueText,
                    style: const TextStyle(
                      color: AddOnsStyles.textDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget buildSeatDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Seat Number', style: AddOnsStyles.label),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedSeatNumber,
          isExpanded: true,
          decoration: AddOnsStyles.inputDecoration(
            hintText: 'Select seat number',
            suffixIcon: const Icon(Icons.event_seat_rounded),
          ),
          items: seatGroups.entries.expand((entry) {
            final String group = entry.key;
            final List<String> seats = entry.value;

            return seats.map((seat) {
              return DropdownMenuItem<String>(
                value: seat,
                child: Text('$group - $seat'),
              );
            });
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              selectedSeatNumber = value;
            });
          },
        ),
      ],
    );
  }

  Widget buildInfoLockedCard() {
    final VerifiedCustomerData? customer = verifiedCustomer;
    if (customer == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AddOnsStyles.infoCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.verified_rounded,
                color: AddOnsStyles.primaryDark,
              ),
              const SizedBox(width: 8),
              Text('Verified Customer', style: AddOnsStyles.sectionTitle),
            ],
          ),
          const SizedBox(height: 14),
          _infoRow('Code', customer.code),
          const SizedBox(height: 10),
          _infoRow('Full Name', customer.fullName),
          const SizedBox(height: 10),
          _infoRow(
            'Phone Number',
            customer.phoneNumber.trim().isEmpty ? '-' : customer.phoneNumber,
          ),
          const SizedBox(height: 14),
          buildSeatDropdown(),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: AddOnsStyles.infoInnerCard,
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AddOnsStyles.mutedText.copyWith(
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
                color: AddOnsStyles.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildOrderRowCard(int index, bool isMobile) {
    final OrderRowData row = orderRows[index];
    final CatalogItem? item = row.item;
    final int maxQty = item == null ? 0 : maxQtyForRow(row);
    final int remaining = item == null
        ? 0
        : remainingAfterCurrentSelection(row);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: AddOnsStyles.sectionCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
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
                    onPressed: () {
                      setState(() {
                        orderRows.removeAt(index);
                        normalizeRowQuantities();
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
            onTap: () => pickCategory(index),
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
            onTap: () => pickItem(index),
          ),
          if (item != null) ...<Widget>[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: AddOnsStyles.formCard,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                      children: <Widget>[
                        Text(item.name, style: AddOnsStyles.sectionTitle),
                        if (item.size != null &&
                            item.size!.trim().isNotEmpty) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            'Size: ${item.size}',
                            style: AddOnsStyles.mutedText,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          'Remaining: $remaining',
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
              children: <Widget>[
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: row.quantity <= 1
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
                    onPressed: row.quantity >= maxQty
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
                children: <Widget>[
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

  Widget buildVerificationCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: AddOnsStyles.formCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Enter Code', style: AddOnsStyles.sectionTitle),
          const SizedBox(height: 14),
          Text(
            'Use your walk-in, reservation, or promo code.',
            style: AddOnsStyles.mutedText,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AddOnsStyles.textDark,
              letterSpacing: 1.2,
            ),
            onChanged: (_) {
              if (isVerified) {
                clearVerifiedState();
              }
              setState(() {});
            },
            decoration: AddOnsStyles.inputDecoration(
              hintText: 'Enter your code',
              suffixIcon: const Icon(Icons.qr_code_2_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: isVerifying ? null : verifyCode,
                  style: AddOnsStyles.primaryButton,
                  child: Text(isVerifying ? 'VERIFYING...' : 'VERIFY CODE'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildOrderForm(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: AddOnsStyles.formCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Add-Ons / Special Item Form', style: AddOnsStyles.sectionTitle),
          const SizedBox(height: 14),
          buildInfoLockedCard(),
          const SizedBox(height: 16),
          ...List<Widget>.generate(
            orderRows.length,
            (int index) => buildOrderRowCard(index, isMobile),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: AddOnsStyles.totalCard,
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AddOnsStyles.textDark,
                    ),
                  ),
                ),
                Text(
                  '₱${totalAmount.toStringAsFixed(2)}',
                  style: AddOnsStyles.priceText.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: addMoreOrder,
                  style: AddOnsStyles.secondaryButton,
                  child: const Text('ADD MORE ORDER'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitOrder,
                  style: AddOnsStyles.primaryButton,
                  child: Text(isSubmitting ? 'SUBMITTING...' : 'SUBMIT ORDER'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: resetOrder,
                  style: AddOnsStyles.dangerButton,
                  child: const Text('RESET ORDER'),
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

    final String successName = verifiedCustomer?.fullName ?? 'Customer';

    return PopScope(
      canPop: false,
      child: Scaffold(
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
                    children: <Widget>[
                      Container(
                        padding: EdgeInsets.all(isMobile ? 12 : 16),
                        decoration: AddOnsStyles.headerCard,
                        child: Row(
                          children: <Widget>[
                            buildLogo(isMobile ? 42 : 48),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Add-Ons / Special Item Assistant',
                                    style: AddOnsStyles.title,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Code first, then order your add-ons or special items.',
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
                              child: Text(
                                'AI ORDER',
                                style: AddOnsStyles.chipText,
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
                          decoration: AddOnsStyles.chatArea,
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : ListView(
                                  controller: scrollController,
                                  children: <Widget>[
                                    buildUserBubble(
                                      'I want to order add-ons or special items.',
                                    ),
                                    buildAiBubble(
                                      text:
                                          'Hello! Please enter your walk-in, reservation, or promo code first so I can verify your account.',
                                    ),
                                    const SizedBox(height: 8),
                                    buildVerificationCard(isMobile),
                                    if (isVerified &&
                                        verifiedCustomer != null) ...<Widget>[
                                      const SizedBox(height: 12),
                                      buildAiBubble(
                                        text:
                                            verifiedCustomer!.message ??
                                            'You can order now.',
                                      ),
                                      const SizedBox(height: 8),
                                      buildOrderForm(isMobile),
                                    ],
                                    if (submitted) ...<Widget>[
                                      const SizedBox(height: 12),
                                      buildAiBubble(
                                        text:
                                            'Your order, $successName, was successful.',
                                      ),

                                      buildAiBubble(
                                        text:
                                            'We’ll notify you via beeper or message once your order is ready.',
                                        showAvatar: true,
                                      ),

                                      buildAiBubble(
                                        text:
                                            'You may then proceed to the counter for pickup and payment.',
                                        showAvatar: true,
                                      ),

                                      buildAiBubble(
                                        text: 'Thank you! 😊',
                                        showAvatar: true,
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
    final MediaQueryData media = MediaQuery.of(context);
    final double maxHeight = media.size.height * 0.72;

    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: AddOnsStyles.cardBg,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
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
          children: <Widget>[
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
                            item.label,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: AddOnsStyles.textDark,
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

class _ItemPickerSheet extends StatefulWidget {
  final String title;
  final List<CatalogItem> items;
  final int Function(CatalogItem item) remainingBuilder;

  const _ItemPickerSheet({
    required this.title,
    required this.items,
    required this.remainingBuilder,
  });

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<CatalogItem> get filteredItems {
    final String q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.items;

    return widget.items.where((CatalogItem e) {
      return e.name.toLowerCase().contains(q) ||
          (e.size ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: AddOnsStyles.cardBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 680,
          child: Column(
            children: <Widget>[
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text(widget.title, style: AddOnsStyles.sectionTitle),
              const SizedBox(height: 14),
              TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                decoration: AddOnsStyles.inputDecoration(
                  hintText: 'Search item...',
                  suffixIcon: const Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: filteredItems.isEmpty
                    ? const Center(child: Text('No available items.'))
                    : ListView.separated(
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (BuildContext context, int index) {
                          final CatalogItem item = filteredItems[index];
                          final int remaining = widget.remainingBuilder(item);

                          return Opacity(
                            opacity: remaining <= 0 ? 0.45 : 1,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: remaining <= 0
                                  ? null
                                  : () => Navigator.pop(context, item),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: AddOnsStyles.sectionCard,
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 64,
                                      height: 64,
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
                                                  Icons
                                                      .image_not_supported_outlined,
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.image_outlined,
                                              size: 30,
                                            ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            item.name,
                                            style: AddOnsStyles.sectionTitle,
                                          ),
                                          if (item.size != null &&
                                              item.size!
                                                  .trim()
                                                  .isNotEmpty) ...<Widget>[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Size: ${item.size}',
                                              style: AddOnsStyles.mutedText,
                                            ),
                                          ],
                                          const SizedBox(height: 4),
                                          Text(
                                            'Remaining: $remaining',
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
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
