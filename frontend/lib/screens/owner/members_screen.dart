import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import 'member_details_screen.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filtered = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final response = await api.dio.get('/members/all');
      final List<dynamic> data = response.data;
      setState(() {
        _allMembers = data.cast<Map<String, dynamic>>();
        _filtered = _allMembers;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching members: $e');
      setState(() => _isLoading = false);
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase();
    setState(() {
      _filtered = _allMembers.where((m) {
        final name = (m['full_name'] ?? '').toString().toLowerCase();
        final parent = (m['parent_name'] ?? '').toString().toLowerCase();
        return name.contains(q) || parent.contains(q);
      }).toList();
    });
  }

  Future<void> _deleteMember(int memberId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda Brisanja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Da li ste sigurni da želite da obrišete "$name"?'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Ako roditelj nema drugu decu, i roditeljski nalog će biti obrisan.",
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      final response = await api.dio.delete('/members/$memberId');
      final parentDeleted = response.data['parent_deleted'] == true;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              parentDeleted
                  ? '$name obrisan/a. Roditeljski nalog takođe obrisan.'
                  : '$name uspešno obrisan/a.',
            ),
          ),
        );
        _fetchMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Greška: $e')));
      }
    }
  }

  // ─── Register New Family Dialog ────────────────────────────

  void _showRegisterFamilyDialog() {
    final parentNameCtrl = TextEditingController();
    final parentEmailCtrl = TextEditingController();
    final parentPhoneCtrl = TextEditingController();
    final parentPasswordCtrl = TextEditingController(text: '123456');
    final childNameCtrl = TextEditingController();
    final childNotesCtrl = TextEditingController();
    DateTime? childDob;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: const Text('Novi Član (Porodica)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section 1: Parent ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '👤 PODACI O RODITELJU',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: parentNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ime i Prezime',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: parentEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email (korisničko ime)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: parentPhoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Telefon',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: parentPasswordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Lozinka',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Section 2: Child ──
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '🧒 PODACI O DETETU',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: childNameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ime i Prezime deteta',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        childDob != null
                            ? 'Datum rođenja: ${DateFormat('dd.MM.yyyy').format(childDob!)}'
                            : 'Izaberite datum rođenja',
                        style: TextStyle(
                          color: childDob != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: ctx2,
                          initialDate: DateTime.now().subtract(
                            const Duration(days: 2555),
                          ),
                          firstDate: DateTime(2005),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setDialogState(() => childDob = d);
                      },
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: childNotesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Napomena (opciono)',
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
                    // Validation
                    if (parentNameCtrl.text.trim().isEmpty ||
                        parentEmailCtrl.text.trim().isEmpty ||
                        parentPasswordCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Popunite ime, email i lozinku roditelja.',
                          ),
                        ),
                      );
                      return;
                    }
                    if (childNameCtrl.text.trim().isEmpty || childDob == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Popunite ime deteta i datum rođenja.'),
                        ),
                      );
                      return;
                    }

                    Navigator.of(ctx).pop();

                    try {
                      final api = Provider.of<ApiClient>(
                        context,
                        listen: false,
                      );

                      // Step A: Create parent
                      final parentRes = await api.dio.post(
                        '/users/admin-create',
                        data: {
                          'full_name': parentNameCtrl.text.trim(),
                          'email': parentEmailCtrl.text.trim(),
                          'phone_number': parentPhoneCtrl.text.trim().isNotEmpty
                              ? parentPhoneCtrl.text.trim()
                              : null,
                          'password': parentPasswordCtrl.text.trim(),
                          'role': 'PARENT',
                        },
                      );

                      final parentId = parentRes.data['id'];

                      // Step B: Create child under parent
                      await api.dio.post(
                        '/members/admin-create',
                        data: {
                          'full_name': childNameCtrl.text.trim(),
                          'date_of_birth': DateFormat(
                            'yyyy-MM-dd',
                          ).format(childDob!),
                          'notes': childNotesCtrl.text.trim().isNotEmpty
                              ? childNotesCtrl.text.trim()
                              : null,
                          'parent_id': parentId,
                        },
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Uspešno kreirani roditelj i dete!'),
                          ),
                        );
                        _fetchMembers();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Greška: $e')));
                      }
                    }
                  },
                  child: const Text('Registruj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plivači"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRegisterFamilyDialog,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ── Search Bar ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: "Pretraži člana...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          // ── List ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                ? const Center(child: Text("Nema rezultata."))
                : RefreshIndicator(
                    onRefresh: _fetchMembers,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) => _buildMemberCard(_filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final isActive = member['active'] == true;
    final hasNotes =
        member['notes'] != null && member['notes'].toString().isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MemberDetailsScreen(member: member),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isActive
                    ? Colors.orange.shade100
                    : Colors.grey.shade200,
                child: Text(
                  (member['full_name'] ?? '?')[0],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.orange.shade800 : Colors.grey,
                  ),
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
                            member['full_name'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "Neaktivan",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (member['date_of_birth'] != null)
                      Text(
                        "Rođen/a: ${member['date_of_birth']}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (member['parent_name'] != null)
                      Text(
                        "Roditelj: ${member['parent_name']}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    if (member['parent_phone'] != null)
                      Text(
                        "Tel: ${member['parent_phone']}",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    if (hasNotes)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "📋 ${member['notes']}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: () =>
                    _deleteMember(member['id'], member['full_name'] ?? ''),
                icon: const Icon(Icons.delete_outline),
                color: Colors.red.shade400,
                tooltip: 'Obriši',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
