import 'package:flutter/material.dart';
import '../styles/BookingModal_styles.dart';

enum CustomerType { reviewer, student, regular }

enum IdType { withId, withoutId }

enum ReservationType { yes, no }

enum OpenTimeType { yes, no }

class BookingModalPage extends StatefulWidget {
  const BookingModalPage({super.key});

  @override
  State<BookingModalPage> createState() => _BookingModalPageState();
}

class _BookingModalPageState extends State<BookingModalPage>
    with TickerProviderStateMixin {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController timeAvailController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  CustomerType? selectedCustomerType;
  IdType? selectedIdType;
  ReservationType? selectedReservationType;
  OpenTimeType? selectedOpenTimeType;

  DateTimeRange? selectedReservationRange;
  TimeOfDay? selectedReservationStartTime;
  final List<String> selectedSeats = [];

  bool showForm = false;
  bool submitted = false;

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
    contactNumberController.dispose();
    timeAvailController.dispose();
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  String customerTypeText(CustomerType? value) {
    switch (value) {
      case CustomerType.reviewer:
        return 'Reviewer';
      case CustomerType.student:
        return 'Student';
      case CustomerType.regular:
        return 'Regular';
      case null:
        return '';
    }
  }

  String idTypeText(IdType? value) {
    switch (value) {
      case IdType.withId:
        return 'With ID';
      case IdType.withoutId:
        return 'Without ID';
      case null:
        return '';
    }
  }

  String reservationTypeText(ReservationType? value) {
    switch (value) {
      case ReservationType.yes:
        return 'Yes';
      case ReservationType.no:
        return 'No';
      case null:
        return '';
    }
  }

  String openTimeText(OpenTimeType? value) {
    switch (value) {
      case OpenTimeType.yes:
        return 'Yes';
      case OpenTimeType.no:
        return 'No';
      case null:
        return '';
    }
  }

  String reservationRangeText(DateTimeRange? range) {
    if (range == null) return '';
    final start =
        '${range.start.month.toString().padLeft(2, '0')}/${range.start.day.toString().padLeft(2, '0')}/${range.start.year}';
    final end =
        '${range.end.month.toString().padLeft(2, '0')}/${range.end.day.toString().padLeft(2, '0')}/${range.end.year}';
    return '$start - $end';
  }

  String reservationStartTimeText(TimeOfDay? value) {
    if (value == null) return '';
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  bool get shouldShowOpenTime => selectedReservationType != null;
  bool get shouldShowTimeAvail => selectedOpenTimeType == OpenTimeType.no;
  bool get shouldShowReservationFields =>
      selectedReservationType == ReservationType.yes;

  bool get isValid {
    final fullName = fullNameController.text.trim();
    final contact = contactNumberController.text.trim();

    if (fullName.isEmpty ||
        contact.isEmpty ||
        selectedCustomerType == null ||
        selectedIdType == null ||
        selectedReservationType == null) {
      return false;
    }

    if (shouldShowOpenTime && selectedOpenTimeType == null) {
      return false;
    }

    if (shouldShowTimeAvail && timeAvailController.text.trim().isEmpty) {
      return false;
    }

    if (shouldShowReservationFields) {
      if (selectedReservationRange == null ||
          selectedReservationStartTime == null ||
          selectedSeats.isEmpty) {
        return false;
      }
    }

    return true;
  }

  void submitForm() {
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all booking information.'),
        ),
      );
      return;
    }

    setState(() {
      submitted = true;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 240,
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
              decoration: BookingModalStyles.aiBubble,
              child: Text(text, style: BookingModalStyles.aiText),
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
              decoration: BookingModalStyles.successBubble,
              child: Text(text, style: BookingModalStyles.successText),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDropdownField({
    required String label,
    required String valueText,
    required VoidCallback onTap,
    String? emptyText,
    IconData? icon,
  }) {
    final bool hasValue = valueText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BookingModalStyles.label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: InputDecorator(
            decoration: BookingModalStyles.inputDecoration(
              hintText: hasValue ? valueText : (emptyText ?? 'Select $label'),
              suffixIcon: Icon(icon ?? Icons.keyboard_arrow_down_rounded),
            ),
            child: hasValue
                ? Text(
                    valueText,
                    style: const TextStyle(
                      color: BookingModalStyles.textDark,
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

  Future<void> pickCustomerType() async {
    final value = await showModalBottomSheet<CustomerType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SelectionSheet<CustomerType>(
          title: 'Select Customer Type',
          items: const [
            _SheetOption(label: 'Reviewer', value: CustomerType.reviewer),
            _SheetOption(label: 'Student', value: CustomerType.student),
            _SheetOption(label: 'Regular', value: CustomerType.regular),
          ],
        );
      },
    );

    if (value != null) {
      setState(() {
        selectedCustomerType = value;
      });
    }
  }

  Future<void> pickIdType() async {
    final value = await showModalBottomSheet<IdType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SelectionSheet<IdType>(
          title: 'Select ID Type',
          items: const [
            _SheetOption(label: 'With ID', value: IdType.withId),
            _SheetOption(label: 'Without ID', value: IdType.withoutId),
          ],
        );
      },
    );

    if (value != null) {
      setState(() {
        selectedIdType = value;
      });
    }
  }

  Future<void> pickReservationType() async {
    final value = await showModalBottomSheet<ReservationType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SelectionSheet<ReservationType>(
          title: 'Reservation',
          items: const [
            _SheetOption(label: 'Yes', value: ReservationType.yes),
            _SheetOption(label: 'No', value: ReservationType.no),
          ],
        );
      },
    );

    if (value != null) {
      setState(() {
        selectedReservationType = value;
        selectedOpenTimeType = null;
        selectedReservationRange = null;
        selectedReservationStartTime = null;
        selectedSeats.clear();
        timeAvailController.clear();
      });
    }
  }

  Future<void> pickOpenTimeType() async {
    final value = await showModalBottomSheet<OpenTimeType>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SelectionSheet<OpenTimeType>(
          title: 'Open Time',
          items: const [
            _SheetOption(label: 'Yes', value: OpenTimeType.yes),
            _SheetOption(label: 'No', value: OpenTimeType.no),
          ],
        );
      },
    );

    if (value != null) {
      setState(() {
        selectedOpenTimeType = value;
        if (value == OpenTimeType.yes) {
          timeAvailController.clear();
        }
      });
    }
  }

  Future<void> pickReservationRange() async {
    final now = DateTime.now();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDateRange: selectedReservationRange,
      saveText: 'Done',
      helpText: 'Select reservation range',
      fieldStartHintText: 'Start date',
      fieldEndHintText: 'End date',
      builder: (context, child) {
        final themedChild = Theme(
          data: Theme.of(context).copyWith(
            useMaterial3: true,
            colorScheme: const ColorScheme.light(
              primary: BookingModalStyles.primary,
              onPrimary: Colors.white,
              surface: BookingModalStyles.cardBg,
              onSurface: BookingModalStyles.textDark,
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: BookingModalStyles.cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            datePickerTheme: BookingModalStyles.buildDatePickerTheme(),
          ),
          child: child!,
        );

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(size: MediaQuery.of(context).size),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760, maxHeight: 720),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Material(color: Colors.transparent, child: themedChild),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedReservationRange = picked;
      });
    }
  }

  Future<void> pickReservationStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedReservationStartTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: BookingModalStyles.cardBg,
              hourMinuteColor: Colors.white,
              hourMinuteTextColor: BookingModalStyles.textDark,
              dialHandColor: BookingModalStyles.primary,
              dialBackgroundColor: Colors.white,
              dayPeriodColor: Colors.white,
              dayPeriodTextColor: BookingModalStyles.textDark,
              entryModeIconColor: BookingModalStyles.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            colorScheme: const ColorScheme.light(
              primary: BookingModalStyles.primary,
              onPrimary: Colors.white,
              onSurface: BookingModalStyles.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedReservationStartTime = picked;
      });
    }
  }

  Future<void> pickTimeAvail() async {
    final TextEditingController localController = TextEditingController(
      text: timeAvailController.text,
    );

    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _TimeAvailSheet(controller: localController),
        );
      },
    );

    if (result != null) {
      setState(() {
        timeAvailController.text = result;
      });
    }
  }

  Future<void> pickSeats() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SeatPickerSheet(
          seatGroups: seatGroups,
          initialSelected: selectedSeats,
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedSeats
          ..clear()
          ..addAll(result);
      });
    }
  }

  String seatText() {
    if (selectedSeats.isEmpty) return '';
    return selectedSeats.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isMobile = screen.width < 640;
    final isTablet = screen.width >= 640 && screen.width < 1100;

    final double modalWidth = isMobile
        ? screen.width - 20
        : isTablet
        ? 600
        : 700;

    final double modalHeight = isMobile
        ? screen.height * 0.92
        : isTablet
        ? 500
        : 520;

    return Scaffold(
      backgroundColor: BookingModalStyles.pageBg,
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
                decoration: BookingModalStyles.modalCard,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BookingModalStyles.headerCard,
                      child: Row(
                        children: [
                          buildLogo(isMobile ? 42 : 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking Assistant',
                                  style: BookingModalStyles.title,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please complete the booking information below.',
                                  style: BookingModalStyles.subtitle,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BookingModalStyles.statusChip,
                            child: Text(
                              'Booking',
                              style: BookingModalStyles.chipText,
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
                        decoration: BookingModalStyles.chatArea,
                        child: ListView(
                          controller: scrollController,
                          children: [
                            buildSuccessBubble('You selected Booking ✅'),
                            buildAiBubble(
                              text: 'Please fill up the information below.',
                            ),
                            if (showForm) ...[
                              const SizedBox(height: 8),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 350),
                                opacity: 1,
                                child: Container(
                                  padding: EdgeInsets.all(isMobile ? 14 : 18),
                                  decoration: BookingModalStyles.formCard,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Booking Information',
                                        style: BookingModalStyles.sectionTitle,
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Full Name',
                                        style: BookingModalStyles.label,
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: fullNameController,
                                        decoration:
                                            BookingModalStyles.inputDecoration(
                                              hintText: 'Enter full name',
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Contact Number',
                                        style: BookingModalStyles.label,
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: contactNumberController,
                                        keyboardType: TextInputType.phone,
                                        decoration:
                                            BookingModalStyles.inputDecoration(
                                              hintText: 'Enter contact number',
                                            ),
                                      ),
                                      const SizedBox(height: 14),
                                      buildDropdownField(
                                        label: 'Customer Type',
                                        valueText: customerTypeText(
                                          selectedCustomerType,
                                        ),
                                        onTap: pickCustomerType,
                                      ),
                                      const SizedBox(height: 14),
                                      buildDropdownField(
                                        label: 'ID',
                                        valueText: idTypeText(selectedIdType),
                                        onTap: pickIdType,
                                      ),
                                      const SizedBox(height: 14),
                                      buildDropdownField(
                                        label: 'Reservation',
                                        valueText: reservationTypeText(
                                          selectedReservationType,
                                        ),
                                        onTap: pickReservationType,
                                      ),
                                      if (shouldShowOpenTime) ...[
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Open Time',
                                          valueText: openTimeText(
                                            selectedOpenTimeType,
                                          ),
                                          onTap: pickOpenTimeType,
                                        ),
                                      ],
                                      if (shouldShowReservationFields) ...[
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Reservation Date Range',
                                          valueText: reservationRangeText(
                                            selectedReservationRange,
                                          ),
                                          emptyText:
                                              'Pick reservation date range',
                                          onTap: pickReservationRange,
                                          icon: Icons.calendar_month_rounded,
                                        ),
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Time Started (Reservation)',
                                          valueText: reservationStartTimeText(
                                            selectedReservationStartTime,
                                          ),
                                          emptyText: 'Pick reservation time',
                                          onTap: pickReservationStartTime,
                                          icon: Icons.access_time_rounded,
                                        ),
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Seat Number',
                                          valueText: seatText(),
                                          emptyText: 'Pick seat number',
                                          onTap: pickSeats,
                                          icon: Icons.event_seat_rounded,
                                        ),
                                      ],
                                      if (shouldShowTimeAvail) ...[
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Time Avail (HH:MM or hours)',
                                          valueText: timeAvailController.text,
                                          emptyText: 'Pick time available',
                                          onTap: pickTimeAvail,
                                          icon: Icons.schedule_rounded,
                                        ),
                                      ],
                                      const SizedBox(height: 18),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: submitForm,
                                              style: BookingModalStyles
                                                  .primaryButton,
                                              child: const Text('Submit'),
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
                                    'Booking information received successfully. You can now proceed to the next booking step.',
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
                            style: BookingModalStyles.secondaryButton,
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
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: BookingModalStyles.cardBg,
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
            Text(title, style: BookingModalStyles.sectionTitle),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
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
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: BookingModalStyles.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeAvailSheet extends StatelessWidget {
  final TextEditingController controller;

  const _TimeAvailSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: BookingModalStyles.cardBg,
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
              'Time Avail (HH:MM or hours)',
              style: BookingModalStyles.sectionTitle,
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: BookingModalStyles.inputDecoration(
                hintText: 'Example: 02:00 or 2 hours',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    style: BookingModalStyles.primaryButton,
                    child: const Text('Done'),
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

class _SeatPickerSheet extends StatefulWidget {
  final Map<String, List<String>> seatGroups;
  final List<String> initialSelected;

  const _SeatPickerSheet({
    required this.seatGroups,
    required this.initialSelected,
  });

  @override
  State<_SeatPickerSheet> createState() => _SeatPickerSheetState();
}

class _SeatPickerSheetState extends State<_SeatPickerSheet> {
  late final List<String> selected;

  @override
  void initState() {
    super.initState();
    selected = [...widget.initialSelected];
  }

  void toggleSeat(String seat) {
    setState(() {
      if (selected.contains(seat)) {
        selected.remove(seat);
      } else {
        selected.add(seat);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      decoration: BoxDecoration(
        color: BookingModalStyles.cardBg,
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
              Text('Seat Number', style: BookingModalStyles.sectionTitle),
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
                          decoration: BookingModalStyles.seatPanel,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.key,
                                style: BookingModalStyles.seatGroupTitle,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: entry.value.map((seat) {
                                  final isSelected = selected.contains(seat);
                                  return GestureDetector(
                                    onTap: () => toggleSeat(seat),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 66,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: isSelected
                                          ? BookingModalStyles.selectedSeatBox
                                          : BookingModalStyles.seatBox,
                                      child: Text(
                                        seat,
                                        style: isSelected
                                            ? BookingModalStyles
                                                  .selectedSeatText
                                            : BookingModalStyles.seatText,
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
                      onPressed: () => Navigator.pop(context, selected),
                      style: BookingModalStyles.primaryButton,
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
