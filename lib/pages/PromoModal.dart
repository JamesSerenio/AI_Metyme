import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../styles/PromoModal_styles.dart';

class PromoModalPage extends StatefulWidget {
  const PromoModalPage({super.key});

  @override
  State<PromoModalPage> createState() => _PromoModalPageState();
}

class _PromoModalPageState extends State<PromoModalPage>
    with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String selectedArea = 'common_area';
  String? selectedSeatNumber;
  String? selectedPackageId;
  String? selectedOptionId;
  DateTime? selectedStartDateTime;

  bool loading = false;
  bool submitting = false;
  bool submitted = false;

  String? generatedPromoCode;
  String? aiFinalMessage;

  String? fullNameError;
  String? phoneNumberError;
  String? areaError;
  String? seatNumberError;
  String? packageError;
  String? optionError;
  String? startDateTimeError;

  late final AnimationController pageController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;

  List<Map<String, dynamic>> packages = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> packageOptions = <Map<String, dynamic>>[];

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

    fullNameController.addListener(() {
      if (fullNameError != null) {
        setState(() {
          fullNameError = validateFullName(fullNameController.text);
        });
      }
    });

    phoneNumberController.addListener(() {
      if (phoneNumberError != null) {
        setState(() {
          phoneNumberError = validatePhoneDetailed(phoneNumberController.text);
        });
      }
    });

    loadPromoData();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneNumberController.dispose();
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  Future<void> loadPromoData() async {
    setState(() {
      loading = true;
    });

    try {
      final packageRes = await supabase
          .from('packages')
          .select('id, area, title, description, amenities, is_active')
          .eq('is_active', true)
          .order('created_at', ascending: false);

      final optionRes = await supabase
          .from('package_options')
          .select(
            'id, package_id, option_name, duration_value, duration_unit, price, '
            'promo_max_attempts, promo_validity_days, max_attempts, validity_days',
          )
          .order('created_at', ascending: true);

      setState(() {
        packages = List<Map<String, dynamic>>.from(packageRes);
        packageOptions = List<Map<String, dynamic>>.from(optionRes);
      });
    } catch (e) {
      _showInlineError(
        'We were unable to load the available promo packages at the moment.\n\nError: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get filteredPackages {
    return packages
        .where((p) => (p['area']?.toString() ?? '') == selectedArea)
        .toList();
  }

  List<Map<String, dynamic>> get filteredOptions {
    if (selectedPackageId == null) return <Map<String, dynamic>>[];
    return packageOptions
        .where((o) => (o['package_id']?.toString() ?? '') == selectedPackageId)
        .toList();
  }

  Map<String, dynamic>? get selectedPackage {
    if (selectedPackageId == null) return null;
    try {
      return packages.firstWhere(
        (p) => (p['id']?.toString() ?? '') == selectedPackageId,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? get selectedOption {
    if (selectedOptionId == null) return null;
    try {
      return packageOptions.firstWhere(
        (o) => (o['id']?.toString() ?? '') == selectedOptionId,
      );
    } catch (_) {
      return null;
    }
  }

  List<String> get amenitiesList {
    final raw = selectedPackage?['amenities']?.toString();
    if (raw == null || raw.trim().isEmpty) return <String>[];
    return raw
        .split(RegExp(r'\r?\n|•'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  bool get requiresSeatNumber => selectedArea == 'common_area';

  String formatAreaText(String value) {
    switch (value) {
      case 'common_area':
        return 'Common Area';
      case 'conference_room':
        return 'Conference Room';
      default:
        return value;
    }
  }

  String formatDurationUnit(String unit, int value) {
    switch (unit) {
      case 'hour':
        return value == 1 ? 'hour' : 'hours';
      case 'day':
        return value == 1 ? 'day' : 'days';
      case 'month':
        return value == 1 ? 'month' : 'months';
      case 'year':
        return value == 1 ? 'year' : 'years';
      default:
        return unit;
    }
  }

  String formatDurationPrice(Map<String, dynamic> option) {
    final int durationValue = toInt(option['duration_value']) ?? 0;
    final String unit = option['duration_unit']?.toString() ?? '';
    final double price = toDouble(option['price']);
    final String optionName = option['option_name']?.toString() ?? 'Option';

    return '$optionName • $durationValue ${formatDurationUnit(unit, durationValue)} • ₱${price.toStringAsFixed(2)}';
  }

  int? toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  DateTime addMonths(DateTime date, int months) {
    final int yearDelta = (date.month - 1 + months) ~/ 12;
    final int newYear = date.year + yearDelta;
    final int newMonth = ((date.month - 1 + months) % 12) + 1;

    final int lastDayOfTargetMonth = DateTime(newYear, newMonth + 1, 0).day;
    final int newDay = date.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : date.day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  DateTime addYears(DateTime date, int years) {
    final int newYear = date.year + years;
    final int lastDayOfTargetMonth = DateTime(newYear, date.month + 1, 0).day;
    final int newDay = date.day > lastDayOfTargetMonth
        ? lastDayOfTargetMonth
        : date.day;

    return DateTime(
      newYear,
      date.month,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  DateTime? computeEndDateTime() {
    if (selectedStartDateTime == null || selectedOption == null) return null;

    final DateTime start = selectedStartDateTime!;
    final int durationValue = toInt(selectedOption!['duration_value']) ?? 0;
    final String unit = selectedOption!['duration_unit']?.toString() ?? '';

    switch (unit) {
      case 'hour':
        return start.add(Duration(hours: durationValue));
      case 'day':
        return start.add(Duration(days: durationValue));
      case 'month':
        return addMonths(start, durationValue);
      case 'year':
        return addYears(start, durationValue);
      default:
        return start;
    }
  }

  String formatDateTimeReadable(DateTime? value) {
    if (value == null) return '';
    final int hour12 = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String period = value.hour >= 12 ? 'PM' : 'AM';

    return '${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}/${value.year} '
        '$hour12:$minute $period';
  }

  String? validateFullName(String input) {
    final value = input.trim();

    if (value.isEmpty) {
      return 'Please enter your full name.';
    }

    if (value.length < 3) {
      return 'Your full name looks too short. Please enter your complete name.';
    }

    return null;
  }

  String? validatePhoneDetailed(String input) {
    String value = input.trim().replaceAll(RegExp(r'\s+|-'), '');

    if (value.isEmpty) {
      return 'Please enter your phone number.';
    }

    if (value.startsWith('+63')) {
      value = '0${value.substring(3)}';
    } else if (value.startsWith('63')) {
      value = '0${value.substring(2)}';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Your phone number must contain digits only.';
    }

    if (!value.startsWith('09')) {
      return 'Your phone number must start with 09.';
    }

    if (value.length < 11) {
      return 'Your phone number is incomplete. Please enter all 11 digits.';
    }

    if (value.length > 11) {
      return 'Your phone number is too long. Please enter only 11 digits.';
    }

    return null;
  }

  String? normalizePhone(String input) {
    String value = input.trim().replaceAll(RegExp(r'\s+|-'), '');

    if (value.startsWith('+63')) {
      value = '0${value.substring(3)}';
    } else if (value.startsWith('63')) {
      value = '0${value.substring(2)}';
    }

    if (!RegExp(r'^09[0-9]{9}$').hasMatch(value)) {
      return null;
    }

    return value;
  }

  Future<String> generateUniquePromoCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    while (true) {
      final code = List.generate(
        8,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      final existing = await supabase
          .from('promo_bookings')
          .select('id')
          .eq('promo_code', code)
          .limit(1);

      if (existing is List && existing.isEmpty) {
        return code;
      }
    }
  }

  bool validateForm() {
    final newFullNameError = validateFullName(fullNameController.text);
    final newPhoneNumberError = validatePhoneDetailed(
      phoneNumberController.text,
    );

    final newAreaError = selectedArea.trim().isEmpty
        ? 'Please select the area.'
        : null;

    final newPackageError = selectedPackageId == null
        ? 'Please select a promo package.'
        : null;

    final newSeatNumberError =
        requiresSeatNumber &&
            (selectedSeatNumber == null || selectedSeatNumber!.trim().isEmpty)
        ? 'Please select the seat number.'
        : null;

    final newOptionError = selectedOptionId == null
        ? 'Please select a duration and price option.'
        : null;

    final newStartDateTimeError = selectedStartDateTime == null
        ? 'Please select the start date and time.'
        : null;

    setState(() {
      fullNameError = newFullNameError;
      phoneNumberError = newPhoneNumberError;
      areaError = newAreaError;
      packageError = newPackageError;
      seatNumberError = newSeatNumberError;
      optionError = newOptionError;
      startDateTimeError = newStartDateTimeError;
    });

    return [
      newFullNameError,
      newPhoneNumberError,
      newAreaError,
      newPackageError,
      newSeatNumberError,
      newOptionError,
      newStartDateTimeError,
    ].every((e) => e == null);
  }

  Future<void> pickStartDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedStartDateTime ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: PromoModalStyles.primary,
              onPrimary: Colors.white,
              onSurface: PromoModalStyles.textDark,
              surface: PromoModalStyles.cardBg,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedStartDateTime != null
          ? TimeOfDay.fromDateTime(selectedStartDateTime!)
          : TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: PromoModalStyles.cardBg,
              hourMinuteColor: Colors.white,
              hourMinuteTextColor: PromoModalStyles.textDark,
              dialHandColor: PromoModalStyles.primary,
              dialBackgroundColor: Colors.white,
              dayPeriodColor: Colors.white,
              dayPeriodTextColor: PromoModalStyles.textDark,
              entryModeIconColor: PromoModalStyles.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            colorScheme: const ColorScheme.light(
              primary: PromoModalStyles.primary,
              onPrimary: Colors.white,
              onSurface: PromoModalStyles.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    final selected = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      selectedStartDateTime = selected;
      startDateTimeError = null;
    });
  }

  Future<void> submitPromo() async {
    final isFormValid = validateForm();
    if (!isFormValid) {
      _scrollToBottom();
      return;
    }

    final normalizedPhone = normalizePhone(phoneNumberController.text);
    if (normalizedPhone == null) {
      setState(() {
        phoneNumberError =
            'Please enter a valid 11-digit phone number that starts with 09.';
      });
      return;
    }

    final package = selectedPackage;
    final option = selectedOption;
    final start = selectedStartDateTime;
    final end = computeEndDateTime();

    if (package == null || option == null || start == null || end == null) {
      _showInlineError(
        'Please complete the promo details before saving your promo booking.',
      );
      return;
    }

    setState(() {
      submitting = true;
    });

    try {
      final promoCode = await generateUniquePromoCode();

      final int promoMaxAttempts =
          toInt(option['promo_max_attempts']) ??
          toInt(option['max_attempts']) ??
          7;

      await supabase.from('promo_bookings').insert({
        'full_name': fullNameController.text.trim(),
        'phone_number': normalizedPhone,
        'area': selectedArea,
        'package_id': package['id'],
        'package_option_id': option['id'],
        'seat_number': requiresSeatNumber ? selectedSeatNumber : null,
        'start_at': start.toUtc().toIso8601String(),
        'end_at': end.toUtc().toIso8601String(),
        'price': toDouble(option['price']),
        'status': 'pending',
        'promo_code': promoCode,
        'attempts': 0,
        'max_attempts': promoMaxAttempts,
        'attempts_left': promoMaxAttempts,
        'validity_end_at': end.toUtc().toIso8601String(),
        'discount_kind': 'none',
        'discount_value': 0,
        'gcash_amount': 0,
        'cash_amount': 0,
        'is_paid': false,
      });

      final reminderText =
          'Please keep this code safe. Copy it or take a screenshot or photo, as you will need it for attendance (IN/OUT), add-ons, and for submitting suggestions or concerns to the staff. Thank you and we look forward to serving you! 😊';

      setState(() {
        submitted = true;
        generatedPromoCode = promoCode;
        aiFinalMessage = reminderText;
      });

      _scrollToBottom();
    } catch (e) {
      _showInlineError(
        'We were unable to save your promo booking at the moment. Please try again.\n\nError: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          submitting = false;
        });
      }
    }
  }

  void _showInlineError(String message) {
    setState(() {
      submitted = false;
      generatedPromoCode = null;
      aiFinalMessage = message;
    });
    _scrollToBottom();
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
              decoration: PromoModalStyles.aiBubble,
              child: Text(text, style: PromoModalStyles.aiText),
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
              decoration: PromoModalStyles.successBubble,
              child: Text(text, style: PromoModalStyles.successText),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCodeBubble(String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: PromoModalStyles.successBubble,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PROMO CODE',
                    style: PromoModalStyles.successText.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    code,
                    style: PromoModalStyles.successText.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration decoratedInput({
    required String hintText,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: PromoModalStyles.textMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorMaxLines: 3,
      errorStyle: const TextStyle(
        color: PromoModalStyles.error,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: errorText != null
              ? PromoModalStyles.error
              : Colors.black.withOpacity(0.07),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: errorText != null
              ? PromoModalStyles.error
              : PromoModalStyles.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PromoModalStyles.error, width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: PromoModalStyles.error, width: 1.6),
      ),
    );
  }

  Widget buildTextField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PromoModalStyles.label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: decoratedInput(hintText: hintText, errorText: errorText),
        ),
      ],
    );
  }

  Widget buildDropdownField({
    required String label,
    required String valueText,
    required VoidCallback onTap,
    String? emptyText,
    IconData? icon,
    String? errorText,
  }) {
    final bool hasValue = valueText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: PromoModalStyles.label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: InputDecorator(
            decoration: decoratedInput(
              hintText: emptyText ?? 'Select $label',
              errorText: errorText,
              suffixIcon: Icon(icon ?? Icons.keyboard_arrow_down_rounded),
            ),
            child: Text(
              hasValue ? valueText : (emptyText ?? 'Select $label'),
              style: TextStyle(
                color: hasValue
                    ? PromoModalStyles.textDark
                    : PromoModalStyles.textMuted,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> pickArea() async {
    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SelectionSheet<String>(
          title: 'Select Area',
          items: const [
            _SheetOption(label: 'Common Area', value: 'common_area'),
            _SheetOption(label: 'Conference Room', value: 'conference_room'),
          ],
        );
      },
    );

    if (value != null) {
      setState(() {
        selectedArea = value;
        selectedSeatNumber = null;
        selectedPackageId = null;
        selectedOptionId = null;
        selectedStartDateTime = null;
        submitted = false;
        generatedPromoCode = null;
        aiFinalMessage = null;

        areaError = null;
        packageError = null;
        seatNumberError = null;
        optionError = null;
        startDateTimeError = null;
      });
    }
  }

  Future<void> pickPackage() async {
    final availablePackages = filteredPackages;
    if (availablePackages.isEmpty) return;

    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SelectionSheet<String>(
          title: 'Select Promo Package',
          items: availablePackages
              .map(
                (p) => _SheetOption(
                  label: p['title']?.toString() ?? 'Package',
                  value: p['id']?.toString() ?? '',
                ),
              )
              .toList(),
        );
      },
    );

    if (value != null) {
      setState(() {
        selectedPackageId = value;
        selectedSeatNumber = null;
        selectedOptionId = null;
        selectedStartDateTime = null;
        packageError = null;
        seatNumberError = null;
        optionError = null;
        startDateTimeError = null;
      });
    }
  }

  Future<void> pickSeatNumber() async {
    if (!requiresSeatNumber || selectedPackageId == null) return;

    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SeatPickerModal(selectedSeat: selectedSeatNumber);
      },
    );

    if (value != null) {
      setState(() {
        selectedSeatNumber = value;
        seatNumberError = null;
      });
    }
  }

  Future<void> pickOption() async {
    final availableOptions = filteredOptions;
    if (availableOptions.isEmpty) return;

    final value = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _SelectionSheet<String>(
          title: 'Select Duration / Price',
          items: availableOptions
              .map(
                (o) => _SheetOption(
                  label: formatDurationPrice(o),
                  value: o['id']?.toString() ?? '',
                ),
              )
              .toList(),
        );
      },
    );

    if (value != null) {
      setState(() {
        selectedOptionId = value;
        selectedStartDateTime = null;
        optionError = null;
        startDateTimeError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final isMobile = screen.width < 640;
    final isTablet = screen.width >= 640 && screen.width < 1100;

    final double modalWidth = isMobile
        ? screen.width - 20
        : isTablet
        ? 620
        : 760;

    final double modalHeight = isMobile
        ? screen.height * 0.92
        : isTablet
        ? 560
        : 620;

    final computedEnd = computeEndDateTime();

    return Scaffold(
      backgroundColor: PromoModalStyles.pageBg,
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
                decoration: PromoModalStyles.modalCard,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: PromoModalStyles.headerCard,
                      child: Row(
                        children: [
                          buildLogo(isMobile ? 42 : 48),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Promo Assistant',
                                  style: PromoModalStyles.title,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Please complete the promo booking details below.',
                                  style: PromoModalStyles.subtitle,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: PromoModalStyles.statusChip,
                            child: Text(
                              'Promo',
                              style: PromoModalStyles.chipText,
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
                        decoration: PromoModalStyles.chatArea,
                        child: loading
                            ? const Center(child: CircularProgressIndicator())
                            : ListView(
                                controller: scrollController,
                                children: [
                                  buildSuccessBubble('You selected Promo 🎉'),
                                  buildAiBubble(
                                    text:
                                        'Please fill in the promo booking information below.',
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.all(isMobile ? 14 : 18),
                                    decoration: PromoModalStyles.formCard,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Promo Booking Information',
                                          style: PromoModalStyles.sectionTitle,
                                        ),
                                        const SizedBox(height: 14),
                                        buildTextField(
                                          label: 'Full Name',
                                          controller: fullNameController,
                                          hintText: 'Enter full name',
                                          errorText: fullNameError,
                                        ),
                                        const SizedBox(height: 14),
                                        buildTextField(
                                          label: 'Phone Number',
                                          controller: phoneNumberController,
                                          hintText: 'Enter phone number',
                                          errorText: phoneNumberError,
                                          keyboardType: TextInputType.phone,
                                        ),
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Area',
                                          valueText: formatAreaText(
                                            selectedArea,
                                          ),
                                          onTap: pickArea,
                                          errorText: areaError,
                                        ),
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Promo Package',
                                          valueText:
                                              selectedPackage?['title']
                                                  ?.toString() ??
                                              '',
                                          emptyText: filteredPackages.isEmpty
                                              ? 'No available package for this area'
                                              : 'Select promo package',
                                          onTap: pickPackage,
                                          icon: Icons.local_offer_rounded,
                                          errorText: packageError,
                                        ),
                                        if (selectedPackage != null) ...[
                                          const SizedBox(height: 14),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration:
                                                PromoModalStyles.infoCard,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Amenities',
                                                  style: PromoModalStyles
                                                      .infoTitle,
                                                ),
                                                const SizedBox(height: 8),
                                                if (amenitiesList.isEmpty)
                                                  Text(
                                                    selectedPackage?['amenities']
                                                                ?.toString()
                                                                .trim()
                                                                .isNotEmpty ==
                                                            true
                                                        ? selectedPackage!['amenities']
                                                              .toString()
                                                        : 'No amenities listed for this package.',
                                                    style: PromoModalStyles
                                                        .infoText,
                                                  )
                                                else
                                                  ...amenitiesList.map(
                                                    (item) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 6,
                                                          ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                            '• ',
                                                            style:
                                                                PromoModalStyles
                                                                    .infoText,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              item,
                                                              style:
                                                                  PromoModalStyles
                                                                      .infoText,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        if (requiresSeatNumber) ...[
                                          const SizedBox(height: 14),
                                          buildDropdownField(
                                            label: 'Seat Number',
                                            valueText: selectedSeatNumber ?? '',
                                            emptyText: selectedPackageId == null
                                                ? 'Select promo package first'
                                                : 'Select seat number',
                                            onTap: pickSeatNumber,
                                            icon: Icons.event_seat_rounded,
                                            errorText: seatNumberError,
                                          ),
                                        ],
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Duration / Price',
                                          valueText: selectedOption != null
                                              ? formatDurationPrice(
                                                  selectedOption!,
                                                )
                                              : '',
                                          emptyText: selectedPackage == null
                                              ? 'Select promo package first'
                                              : 'Select duration and price',
                                          onTap: pickOption,
                                          icon: Icons.payments_rounded,
                                          errorText: optionError,
                                        ),
                                        if (selectedOption != null) ...[
                                          const SizedBox(height: 14),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration:
                                                PromoModalStyles.infoCard,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Selected Promo Details',
                                                  style: PromoModalStyles
                                                      .infoTitle,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  formatDurationPrice(
                                                    selectedOption!,
                                                  ),
                                                  style:
                                                      PromoModalStyles.infoText,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 14),
                                        buildDropdownField(
                                          label: 'Start Date & Time',
                                          valueText: formatDateTimeReadable(
                                            selectedStartDateTime,
                                          ),
                                          emptyText: 'Pick start date and time',
                                          onTap: pickStartDateTime,
                                          icon: Icons.calendar_month_rounded,
                                          errorText: startDateTimeError,
                                        ),
                                        if (selectedStartDateTime != null &&
                                            computedEnd != null) ...[
                                          const SizedBox(height: 14),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(14),
                                            decoration:
                                                PromoModalStyles.infoCard,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Schedule Preview',
                                                  style: PromoModalStyles
                                                      .infoTitle,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Start: ${formatDateTimeReadable(selectedStartDateTime)}',
                                                  style:
                                                      PromoModalStyles.infoText,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  'End: ${formatDateTimeReadable(computedEnd)}',
                                                  style:
                                                      PromoModalStyles.infoText,
                                                ),
                                                if (requiresSeatNumber &&
                                                    selectedSeatNumber !=
                                                        null) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    'Seat: $selectedSeatNumber',
                                                    style: PromoModalStyles
                                                        .infoText,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 18),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: ElevatedButton(
                                                onPressed: submitting
                                                    ? null
                                                    : submitPromo,
                                                style: PromoModalStyles
                                                    .primaryButton,
                                                child: submitting
                                                    ? const SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2.4,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      )
                                                    : const Text(
                                                        'Submit Promo',
                                                      ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (submitted &&
                                      generatedPromoCode != null) ...[
                                    const SizedBox(height: 12),
                                    buildAiBubble(
                                      text:
                                          'Your promo booking information has been received successfully.',
                                    ),
                                    buildCodeBubble(generatedPromoCode!),
                                    if (aiFinalMessage != null)
                                      buildAiBubble(text: aiFinalMessage!),
                                  ] else if (aiFinalMessage != null) ...[
                                    const SizedBox(height: 12),
                                    buildAiBubble(text: aiFinalMessage!),
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
                            style: PromoModalStyles.secondaryButton,
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

class SeatPickerModal extends StatefulWidget {
  final String? selectedSeat;

  const SeatPickerModal({super.key, this.selectedSeat});

  @override
  State<SeatPickerModal> createState() => _SeatPickerModalState();
}

class _SeatPickerModalState extends State<SeatPickerModal> {
  String? selected;

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
    selected = widget.selectedSeat?.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: PromoModalStyles.cardBg,
        borderRadius: BorderRadius.circular(26),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Text('Seat Number', style: PromoModalStyles.seatPickerTitle),
              const SizedBox(height: 14),
              ...seatGroups.entries.map((group) {
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: PromoModalStyles.seatGroupCard,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.key, style: PromoModalStyles.seatGroupTitle),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: group.value.map((seat) {
                          final bool isSelected = selected == seat;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selected = seat;
                              });
                            },
                            child: Container(
                              width: 70,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: isSelected
                                  ? PromoModalStyles.selectedSeatBox
                                  : PromoModalStyles.seatBox,
                              child: Text(
                                seat,
                                style: isSelected
                                    ? PromoModalStyles.selectedSeatText
                                    : PromoModalStyles.seatText,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, selected);
                  },
                  style: PromoModalStyles.primaryButton,
                  child: const Text('Done'),
                ),
              ),
            ],
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
        color: PromoModalStyles.cardBg,
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
            Text(title, style: PromoModalStyles.sectionTitle),
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
                        color: PromoModalStyles.textDark,
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
