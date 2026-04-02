import 'dart:math';

import 'package:flutter/material.dart';
import '../styles/BookingModal_styles.dart';
import '../utils/supabase_client.dart';

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
  bool isSubmitting = false;

  String? generatedBookingCode;
  String? aiFinalMessage;

  String? fullNameError;
  String? contactNumberError;
  String? customerTypeError;
  String? idTypeError;
  String? reservationTypeError;
  String? openTimeError;
  String? reservationRangeError;
  String? reservationStartTimeError;
  String? seatNumberError;
  String? timeAvailError;

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

    fullNameController.addListener(() {
      if (fullNameError != null) {
        setState(() {
          fullNameError = validateFullName(fullNameController.text);
        });
      }
    });

    contactNumberController.addListener(() {
      if (contactNumberError != null) {
        setState(() {
          contactNumberError = validatePhoneDetailed(
            contactNumberController.text,
          );
        });
      }
    });

    timeAvailController.addListener(() {
      if (timeAvailError != null) {
        setState(() {
          timeAvailError = validateTimeAvailField();
        });
      }
    });

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
  bool get shouldShowSeatField => selectedReservationType != null;

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
      return 'Please enter your contact number.';
    }

    if (value.startsWith('+63')) {
      value = '0${value.substring(3)}';
    } else if (value.startsWith('63')) {
      value = '0${value.substring(2)}';
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Your contact number must contain digits only.';
    }

    if (!value.startsWith('09')) {
      return 'Your contact number must start with 09.';
    }

    if (value.length < 11) {
      return 'Your contact number is incomplete. Please enter all 11 digits.';
    }

    if (value.length > 11) {
      return 'Your contact number is too long. Please enter only 11 digits.';
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

  String? validateTimeAvailField() {
    if (!shouldShowTimeAvail) return null;

    final value = timeAvailController.text.trim();
    if (value.isEmpty) {
      return 'Please select or enter the available time.';
    }

    if (parseTimeAvail(value) == null) {
      return 'Please enter a valid time format, such as 02:00, 2 hours, or 30 mins.';
    }

    return null;
  }

  String formatDateOnly(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  DateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Duration? parseTimeAvail(String input) {
    final value = input.trim().toLowerCase();

    final hhmm = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (hhmm != null) {
      final hours = int.tryParse(hhmm.group(1)!);
      final minutes = int.tryParse(hhmm.group(2)!);
      if (hours != null && minutes != null) {
        return Duration(hours: hours, minutes: minutes);
      }
    }

    final hoursOnly = RegExp(
      r'^(\d+)\s*(hour|hours|hr|hrs)$',
    ).firstMatch(value);
    if (hoursOnly != null) {
      final hours = int.tryParse(hoursOnly.group(1)!);
      if (hours != null) {
        return Duration(hours: hours);
      }
    }

    final minsOnly = RegExp(
      r'^(\d+)\s*(minute|minutes|min|mins)$',
    ).firstMatch(value);
    if (minsOnly != null) {
      final mins = int.tryParse(minsOnly.group(1)!);
      if (mins != null) {
        return Duration(minutes: mins);
      }
    }

    final justNumber = int.tryParse(value);
    if (justNumber != null) {
      return Duration(hours: justNumber);
    }

    return null;
  }

  Future<String> generateUniqueBookingCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();

    while (true) {
      final code = List.generate(
        4,
        (_) => chars[random.nextInt(chars.length)],
      ).join();

      final existing = await supabase
          .from('customer_sessions')
          .select('id')
          .eq('booking_code', code)
          .limit(1);

      if (existing is List && existing.isEmpty) {
        return code;
      }
    }
  }

  bool validateForm() {
    final newFullNameError = validateFullName(fullNameController.text);
    final newContactNumberError = validatePhoneDetailed(
      contactNumberController.text,
    );

    final newCustomerTypeError = selectedCustomerType == null
        ? 'Please select the customer type.'
        : null;

    final newIdTypeError = selectedIdType == null
        ? 'Please select whether the customer has an ID.'
        : null;

    final newReservationTypeError = selectedReservationType == null
        ? 'Please select whether this booking is for reservation.'
        : null;

    final newOpenTimeError = shouldShowOpenTime && selectedOpenTimeType == null
        ? 'Please select whether this booking is open time or not.'
        : null;

    final newReservationRangeError =
        shouldShowReservationFields && selectedReservationRange == null
        ? 'Please select the reservation date range.'
        : null;

    final newReservationStartTimeError =
        shouldShowReservationFields && selectedReservationStartTime == null
        ? 'Please select the reservation start time.'
        : null;

    final newSeatNumberError = shouldShowSeatField && selectedSeats.isEmpty
        ? 'Please select at least one seat.'
        : null;

    final newTimeAvailError = validateTimeAvailField();

    setState(() {
      fullNameError = newFullNameError;
      contactNumberError = newContactNumberError;
      customerTypeError = newCustomerTypeError;
      idTypeError = newIdTypeError;
      reservationTypeError = newReservationTypeError;
      openTimeError = newOpenTimeError;
      reservationRangeError = newReservationRangeError;
      reservationStartTimeError = newReservationStartTimeError;
      seatNumberError = newSeatNumberError;
      timeAvailError = newTimeAvailError;
    });

    return [
      newFullNameError,
      newContactNumberError,
      newCustomerTypeError,
      newIdTypeError,
      newReservationTypeError,
      newOpenTimeError,
      newReservationRangeError,
      newReservationStartTimeError,
      newSeatNumberError,
      newTimeAvailError,
    ].every((e) => e == null);
  }

  Future<void> submitForm() async {
    final isFormValid = validateForm();
    if (!isFormValid) {
      _scrollToBottom();
      return;
    }

    final normalizedPhone = normalizePhone(contactNumberController.text.trim());
    if (normalizedPhone == null) {
      setState(() {
        contactNumberError =
            'Please enter a valid 11-digit contact number that starts with 09.';
      });
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final isReservation = selectedReservationType == ReservationType.yes;
      final isOpen = selectedOpenTimeType == OpenTimeType.yes;

      DateTime timeStarted;
      DateTime? timeEnded;
      DateTime? expectedEndAt;
      String? reservationDate;
      String? reservationEndDate;

      if (isReservation) {
        final range = selectedReservationRange!;
        final startTime = selectedReservationStartTime!;
        timeStarted = combineDateAndTime(range.start, startTime);
        reservationDate = formatDateOnly(range.start);
        reservationEndDate = formatDateOnly(range.end);

        if (isOpen) {
          expectedEndAt = DateTime(
            range.end.year,
            range.end.month,
            range.end.day,
            23,
            59,
            59,
          );
          timeEnded = null;
        } else {
          final duration = parseTimeAvail(timeAvailController.text);
          if (duration != null) {
            final computedEnd = timeStarted.add(duration);
            final latestAllowed = DateTime(
              range.end.year,
              range.end.month,
              range.end.day,
              23,
              59,
              59,
            );

            expectedEndAt = computedEnd.isAfter(latestAllowed)
                ? latestAllowed
                : computedEnd;
            timeEnded = expectedEndAt;
          }
        }
      } else {
        timeStarted = now;
        reservationDate = null;
        reservationEndDate = null;

        if (isOpen) {
          expectedEndAt = null;
          timeEnded = null;
        } else {
          final duration = parseTimeAvail(timeAvailController.text);
          if (duration != null) {
            expectedEndAt = now.add(duration);
            timeEnded = expectedEndAt;
          }
        }
      }

      final bookingCode = await generateUniqueBookingCode();

      final payload = <String, dynamic>{
        'date': formatDateOnly(now),
        'full_name': fullNameController.text.trim(),
        'customer_type': customerTypeText(selectedCustomerType).toLowerCase(),
        'has_id': selectedIdType == IdType.withId,
        'hour_avail': isOpen ? 'OPEN' : timeAvailController.text.trim(),
        'time_started': timeStarted.toUtc().toIso8601String(),
        'time_ended': timeEnded?.toUtc().toIso8601String(),
        'total_time': 0,
        'total_amount': 0,
        'reservation': isReservation ? 'yes' : 'no',
        'reservation_date': reservationDate,
        'reservation_end_date': reservationEndDate,
        'seat_number': selectedSeats.join(', '),
        'phone_number': normalizedPhone,
        'expected_end_at': expectedEndAt?.toUtc().toIso8601String(),
        'booking_code': bookingCode,
      };

      await supabase.from('customer_sessions').insert(payload);

      final reminderText = isReservation
          ? 'Please keep this code safe and make sure to copy it or take a screenshot or photo. You will need it for your IN/OUT attendance, add-ons, and for submitting suggestions or concerns to the staff. Thank you and we look forward to serving you! 😊'
          : 'Please keep this code safe. Copy it or take a screenshot or photo, as you will need it for add-ons and for submitting suggestions or concerns to the staff. Thank you and we look forward to serving you! 😊';

      setState(() {
        submitted = true;
        generatedBookingCode = bookingCode;
        aiFinalMessage = reminderText;
      });

      _scrollToBottom();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your booking has been saved successfully.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'We were unable to save your booking at the moment. Please try again. Error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
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

  InputDecoration decoratedInput({
    required String hintText,
    String? errorText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9BA3B2),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.96),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: suffixIcon,
      errorText: errorText,
      errorMaxLines: 3,
      errorStyle: const TextStyle(
        color: Color(0xFFD32F2F),
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: errorText != null
              ? const Color(0xFFD32F2F)
              : Colors.black.withOpacity(0.07),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: errorText != null
              ? const Color(0xFFD32F2F)
              : BookingModalStyles.primary,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.6),
      ),
    );
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

  Widget buildCodeBubble(String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BookingModalStyles.successBubble,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BOOKING CODE',
                    style: BookingModalStyles.successText.copyWith(
                      fontSize: 12,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    code,
                    style: BookingModalStyles.successText.copyWith(
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
        Text(label, style: BookingModalStyles.label),
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
        Text(label, style: BookingModalStyles.label),
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
                    ? BookingModalStyles.textDark
                    : const Color(0xFF9BA3B2),
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
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
        customerTypeError = null;
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
        idTypeError = null;
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
        submitted = false;
        generatedBookingCode = null;
        aiFinalMessage = null;

        reservationTypeError = null;
        openTimeError = null;
        reservationRangeError = null;
        reservationStartTimeError = null;
        seatNumberError = null;
        timeAvailError = null;
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
        openTimeError = null;
        if (value == OpenTimeType.yes) {
          timeAvailController.clear();
          timeAvailError = null;
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
        reservationRangeError = null;
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
        reservationStartTimeError = null;
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
        timeAvailError = validateTimeAvailField();
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
        seatNumberError = selectedSeats.isEmpty
            ? 'Please select at least one seat.'
            : null;
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
    final bool isMobile = screen.width < 640;
    final bool isTablet = screen.width >= 640 && screen.width < 1100;

    final double stageWidth = isMobile
        ? screen.width - 8
        : isTablet
        ? 760
        : 1040;

    final double stageHeight = isMobile
        ? screen.height * 0.95
        : isTablet
        ? 650
        : 720;

    final double frameWidth = isMobile
        ? stageWidth * 0.98
        : isTablet
        ? 720
        : 930;

    final double formWidth = isMobile
        ? stageWidth * 0.66
        : isTablet
        ? 430
        : 500;

    final double formHeight = isMobile
        ? stageHeight * 0.47
        : isTablet
        ? 305
        : 330;

    final double formTop = isMobile
        ? stageHeight * 0.20
        : isTablet
        ? 136
        : 150;

    final double closeBottom = isMobile
        ? stageHeight * 0.17
        : isTablet
        ? 138
        : 145;

    return Scaffold(
      backgroundColor: BookingModalStyles.pageBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: fadeAnim,
          child: SlideTransition(
            position: slideAnim,
            child: Center(
              child: SizedBox(
                width: stageWidth,
                height: stageHeight,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    IgnorePointer(
                      child: Center(
                        child: Image.asset(
                          'assets/booking.png',
                          width: frameWidth,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: frameWidth * 0.82,
                              height: stageHeight * 0.82,
                              decoration: BookingModalStyles.frameFallback,
                            );
                          },
                        ),
                      ),
                    ),
                    Positioned(
                      top: formTop,
                      child: SizedBox(
                        width: formWidth,
                        height: formHeight,
                        child: Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(isMobile ? 10 : 12),
                              decoration: BookingModalStyles.headerCard,
                              child: Row(
                                children: [
                                  buildLogo(isMobile ? 30 : 36),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Booking Assistant',
                                          style: BookingModalStyles.title,
                                        ),
                                        const SizedBox(height: 2),
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
                                      vertical: 6,
                                    ),
                                    decoration: BookingModalStyles.statusChip,
                                    child: Text(
                                      'Booking',
                                      style: BookingModalStyles.chipText,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(isMobile ? 10 : 14),
                                decoration: BookingModalStyles.chatArea,
                                child: ListView(
                                  controller: scrollController,
                                  padding: EdgeInsets.zero,
                                  children: [
                                    buildSuccessBubble(
                                      'You selected Booking ✅',
                                    ),
                                    buildAiBubble(
                                      text:
                                          'Please fill in the booking details below.',
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
                                            isMobile ? 12 : 16,
                                          ),
                                          decoration:
                                              BookingModalStyles.formCard,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Booking Information',
                                                style: BookingModalStyles
                                                    .sectionTitle,
                                              ),
                                              const SizedBox(height: 12),
                                              buildTextField(
                                                label: 'Full Name',
                                                controller: fullNameController,
                                                hintText: 'Enter full name',
                                                errorText: fullNameError,
                                              ),
                                              const SizedBox(height: 12),
                                              buildTextField(
                                                label: 'Contact Number',
                                                controller:
                                                    contactNumberController,
                                                hintText:
                                                    'Enter contact number',
                                                errorText: contactNumberError,
                                                keyboardType:
                                                    TextInputType.phone,
                                              ),
                                              const SizedBox(height: 12),
                                              buildDropdownField(
                                                label: 'Customer Type',
                                                valueText: customerTypeText(
                                                  selectedCustomerType,
                                                ),
                                                onTap: pickCustomerType,
                                                errorText: customerTypeError,
                                              ),
                                              const SizedBox(height: 12),
                                              buildDropdownField(
                                                label: 'ID',
                                                valueText: idTypeText(
                                                  selectedIdType,
                                                ),
                                                onTap: pickIdType,
                                                errorText: idTypeError,
                                              ),
                                              const SizedBox(height: 12),
                                              buildDropdownField(
                                                label: 'Reservation',
                                                valueText: reservationTypeText(
                                                  selectedReservationType,
                                                ),
                                                onTap: pickReservationType,
                                                errorText: reservationTypeError,
                                              ),
                                              if (shouldShowOpenTime) ...[
                                                const SizedBox(height: 12),
                                                buildDropdownField(
                                                  label: 'Open Time',
                                                  valueText: openTimeText(
                                                    selectedOpenTimeType,
                                                  ),
                                                  onTap: pickOpenTimeType,
                                                  errorText: openTimeError,
                                                ),
                                              ],
                                              if (shouldShowReservationFields) ...[
                                                const SizedBox(height: 12),
                                                buildDropdownField(
                                                  label:
                                                      'Reservation Date Range',
                                                  valueText:
                                                      reservationRangeText(
                                                        selectedReservationRange,
                                                      ),
                                                  emptyText:
                                                      'Pick reservation date range',
                                                  onTap: pickReservationRange,
                                                  icon: Icons
                                                      .calendar_month_rounded,
                                                  errorText:
                                                      reservationRangeError,
                                                ),
                                                const SizedBox(height: 12),
                                                buildDropdownField(
                                                  label:
                                                      'Time Started (Reservation)',
                                                  valueText:
                                                      reservationStartTimeText(
                                                        selectedReservationStartTime,
                                                      ),
                                                  emptyText:
                                                      'Pick reservation time',
                                                  onTap:
                                                      pickReservationStartTime,
                                                  icon:
                                                      Icons.access_time_rounded,
                                                  errorText:
                                                      reservationStartTimeError,
                                                ),
                                              ],
                                              if (shouldShowSeatField) ...[
                                                const SizedBox(height: 12),
                                                buildDropdownField(
                                                  label: 'Seat Number',
                                                  valueText: seatText(),
                                                  emptyText: 'Pick seat number',
                                                  onTap: pickSeats,
                                                  icon:
                                                      Icons.event_seat_rounded,
                                                  errorText: seatNumberError,
                                                ),
                                              ],
                                              if (shouldShowTimeAvail) ...[
                                                const SizedBox(height: 12),
                                                buildDropdownField(
                                                  label:
                                                      'Time Avail (HH:MM or hours)',
                                                  valueText:
                                                      timeAvailController.text,
                                                  emptyText:
                                                      'Pick time available',
                                                  onTap: pickTimeAvail,
                                                  icon: Icons.schedule_rounded,
                                                  errorText: timeAvailError,
                                                ),
                                              ],
                                              const SizedBox(height: 16),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: isSubmitting
                                                          ? null
                                                          : submitForm,
                                                      style: BookingModalStyles
                                                          .primaryButton,
                                                      child: isSubmitting
                                                          ? const SizedBox(
                                                              width: 22,
                                                              height: 22,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2.4,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                            )
                                                          : const Text(
                                                              'Submit',
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
                                    if (submitted &&
                                        generatedBookingCode != null) ...[
                                      const SizedBox(height: 12),
                                      buildAiBubble(
                                        text:
                                            'Your booking information has been received successfully.',
                                      ),
                                      buildCodeBubble(generatedBookingCode!),
                                      if (aiFinalMessage != null)
                                        buildAiBubble(text: aiFinalMessage!),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: closeBottom,
                      child: SizedBox(
                        width: formWidth * 0.88,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: BookingModalStyles.secondaryButton,
                          child: const Text('Close'),
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
              decoration: InputDecoration(
                hintText: 'Example: 02:00 or 2 hours',
                hintStyle: const TextStyle(
                  color: Color(0xFF9BA3B2),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(
                    color: Colors.black.withOpacity(0.07),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: BookingModalStyles.primary,
                    width: 1.6,
                  ),
                ),
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
