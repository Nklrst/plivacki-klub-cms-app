import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../models/schedule.dart';
import 'attendance_screen.dart';
import 'notifications_screen.dart';
import '../providers/notification_provider.dart';

class CoachDashboard extends StatefulWidget {
  const CoachDashboard({super.key});

  @override
  State<CoachDashboard> createState() => _CoachDashboardState();
}

class _CoachDashboardState extends State<CoachDashboard> {
  bool _isLoading = true;
  List<Schedule> _schedules = [];

  // ── Day-of-week mapping ──────────────────────────────────────
  static const Map<String, int> _dayMap = {
    'PON': 1,
    'PONEDELJAK': 1,
    'MONDAY': 1,
    'MON': 1,
    'UTO': 2,
    'UTORAK': 2,
    'TUESDAY': 2,
    'TUE': 2,
    'SRE': 3,
    'SREDA': 3,
    'WEDNESDAY': 3,
    'WED': 3,
    'CET': 4,
    'CETVRTAK': 4,
    'THURSDAY': 4,
    'THU': 4,
    'PET': 5,
    'PETAK': 5,
    'FRIDAY': 5,
    'FRI': 5,
    'SUB': 6,
    'SUBOTA': 6,
    'SATURDAY': 6,
    'SAT': 6,
    'NED': 7,
    'NEDELJA': 7,
    'SUNDAY': 7,
    'SUN': 7,
  };

  static const Map<int, String> _dayNamesSrb = {
    1: 'Ponedeljak',
    2: 'Utorak',
    3: 'Sreda',
    4: 'Četvrtak',
    5: 'Petak',
    6: 'Subota',
    7: 'Nedelja',
  };

  int? _parseWeekday(String dayCode) {
    return _dayMap[dayCode.toUpperCase().trim()];
  }

  /// Returns the next occurrence of [targetWeekday] from today.
  /// If today IS that day, returns today.
  DateTime _getNextDateForDay(int targetWeekday) {
    final now = DateTime.now();
    int diff = targetWeekday - now.weekday;
    if (diff < 0) diff += 7;
    if (diff == 0) return now; // Today IS that day
    return now.add(Duration(days: diff));
  }

  @override
  void initState() {
    super.initState();
    _fetchSchedules();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(context, listen: false).fetchMessages();
    });
  }

  Future<void> _fetchSchedules() async {
    try {
      final fetched = await Provider.of<MemberProvider>(
        context,
        listen: false,
      ).fetchSchedules();

      if (mounted) {
        setState(() {
          _schedules = fetched;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Greška pri učitavanju termina: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.user?.fullName ?? 'Trener';
    final now = DateTime.now();
    final todayWeekday = now.weekday;
    final todayName = _dayNamesSrb[todayWeekday] ?? '';
    final todayFormatted = DateFormat('dd.MM.yyyy').format(now);

    // Split schedules into today vs. other
    final todaySchedules = <Schedule>[];
    final otherSchedules = <Schedule>[];
    for (final s in _schedules) {
      final wd = _parseWeekday(s.dayOfWeek);
      if (wd == todayWeekday) {
        todaySchedules.add(s);
      } else {
        otherSchedules.add(s);
      }
    }

    // Sort "others" by next occurrence (soonest first)
    otherSchedules.sort((a, b) {
      final dateA = _getNextDateForDay(_parseWeekday(a.dayOfWeek) ?? 8);
      final dateB = _getNextDateForDay(_parseWeekday(b.dayOfWeek) ?? 8);
      return dateA.compareTo(dateB);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trenerski Panel"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationProvider>(
            builder: (ctx, notif, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  ),
                ),
                if (notif.hasUnread)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
          ? const Center(child: Text("Nema aktivnih rasporeda."))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── WELCOME HEADER ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF005696), Color(0xFF0077CC)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Dobrodošli!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Image.asset(
                            'assets/images/logo_white.png',
                            height: 32,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Prijavljen kao: $userName",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Danas je $todayName, $todayFormatted.",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── SECTION A: TODAY'S TRAININGS ────────────
                if (todaySchedules.isNotEmpty) ...[
                  _buildSectionHeader(
                    "DANAŠNJI TRENINZI",
                    Icons.flash_on,
                    Colors.green.shade700,
                  ),
                  const SizedBox(height: 8),
                  ...todaySchedules.map((s) => _buildTodayCard(context, s)),
                  const SizedBox(height: 20),
                ],

                if (todaySchedules.isEmpty) ...[
                  Card(
                    color: Colors.grey.shade100,
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey),
                          SizedBox(width: 12),
                          Text("Danas nema zakazanih treninga."),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── SECTION B: OTHER SCHEDULES ──────────────
                if (otherSchedules.isNotEmpty) ...[
                  _buildSectionHeader(
                    "OSTALI TERMINI",
                    Icons.calendar_month,
                    Colors.grey.shade700,
                  ),
                  const SizedBox(height: 8),
                  ...otherSchedules.map((s) => _buildOtherCard(context, s)),
                ],
              ],
            ),
    );
  }

  // ─── Section Header ──────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  // ─── TODAY Card (highlighted) ────────────────────────────────
  Widget _buildTodayCard(BuildContext context, Schedule schedule) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade400, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttendanceScreen(schedule: schedule),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.pool, color: Colors.green),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.groupName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${schedule.startTime} - ${schedule.endTime}",
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      schedule.location,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "DANAS",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ─── OTHER Card (with next date) ─────────────────────────────
  Widget _buildOtherCard(BuildContext context, Schedule schedule) {
    final wd = _parseWeekday(schedule.dayOfWeek);
    String nextDateStr = schedule.dayOfWeek;

    if (wd != null) {
      final nextDate = _getNextDateForDay(wd);
      final fullDayName = _dayNamesSrb[wd] ?? schedule.dayOfWeek;
      nextDateStr = "$fullDayName (${DateFormat('dd.MM.').format(nextDate)})";
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AttendanceScreen(schedule: schedule),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.pool, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.groupName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$nextDateStr  •  ${schedule.startTime} - ${schedule.endTime}",
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    Text(
                      schedule.location,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
