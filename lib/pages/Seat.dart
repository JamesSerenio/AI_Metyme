import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../styles/Seat_styles.dart';

enum SeatStatus { tempAvailable, occupiedTemp, occupied, reserved }

enum PinKind { seat, room }

class SeatPin {
  final String id;
  final String label;
  final double x;
  final double y;
  final PinKind kind;
  final bool readonly;
  final SeatStatus? fixedStatus;

  const SeatPin({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    required this.kind,
    this.readonly = false,
    this.fixedStatus,
  });
}

class SeatBlockedRow {
  final String seatNumber;
  final String startAt;
  final String endAt;
  final String source;
  final String? note;

  const SeatBlockedRow({
    required this.seatNumber,
    required this.startAt,
    required this.endAt,
    required this.source,
    required this.note,
  });

  factory SeatBlockedRow.fromMap(Map<String, dynamic> map) {
    return SeatBlockedRow(
      seatNumber: (map['seat_number'] ?? '').toString(),
      startAt: (map['start_at'] ?? '').toString(),
      endAt: (map['end_at'] ?? '').toString(),
      source: (map['source'] ?? '').toString(),
      note: map['note']?.toString(),
    );
  }
}

class SeatPage extends StatefulWidget {
  final int pollMs;

  const SeatPage({super.key, this.pollMs = 15000});

  @override
  State<SeatPage> createState() => _SeatPageState();
}

class _SeatPageState extends State<SeatPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final String conferenceId = 'CONFERENCE_ROOM';

  late final List<SeatPin> pins;

  Map<String, SeatStatus> statusBySeat = {};
  DateTime now = DateTime.now();
  bool loading = true;

  late final AnimationController pageController;
  late final Animation<double> fadeAnim;
  late final Animation<Offset> slideAnim;

  Timer? clockTimer;
  Timer? pollTimer;

  @override
  void initState() {
    super.initState();

    pins = [
      const SeatPin(
        id: 'CONFERENCE_ROOM',
        label: 'CONFERENCE ROOM',
        x: 38.5,
        y: 23.5,
        kind: PinKind.room,
      ),

      const SeatPin(id: '6', label: '6', x: 44.7, y: 31, kind: PinKind.seat),
      const SeatPin(id: '5', label: '5', x: 48.5, y: 31, kind: PinKind.seat),
      const SeatPin(id: '4', label: '4', x: 52.4, y: 31, kind: PinKind.seat),
      const SeatPin(id: '3', label: '3', x: 56.2, y: 31, kind: PinKind.seat),
      const SeatPin(id: '2', label: '2', x: 64.6, y: 31, kind: PinKind.seat),
      const SeatPin(id: '1', label: '1', x: 68.4, y: 31, kind: PinKind.seat),

      const SeatPin(id: '11', label: '11', x: 29.5, y: 42, kind: PinKind.seat),
      const SeatPin(id: '10', label: '10', x: 36, y: 44, kind: PinKind.seat),
      const SeatPin(id: '9', label: '9', x: 38.4, y: 39.5, kind: PinKind.seat),

      const SeatPin(id: '8A', label: '8A', x: 46, y: 40, kind: PinKind.seat),
      const SeatPin(id: '8B', label: '8B', x: 46, y: 44.5, kind: PinKind.seat),

      const SeatPin(id: '7A', label: '7A', x: 55.5, y: 40, kind: PinKind.seat),
      const SeatPin(
        id: '7B',
        label: '7B',
        x: 55.5,
        y: 44.5,
        kind: PinKind.seat,
      ),

      const SeatPin(
        id: '13',
        label: '13',
        x: 45.5,
        y: 62.2,
        kind: PinKind.seat,
      ),

      const SeatPin(
        id: '14',
        label: '14',
        x: 49.7,
        y: 53.5,
        kind: PinKind.seat,
      ),
      const SeatPin(
        id: '15',
        label: '15',
        x: 53.5,
        y: 53.5,
        kind: PinKind.seat,
      ),
      const SeatPin(
        id: '16',
        label: '16',
        x: 57.3,
        y: 53.5,
        kind: PinKind.seat,
      ),
      const SeatPin(
        id: '17',
        label: '17',
        x: 61.2,
        y: 53.5,
        kind: PinKind.seat,
      ),

      const SeatPin(id: '25', label: '25', x: 54, y: 62, kind: PinKind.seat),

      const SeatPin(
        id: '18',
        label: '18',
        x: 49.5,
        y: 70.5,
        kind: PinKind.seat,
      ),
      const SeatPin(
        id: '19',
        label: '19',
        x: 54.5,
        y: 70.5,
        kind: PinKind.seat,
      ),
      const SeatPin(
        id: '20',
        label: '20',
        x: 60.3,
        y: 70.5,
        kind: PinKind.seat,
      ),

      const SeatPin(id: '24', label: '24', x: 76, y: 56.7, kind: PinKind.seat),
      const SeatPin(
        id: '23',
        label: '23',
        x: 81.5,
        y: 59.5,
        kind: PinKind.seat,
      ),
      const SeatPin(id: '22', label: '22', x: 65.2, y: 66, kind: PinKind.seat),
      const SeatPin(id: '21', label: '21', x: 69, y: 69.5, kind: PinKind.seat),

      const SeatPin(
        id: '12A',
        label: '12A',
        x: 27.3,
        y: 68,
        kind: PinKind.seat,
      ),
      const SeatPin(
        id: '12B',
        label: '12B',
        x: 31.3,
        y: 69,
        kind: PinKind.seat,
      ),
      const SeatPin(
        id: '12C',
        label: '12C',
        x: 35.5,
        y: 70,
        kind: PinKind.seat,
      ),
    ];

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

    _loadSeatStatuses();

    clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {
        now = DateTime.now();
      });
    });

    pollTimer = Timer.periodic(
      Duration(milliseconds: widget.pollMs < 3000 ? 3000 : widget.pollMs),
      (_) => _loadSeatStatuses(),
    );
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    pollTimer?.cancel();
    pageController.dispose();
    super.dispose();
  }

  List<String> get seatIdsOnly {
    return pins
        .where((p) => p.kind == PinKind.seat && !p.readonly)
        .map((p) => p.id)
        .toList();
  }

  List<String> get blockedIds => [...seatIdsOnly, conferenceId];

  String farFutureIso() {
    return DateTime(2999, 12, 31, 23, 59, 59).toUtc().toIso8601String();
  }

  String normalizeSeatId(String value) {
    return value.trim().toUpperCase();
  }

  bool isTempMirrorRow(String? note) {
    return (note ?? '').trim().toLowerCase() == 'temp';
  }

  bool isAutoReservationRow(String? note) {
    return (note ?? '').trim().toLowerCase() == 'reservation';
  }

  Future<void> _loadSeatStatuses() async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final endIso = farFutureIso();

    if (mounted) {
      setState(() {
        loading = true;
      });
    }

    try {
      final blockedData = await supabase
          .from('seat_blocked_times')
          .select('seat_number, start_at, end_at, source, note')
          .inFilter('seat_number', blockedIds)
          .lt('start_at', endIso)
          .gt('end_at', nowIso);

      final Map<String, SeatStatus> next = {
        for (final pin in pins) pin.id: SeatStatus.tempAvailable,
      };

      final rows = (blockedData as List<dynamic>)
          .map((e) => SeatBlockedRow.fromMap(e as Map<String, dynamic>))
          .toList();

      final bySeat = <String, SeatStatus>{};

      for (final row in rows) {
        if (isTempMirrorRow(row.note)) continue;
        if (isAutoReservationRow(row.note)) continue;

        final id = normalizeSeatId(row.seatNumber);

        if (row.source == 'reserved') {
          bySeat[id] = SeatStatus.reserved;
          continue;
        }

        if (row.source == 'regular') {
          if (bySeat[id] != SeatStatus.reserved) {
            bySeat[id] = SeatStatus.occupied;
          }
          continue;
        }

        if (bySeat[id] != SeatStatus.reserved) {
          bySeat[id] = SeatStatus.occupied;
        }
      }

      for (final id in blockedIds.map((e) => e.toUpperCase())) {
        if (bySeat[id] != null) {
          next[id] = bySeat[id]!;
        }
      }

      if (!mounted) return;
      setState(() {
        statusBySeat = next;
        now = DateTime.now();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }

  String formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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

    final weekday = weekdays[(date.weekday - 1).clamp(0, 6)];
    final month = months[(date.month - 1).clamp(0, 11)];

    return '$weekday, $month ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  Color statusColor(SeatStatus status) {
    switch (status) {
      case SeatStatus.tempAvailable:
        return SeatStyles.greenSeat;
      case SeatStatus.occupiedTemp:
        return SeatStyles.yellowSeat;
      case SeatStatus.occupied:
        return SeatStyles.redSeat;
      case SeatStatus.reserved:
        return SeatStyles.purpleSeat;
    }
  }

  Widget buildPinWidget(SeatPin pin, bool isMobile) {
    final status =
        pin.fixedStatus ?? statusBySeat[pin.id] ?? SeatStatus.tempAvailable;
    final color = statusColor(status);
    final isRoom = pin.kind == PinKind.room;

    return FractionalTranslation(
      translation: const Offset(-0.5, -0.5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: isRoom ? (isMobile ? 100 : 120) : (isMobile ? 18 : 16),
        height: isRoom ? (isMobile ? 20 : 20) : (isMobile ? 18 : 16),
        alignment: Alignment.center,
        decoration: isRoom
            ? SeatStyles.roomDecoration(color)
            : SeatStyles.pinDecoration(color),
        child: Text(
          pin.label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: isRoom
              ? SeatStyles.roomLabel.copyWith(fontSize: 8)
              : SeatStyles.seatLabel.copyWith(fontSize: 6.3),
        ),
      ),
    );
  }

  Widget legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withOpacity(0.08)),
          ),
        ),
        const SizedBox(width: 8),
        Text(text, style: SeatStyles.legendText),
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
        ? 860
        : 920;

    return Scaffold(
      backgroundColor: SeatStyles.pageBg,
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
                decoration: SeatStyles.modalCard,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: SeatStyles.headerCard,
                      child: Row(
                        children: [
                          Container(
                            width: isMobile ? 42 : 48,
                            height: isMobile ? 42 : 48,
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
                                errorBuilder: (_, __, ___) {
                                  return const Icon(
                                    Icons.image_not_supported_outlined,
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Seat View', style: SeatStyles.title),
                                const SizedBox(height: 4),
                                Text(
                                  'View live seat availability and reservation status.',
                                  style: SeatStyles.subtitle,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: SeatStyles.statusChip,
                            child: Text('Live Map', style: SeatStyles.chipText),
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
                        decoration: SeatStyles.stageCard,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Seat Map',
                                  style: SeatStyles.sectionTitle,
                                ),
                                const Spacer(),
                                Text(
                                  formatDate(now),
                                  style: SeatStyles.dateText,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Center(
                                            child: Transform.scale(
                                              scale: isMobile ? 1.0 : 1.0,
                                              child: Image.asset(
                                                'assets/seats.png',
                                                width: constraints.maxWidth,
                                                height: constraints.maxHeight,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) {
                                                  return const Center(
                                                    child: Text(
                                                      'seats.png not found',
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                        ...pins.map((pin) {
                                          return Positioned(
                                            left:
                                                constraints.maxWidth *
                                                (pin.x / 100),
                                            top:
                                                constraints.maxHeight *
                                                (pin.y / 100),
                                            child: buildPinWidget(
                                              pin,
                                              isMobile,
                                            ),
                                          );
                                        }),
                                        if (loading)
                                          Positioned.fill(
                                            child: Container(
                                              color: Colors.white.withOpacity(
                                                0.18,
                                              ),
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: SeatStyles.legendCard,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 18,
                                runSpacing: 10,
                                children: [
                                  legendItem(SeatStyles.greenSeat, 'Available'),
                                  legendItem(
                                    SeatStyles.yellowSeat,
                                    'Occupied Temporarily',
                                  ),
                                  legendItem(SeatStyles.redSeat, 'Occupied'),
                                  legendItem(SeatStyles.purpleSeat, 'Reserved'),
                                ],
                              ),
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
                            style: SeatStyles.secondaryButton,
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
