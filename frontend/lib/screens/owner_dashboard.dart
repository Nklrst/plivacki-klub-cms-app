import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';
import '../providers/owner_provider.dart';
import 'owner/members_screen.dart';
import 'owner/staff_screen.dart';
import 'owner/notifications_screen.dart';
import 'owner/schedules_screen.dart';
import 'owner/finance_screen.dart';
import 'owner/settings_screen.dart';
import 'notifications_screen.dart' as inbox;
import '../providers/notification_provider.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<OwnerProvider>(context, listen: false).fetchDashboardData();
      Provider.of<NotificationProvider>(context, listen: false).fetchMessages();
    });
  }

  static const Map<int, String> _dayNamesSrb = {
    1: 'Ponedeljak',
    2: 'Utorak',
    3: 'Sreda',
    4: 'Četvrtak',
    5: 'Petak',
    6: 'Subota',
    7: 'Nedelja',
  };

  void _showEditNameDialog(BuildContext context, AuthProvider auth) {
    final controller = TextEditingController(text: auth.user?.fullName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vlasnik Kluba:'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Novo ime',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Wire to backend PUT /users/me or similar route
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ime sačuvano (lokalno).')),
              );
            },
            child: const Text('Sačuvaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final owner = Provider.of<OwnerProvider>(context);
    final userName = auth.user?.fullName ?? 'Vlasnik';
    final now = DateTime.now();
    final todayName = _dayNamesSrb[now.weekday] ?? '';
    final todayFormatted = DateFormat('dd.MM.yyyy').format(now);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kontrolna Tabla"),
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
                      builder: (_) => const inbox.NotificationsScreen(),
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
            icon: const Icon(Icons.refresh),
            onPressed: () => owner.fetchDashboardData(),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF005696), Color(0xFF0077CC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF005696)),
              ),
              accountName: Row(
                children: [
                  Flexible(
                    child: Text(
                      auth.user?.fullName ?? 'Vlasnik',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (auth.user?.role == UserRole.OWNER)
                    GestureDetector(
                      onTap: () => _showEditNameDialog(context, auth),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.edit, size: 20, color: Colors.white),
                      ),
                    ),
                ],
              ),
              accountEmail: Text(auth.user?.email ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Podešavanja'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Pravila privatnosti'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Uskoro!')));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Uslovi korišćenja'),
              onTap: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Uskoro!')));
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Odjavi se',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.of(context).pop();
                auth.logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      body: owner.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => owner.fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 24),

                    // ── SECTION A: QUICK STATS ──────────────
                    _buildSectionHeader(
                      "STATISTIKA",
                      Icons.analytics,
                      Colors.indigo,
                    ),
                    const SizedBox(height: 12),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStatCard(
                            icon: Icons.people,
                            label: "Aktivni Članovi",
                            value: "${owner.stats?.activeMembers ?? 0}",
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.check_circle,
                            label: "Današnji Dolasci",
                            value: "${owner.stats?.attendanceToday ?? 0}",
                            color: Colors.green,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            icon: Icons.payments,
                            label: "Prihod (Feb)",
                            value: "${owner.stats?.revenueMonth ?? 0} RSD",
                            color: Colors.orange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── SECTION B: NAVIGATION GRID ──────────
                    _buildSectionHeader(
                      "UPRAVLJANJE",
                      Icons.dashboard,
                      Colors.grey.shade700,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _buildNavCard(
                          icon: Icons.calendar_month,
                          label: "Termini &\nRaspored",
                          color: Colors.blue,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SchedulesScreen(),
                              ),
                            );
                          },
                        ),
                        _buildNavCard(
                          icon: Icons.payments,
                          label: "Finansije &\nČlanarine",
                          color: Colors.green,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FinanceScreen(),
                              ),
                            );
                          },
                        ),
                        _buildNavCard(
                          icon: Icons.groups,
                          label: "Plivači",
                          color: Colors.orange,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MembersScreen(),
                              ),
                            );
                          },
                        ),
                        _buildNavCard(
                          icon: Icons.sports,
                          label: "Treneri",
                          color: Colors.teal,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const StaffScreen(),
                              ),
                            );
                          },
                        ),
                        _buildNavCard(
                          icon: Icons.notifications,
                          label: "Obaveštenja",
                          color: Colors.purple,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // ── SECTION C: TODAY'S TRAININGS ─────────
                    _buildSectionHeader(
                      "DANAŠNJI TRENINZI",
                      Icons.flash_on,
                      Colors.green.shade700,
                    ),
                    const SizedBox(height: 12),
                    if (owner.todaySchedules.isEmpty)
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
                    ...owner.todaySchedules.map((s) => _buildTrainingCard(s)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Helpers ────────────────────────────────────────────────

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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          height: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: color.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrainingCard(TodaySchedule schedule) {
    final isActive = schedule.presentCount > 0;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isActive
                  ? Colors.green.shade100
                  : Colors.grey.shade200,
              child: Icon(
                Icons.pool,
                color: isActive ? Colors.green : Colors.grey,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.groupName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    schedule.time,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  if (schedule.location.isNotEmpty)
                    Text(
                      schedule.location,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? Colors.green.shade300
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                "${schedule.presentCount}/${schedule.enrolledCount}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isActive ? Colors.green.shade700 : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
