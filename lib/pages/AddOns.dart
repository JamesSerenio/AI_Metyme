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

class AddOnsPage extends StatefulWidget {
  const AddOnsPage({super.key});

  @override
  State<AddOnsPage> createState() => _AddOnsPageState();
}

class _AddOnsPageState extends State<AddOnsPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final TextEditingController fullNameController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String? selectedSeat;
  bool isLoading = true;
  bool isSubmitting = false;
  bool showForm = false;
  bool submitted = false;

  List<CatalogItem> addOnItems = [];
  List<CatalogItem> otherItems = [];
  List<OrderRowData> orderRows = [OrderRowData()];

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
      submitted = false;
    });
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

      if (addOnPayload.isNotEmpty) {
        await supabase.rpc(
          'place_addon_order', // ✅ tamang function
          params: {
            'p_full_name': fullNameController.text.trim(),
            'p_seat_number': selectedSeat,
            'p_items': addOnPayload, // ✅ tamang payload
          },
        );
      }

      if (otherItemsPayload.isNotEmpty) {
        await supabase.rpc(
          'place_consignment_order',
          params: {
            'p_full_name': fullNameController.text.trim(),
            'p_seat_number': selectedSeat,
            'p_items': otherItemsPayload,
          },
        );
      }

      await _loadCatalog();

      if (!mounted) return;
      setState(() {
        submitted = true;
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

  Widget buildAiBubble({required String text, bool showAvatar = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[buildLogo(38), const SizedBox(width: 8)],
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
                    onPressed: () {
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
                    onPressed: () => changeQty(index, row.quantity - 1),
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
                    onPressed: () => changeQty(index, row.quantity + 1),
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
                                                    onPressed: addMoreOrder,
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
                                                    onPressed: isSubmitting
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
                                  if (submitted) ...[
                                    const SizedBox(height: 12),

                                    buildAiBubble(
                                      text:
                                          'We’ll notify you via beeper or message once your order is ready.',
                                    ),

                                    buildAiBubble(
                                      text:
                                          'You may then proceed to the counter for pickup and payment.',
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
        child: SizedBox(
          height: 620,
          child: Column(
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
              Text('Seat Number', style: AddOnsStyles.sectionTitle),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.seatGroups.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: AddOnsStyles.seatPanel,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: AddOnsStyles.seatGroupTitle,
                              ),
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
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 66,
                                      height: 42,
                                      alignment: Alignment.center,
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
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected == null
                          ? null
                          : () => Navigator.pop(context, selected),
                      style: AddOnsStyles.primaryButton,
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemPickerSheet extends StatefulWidget {
  final String title;
  final List<CatalogItem> items;

  const _ItemPickerSheet({required this.title, required this.items});

  @override
  State<_ItemPickerSheet> createState() => _ItemPickerSheetState();
}

class _ItemPickerSheetState extends State<_ItemPickerSheet> {
  final TextEditingController searchController = TextEditingController();

  List<CatalogItem> get filteredItems {
    final q = searchController.text.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items.where((e) {
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
        child: SizedBox(
          height: 680,
          child: Column(
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
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];

                          return InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.pop(context, item),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: AddOnsStyles.sectionCard,
                              child: Row(
                                children: [
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
                                      children: [
                                        Text(
                                          item.name,
                                          style: AddOnsStyles.sectionTitle,
                                        ),
                                        if (item.size != null &&
                                            item.size!.trim().isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Size: ${item.size}',
                                            style: AddOnsStyles.mutedText,
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          'Remaining: ${item.stocks}',
                                          style: AddOnsStyles.mutedText,
                                        ),
                                        const SizedBox(height: 6),
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
