import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/member_provider.dart';
import '../models/member.dart';
import 'child_detail_screen.dart';
import 'notifications_screen.dart';
import '../../core/api_client.dart';
import '../providers/notification_provider.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  @override
  void initState() {
    super.initState();
    // Učitavamo podatke čim se ekran otvori
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).refreshUser();
      Provider.of<MemberProvider>(context, listen: false).fetchMyMembers();
      Provider.of<NotificationProvider>(context, listen: false).fetchMessages();
    });
  }

  // --- POPRAVLJENA LOGIKA ZA SLEDEĆI TRENING ---
  // Ovo zamenjuje onaj dugački blok koda koji je pravio problem
  // --- POPRAVLJENA LOGIKA ZA SLEDEĆI TRENING ---
  String getNextTrainingInfo(Member member) {
    if (member.enrollments.isEmpty) {
      return "Raspored nije dostupan";
    }

    final enrollment = member.enrollments.first;

    // [FIX] Provera: Ako je schedule slučajno null, ne pucamo
    if (enrollment.schedule == null) {
      return "Greška u rasporedu";
    }

    // [FIX] Koristimo '!' jer smo sigurni da nije null
    return "Sledeći: ${enrollment.schedule!.dayName} ${enrollment.schedule!.formattedTime}";
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final memberProvider = Provider.of<MemberProvider>(context);

    // Ime roditelja (Siguran pristup)
    final String parentName = authProvider.user?.fullName ?? "Roditelj";

    return Scaffold(
      appBar: AppBar(
        title: const Text("PK Ušće - Moj Profil"),
        backgroundColor: const Color(0xFF005696), // Tvoja plava boja
        foregroundColor: Colors.white,
        actions: [
          Consumer<NotificationProvider>(
            builder: (ctx, notif, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: "Obaveštenja",
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
            tooltip: "Odjavi se",
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- WELCOME SECTION ---
            // --- WELCOME HEADER ---
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
                      Image.asset('assets/images/logo_white.png', height: 32),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Prijavljen kao: $parentName",
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
                          DateFormat(
                            'EEEE, d. MMMM yyyy',
                          ).format(DateTime.now()),
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
            const SizedBox(height: 25),

            // --- HEADER ZA DECU ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Moja Deca",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _showAddChildDialog(context);
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Dodaj dete"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF005696),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // --- LISTA DECE ---
            if (memberProvider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (memberProvider.members.isEmpty)
              _buildEmptyState()
            else
              ...memberProvider.members.map(
                (member) => _buildChildCard(context, member: member),
              ),
          ],
        ),
      ),
    );
  }

  // --- ZADRŽANA FUNKCIJA ZA PRAZNO STANJE ---
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      child: Column(
        children: const [
          Icon(Icons.family_restroom, size: 60, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            "Nemate dodate dece.",
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // --- KARTICA DETETA (SA POPRAVLJENIM VREMENOM) ---
  Widget _buildChildCard(BuildContext context, {required Member member}) {
    // Koristimo novu helper funkciju umesto stare logike koja je pucala
    String nextSession = getNextTrainingInfo(member);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChildDetailScreen(member: member),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFFE3F2FD),
                    child: const Icon(Icons.pool, color: Color(0xFF005696)),
                  ),
                  const SizedBox(width: 15),
                  // Tekstualni podaci
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Status (možemo dodati isActive u Member model kasnije)
                        const Text(
                          "Aktivan član",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _PaymentStatusChip(memberId: member.id),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const Divider(height: 25),
              // Donji deo kartice (Sledeći trening)
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(
                    "Sledeći trening: $nextSession",
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- DIALOG ZA DODAVANJE DETETA (SA STATEFUL BUILDEROM) ---
  void _showAddChildDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Dodaj dete"),
        // StatefulBuilder je KLJUČAN ovde da bi se datum osvežio kad ga izabereš!
        content: StatefulBuilder(
          builder: (context, setState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: "Ime i prezime",
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Unesite ime i prezime";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    InkWell(
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().subtract(
                            const Duration(days: 365 * 6),
                          ),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (pickedDate != null) {
                          // Ovo osvežava samo Dialog, ne celu stranicu
                          setState(() {
                            selectedDate = pickedDate;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Datum rođenja",
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                          selectedDate == null
                              ? "Izaberite datum"
                              : "${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}",
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Beleške (opciono)",
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Otkaži"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Molimo izaberite datum rođenja"),
                    ),
                  );
                  return;
                }

                try {
                  await Provider.of<MemberProvider>(
                    context,
                    listen: false,
                  ).addMember(
                    nameController.text,
                    selectedDate!,
                    notesController.text.isEmpty ? null : notesController.text,
                  );

                  if (context.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Dete uspešno dodato!")),
                    );
                  }
                } catch (e) {
                  // Greška se već ispisuje u Provideru, ovde samo zatvaramo dialog ako treba
                  // ili prikazujemo snackbar.
                }
              }
            },
            child: const Text("Sačuvaj"),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusChip extends StatefulWidget {
  final int memberId;
  const _PaymentStatusChip({required this.memberId});

  @override
  State<_PaymentStatusChip> createState() => _PaymentStatusChipState();
}

class _PaymentStatusChipState extends State<_PaymentStatusChip> {
  bool? _isPaid;
  String? _monthName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final res = await api.dio.get('/payments/status/${widget.memberId}');
      if (mounted) {
        setState(() {
          _isPaid = res.data['is_paid'];
          _monthName = res.data['month_name'];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_isPaid == true) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              '$_monthName: PLAĆENO',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, color: Colors.orange.shade800, size: 14),
            const SizedBox(width: 4),
            Text(
              '$_monthName: ČEKA UPLATU',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }
}
