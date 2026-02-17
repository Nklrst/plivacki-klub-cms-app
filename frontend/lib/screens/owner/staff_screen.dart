import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_client.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _staff = [];

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  Future<void> _fetchStaff() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final responses = await Future.wait([
        api.dio.get('/users/', queryParameters: {'role': 'COACH'}),
        api.dio.get('/users/', queryParameters: {'role': 'OWNER'}),
      ]);

      final List<dynamic> coaches = responses[0].data;
      final List<dynamic> owners = responses[1].data;

      setState(() {
        _staff = [...owners, ...coaches].cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching staff: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showMessageDialog(String name) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pošalji poruku'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prima: $name', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Unesite poruku...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Poruka poslata: $name')));
            },
            child: const Text('Pošalji'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStaff(int userId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda Brisanja'),
        content: Text('Da li ste sigurni da želite da obrišete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      await api.dio.delete('/users/$userId');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name uspešno obrisan/a.')));
        _fetchStaff();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Greška: $e')));
      }
    }
  }

  // ─── Add Coach Dialog ─────────────────────────────────────

  void _showAddCoachDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novi Trener'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Ime i Prezime',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Lozinka',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty ||
                  emailCtrl.text.trim().isEmpty ||
                  passwordCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Popunite ime, email i lozinku.'),
                  ),
                );
                return;
              }

              Navigator.of(ctx).pop();

              try {
                final api = Provider.of<ApiClient>(context, listen: false);
                await api.dio.post(
                  '/users/admin-create',
                  data: {
                    'full_name': nameCtrl.text.trim(),
                    'email': emailCtrl.text.trim(),
                    'phone_number': phoneCtrl.text.trim().isNotEmpty
                        ? phoneCtrl.text.trim()
                        : null,
                    'password': passwordCtrl.text.trim(),
                    'role': 'COACH',
                  },
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Trener uspešno dodat!')),
                  );
                  _fetchStaff();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Greška: $e')));
                }
              }
            },
            child: const Text('Dodaj'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Treneri & Osoblje"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCoachDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _staff.isEmpty
          ? const Center(child: Text("Nema osoblja."))
          : RefreshIndicator(
              onRefresh: _fetchStaff,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _staff.length,
                itemBuilder: (ctx, i) => _buildStaffCard(_staff[i]),
              ),
            ),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> user) {
    final role = (user['role'] ?? '').toString().toUpperCase();
    final isOwner = role.contains('OWNER');
    final roleLabel = isOwner ? 'Vlasnik' : 'Trener';
    final roleColor = isOwner ? Colors.purple : Colors.teal;
    final name = user['full_name'] ?? '';
    final hasPhone =
        user['phone_number'] != null &&
        user['phone_number'].toString().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: roleColor.shade100,
              child: Icon(
                isOwner ? Icons.admin_panel_settings : Icons.sports,
                color: roleColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: roleColor.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: roleColor.shade200),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: roleColor.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (user['email'] != null)
                    Text(
                      user['email'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  Text(
                    hasPhone
                        ? "Tel: ${user['phone_number']}"
                        : "Telefon nije unet",
                    style: TextStyle(
                      fontSize: 12,
                      color: hasPhone ? Colors.blue.shade400 : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _showMessageDialog(name),
              icon: const Icon(Icons.message),
              color: Colors.blue,
              tooltip: 'Pošalji poruku',
            ),
            IconButton(
              onPressed: () => _deleteStaff(user['id'], name),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red.shade400,
              tooltip: 'Obriši',
            ),
          ],
        ),
      ),
    );
  }
}
