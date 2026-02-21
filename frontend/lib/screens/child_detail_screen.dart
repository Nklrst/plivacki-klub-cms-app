import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../models/schedule.dart';
import '../models/enrollment.dart';
import '../models/skill.dart';
import '../providers/member_provider.dart';

class ChildDetailScreen extends StatefulWidget {
  final Member member;

  const ChildDetailScreen({super.key, required this.member});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  bool _isLoading = true;
  List<Enrollment> _enrollments = [];
  List<Skill> _allSkills = [];
  Set<int> _acquiredSkillIds = {};

  @override
  void initState() {
    super.initState();
    // Učitavamo podatke čim se ekran otvori
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<MemberProvider>(context, listen: false);
    try {
      final enrollments = await provider.fetchEnrollments(widget.member.id);
      final skills = await provider.fetchAllSkills();
      final memberSkills = await provider.fetchMemberSkills(widget.member.id);

      if (mounted) {
        setState(() {
          _enrollments = enrollments;
          _allSkills = skills;
          _acquiredSkillIds = memberSkills.map((ms) => ms.skillId).toSet();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- DIALOG ZA IZMENU PROFILA ---
  void _showEditProfileDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.member.fullName);
    final notesController = TextEditingController(text: widget.member.notes);
    DateTime selectedDate = widget.member.dateOfBirth;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Izmeni podatke"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Ime i prezime"),
              ),
              const SizedBox(height: 15),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: "Datum rođenja",
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: "Beleške (npr. alergije)",
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Otkaži"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Provider.of<MemberProvider>(
                    context,
                    listen: false,
                  ).updateMember(
                    widget.member.id,
                    nameController.text,
                    selectedDate,
                    notesController.text.isEmpty ? null : notesController.text,
                  );
                  if (mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profil ažuriran!")),
                    );
                    _fetchData(); // Osveži podatke
                  }
                } catch (e) {
                  // Error handling
                }
              },
              child: const Text("Sačuvaj"),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG ZA UPIS (POPRAVLJEN DIZAJN I LOKACIJA) ---
  Future<void> _showEnrollDialog(BuildContext context) async {
    final memberProvider = Provider.of<MemberProvider>(context, listen: false);
    List<Schedule> schedules = [];

    try {
      schedules = await memberProvider.fetchSchedules();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Greška pri učitavanju rasporeda.")),
        );
      }
      return;
    }

    if (!mounted) return;

    Schedule? selectedSchedule;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Odaberi termine"), // Vraćeno na staro
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (schedules.isEmpty)
                const Text("Nema dostupnih grupa.")
              else
                DropdownButton<Schedule>(
                  isExpanded: true,
                  hint: const Text("Izaberite termin"),
                  value: selectedSchedule,
                  items: schedules.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        // [FIX] Prikazujemo i LOKACIJU
                        "${s.dayName} ${s.formattedTime} • ${s.location}",
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedSchedule = val;
                    });
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text("Otkaži"),
            ),
            ElevatedButton(
              onPressed: selectedSchedule == null
                  ? null
                  : () async {
                      try {
                        await memberProvider.enrollMember(
                          widget.member.id,
                          selectedSchedule!.id,
                          DateTime.now(),
                        );
                        if (mounted) {
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Uspešno upisano!")),
                          );
                          _fetchData(); // Osveži prikaz
                        }
                      } catch (e) {
                        // Error handling
                      }
                    },
              child: const Text("Sačuvaj"),
            ),
          ],
        ),
      ),
    );
  }

  // --- DIALOG ZA ZAHTEV ZA PROMENU ---
  void _showChangeRequestDialog(BuildContext context) {
    final noteController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Promena termina"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Za promenu fiksnog termina, pošaljite zahtev administratoru.",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "Razlog promene / Željeni termin...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Odustani"),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<MemberProvider>(
                context,
                listen: false,
              ).sendScheduleRequest(noteController.text);
              if (mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Zahtev poslat!")));
              }
            },
            child: const Text("Pošalji"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.fullName),
        backgroundColor: const Color(0xFF005696),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch, // [FIX] Vraćeno rastezanje
                children: [
                  // --- OSNOVNI PODACI ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Osnovni Podaci",
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF005696),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Color(0xFF005696),
                              ),
                              onPressed: () => _showEditProfileDialog(context),
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        _buildInfoRow(
                          "Datum rođenja:",
                          "${widget.member.dateOfBirth.day}.${widget.member.dateOfBirth.month}.${widget.member.dateOfBirth.year}",
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          "Napomene:",
                          widget.member.notes?.isNotEmpty == true
                              ? widget.member.notes!
                              : "Nema napomena",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --- RASPORED TRENINGA ---
                  const Text(
                    "Raspored Treninga",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (_enrollments.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 40,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Dete nije upisano ni u jednu grupu.",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _showEnrollDialog(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005696),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text(
                              "Odaberi termine",
                            ), // [FIX] Vraćen tekst
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // Prikaz postojećih termina
                    ..._enrollments.map((enrollment) {
                      if (enrollment.schedule == null) {
                        return const SizedBox.shrink();
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // [FIX] Vraćena LOKACIJA u prikaz kartice
                                    "${enrollment.schedule!.dayName} ${enrollment.schedule!.formattedTime} • ${enrollment.schedule!.location}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Grupa: ${enrollment.schedule!.groupName}",
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _showChangeRequestDialog(context),
                              child: const Text(
                                "Promeni",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Dugme za dodavanje drugog termina (ako ih je manje od 2)
                    if (_enrollments.length < 2)
                      ElevatedButton.icon(
                        onPressed: () => _showEnrollDialog(context),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Dodaj drugi termin"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF005696),
                          foregroundColor: Colors.white,
                        ),
                      ),

                    if (_enrollments.length >= 2)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: Text(
                            "Maksimalan broj termina (2) je dostignut.",
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 20),

                  // --- NAPREDAK (VEŠTINE) ---
                  const Text(
                    "Napredak (Savladani elementi)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (_allSkills.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Nema definisanih veština u sistemu.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true, // Bitno da ne puca scroll
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _allSkills.length,
                      itemBuilder: (context, index) {
                        final skill = _allSkills[index];
                        final isAcquired = _acquiredSkillIds.contains(skill.id);

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isAcquired
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: isAcquired ? Colors.green : Colors.grey[400],
                          ),
                          title: Text(
                            skill.name,
                            style: TextStyle(
                              fontWeight: isAcquired
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isAcquired
                                  ? Colors.black87
                                  : Colors.black54,
                            ),
                          ),
                          subtitle: Text(
                            skill.category,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
