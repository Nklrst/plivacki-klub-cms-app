import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/attendance_provider.dart';
import '../providers/skills_provider.dart';
import '../models/schedule.dart';

class AttendanceScreen extends StatefulWidget {
  final Schedule schedule;

  const AttendanceScreen({super.key, required this.schedule});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Helper: parses schedule day string to DateTime weekday (1=Mon..7=Sun)
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
    'ČET': 4,
    'CETVRTAK': 4,
    'ČETVRTAK': 4,
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

  int? get _scheduleWeekday {
    final raw = widget.schedule.dayOfWeek.toUpperCase().trim();
    return _dayMap[raw];
  }

  /// Returns the nearest date matching [targetWeekday] relative to [reference].
  DateTime _nearestMatchingDate(int targetWeekday, DateTime reference) {
    int diff = targetWeekday - reference.weekday;
    if (diff < 0) diff += 7;
    return DateTime(reference.year, reference.month, reference.day + diff);
  }

  @override
  void initState() {
    super.initState();
    // Set initial date to nearest valid training day
    final wd = _scheduleWeekday;
    if (wd != null) {
      _selectedDate = _nearestMatchingDate(wd, DateTime.now());
    }
    Future.microtask(() => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    await Provider.of<AttendanceProvider>(
      context,
      listen: false,
    ).fetchGroupMembers(widget.schedule.id, _selectedDate);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);
    try {
      final provider = Provider.of<AttendanceProvider>(context, listen: false);

      final presentIds = provider.attendanceList
          .where((att) => att.isPresent)
          .map((att) => att.memberId)
          .toList();

      await provider.saveAttendance(
        widget.schedule.id,
        _selectedDate,
        presentIds,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prisustvo uspešno sačuvano! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ─── Skills Dialog (Real Backend Data) ───────────────────────
  void _showSkillsDialog(int memberId, String memberName) async {
    final skillsProvider = Provider.of<SkillsProvider>(context, listen: false);

    // Show a loading dialog while fetching
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final skills = await skillsProvider.fetchMemberSkills(memberId);

    // Dismiss loading dialog
    if (mounted) Navigator.of(context).pop();

    if (skills.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Greška pri učitavanju veština.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Local copy for toggling inside the dialog
    final Map<int, bool> localState = {
      for (var s in skills) s.skillId: s.isMastered,
    };

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Veštine: $memberName',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: skills.map((skill) {
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          skill.skillName,
                          style: const TextStyle(fontSize: 14),
                        ),
                        value: localState[skill.skillId] ?? false,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          setDialogState(() {
                            localState[skill.skillId] = val ?? false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Odustani'),
                ),
                FilledButton(
                  onPressed: () async {
                    // Collect mastered skill IDs
                    final masteredIds = localState.entries
                        .where((e) => e.value)
                        .map((e) => e.key)
                        .toList();

                    try {
                      await skillsProvider.updateMemberSkills(
                        memberId,
                        masteredIds,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Veštine sačuvane! ✅'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Greška: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Sačuvaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Build ───────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AttendanceProvider>(context);
    final members = provider.attendanceList;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule.groupName),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final weekday = _scheduleWeekday;
              // Ensure initialDate satisfies the predicate
              DateTime validInitial = _selectedDate;
              if (weekday != null && _selectedDate.weekday != weekday) {
                validInitial = _nearestMatchingDate(weekday, _selectedDate);
              }
              final picked = await showDatePicker(
                context: context,
                initialDate: validInitial,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                selectableDayPredicate: weekday != null
                    ? (date) => date.weekday == weekday
                    : null, // Allow all days if parsing fails
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
                _fetchData();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── DATUM I BROJNOST ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.grey.shade200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Datum: ${DateFormat('dd.MM.yyyy').format(_selectedDate)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Prijavljeno: ${members.length}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // ── LISTA DECE ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : members.isEmpty
                ? const Center(child: Text("Nema upisane dece u ovu grupu."))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: members.length,
                    itemBuilder: (ctx, i) {
                      final item = members[i];
                      return _buildMemberCard(item, provider);
                    },
                  ),
          ),

          // ── SAVE BUTTON ──
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _saveAttendance,
                child: const Text(
                  "SAČUVAJ PRISUSTVO",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Health Card Dialog ──────────────────────────────────────
  void _showHealthDialog(AttendanceRecord item) {
    final hasNotes = item.medicalNotes != null && item.medicalNotes!.isNotEmpty;
    final hasPhone = item.parentPhone != null && item.parentPhone!.isNotEmpty;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.medical_information, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Zdravstveni Karton',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Child name
                Text(
                  item.memberName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.birthDate != null)
                  Text(
                    'Rođen/a: ${item.birthDate}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                const Divider(height: 24),

                // Section 1: Medical Notes
                const Text(
                  'Napomene:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  hasNotes ? item.medicalNotes! : 'Nema unetih napomena.',
                  style: TextStyle(
                    color: hasNotes ? Colors.red.shade700 : Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const Divider(height: 24),

                // Section 2: Parent Contact
                const Text(
                  'Kontakt Roditelja:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPhone ? item.parentPhone! : 'Telefon nije unet.',
                  style: TextStyle(
                    color: hasPhone ? Colors.black87 : Colors.grey,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (hasPhone)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Pozivanje ${item.parentPhone}...')),
                  );
                },
                icon: const Icon(Icons.phone, size: 16),
                label: const Text('Pozovi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Zatvori'),
            ),
          ],
        );
      },
    );
  }

  // ─── Custom Member Card ──────────────────────────────────────
  Widget _buildMemberCard(AttendanceRecord item, AttendanceProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // ── Avatar ──
            CircleAvatar(
              backgroundColor: item.isPresent
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              child: Text(
                item.memberName.isNotEmpty ? item.memberName[0] : "?",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: item.isPresent
                      ? Colors.green.shade800
                      : Colors.red.shade800,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Info (Name, DOB, ID) ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.memberName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.birthDate != null)
                    Text(
                      "Rođen/a: ${item.birthDate}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  Text(
                    "ID: ${item.memberId}",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // ── Actions ──
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Info Button
                  ElevatedButton.icon(
                    onPressed: () => _showHealthDialog(item),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text(
                      "Informacije o plivaču",
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Skills Button
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showSkillsDialog(item.memberId, item.memberName),
                    icon: const Icon(Icons.checklist, size: 16),
                    label: const Text(
                      "Savladani Elementi",
                      style: TextStyle(fontSize: 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Attendance Checkbox
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Prisutan",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      Checkbox(
                        value: item.isPresent,
                        activeColor: Colors.green,
                        onChanged: (val) {
                          provider.toggleAttendance(item.memberId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
