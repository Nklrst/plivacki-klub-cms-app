import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../providers/skills_provider.dart';

class MemberDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> member;
  const MemberDetailsScreen({super.key, required this.member});

  @override
  State<MemberDetailsScreen> createState() => _MemberDetailsScreenState();
}

class _MemberDetailsScreenState extends State<MemberDetailsScreen> {
  // Stats state
  bool _statsLoading = true;
  int _total = 0;
  int _present = 0;
  double _percentage = 0;
  List<Map<String, dynamic>> _history = [];

  // Skills state
  List<SkillStatus> _skills = [];
  bool _skillsLoading = true;

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  static const List<String> _monthNames = [
    '',
    'Januar',
    'Februar',
    'Mart',
    'April',
    'Maj',
    'Jun',
    'Jul',
    'Avgust',
    'Septembar',
    'Oktobar',
    'Novembar',
    'Decembar',
  ];

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchSkills();
  }

  Future<void> _fetchSkills() async {
    setState(() => _skillsLoading = true);
    try {
      final provider = Provider.of<SkillsProvider>(context, listen: false);
      final skills = await provider.fetchMemberSkills(widget.member['id']);
      if (mounted) {
        setState(() {
          _skills = skills;
          _skillsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _skillsLoading = false);
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _statsLoading = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final res = await api.dio.get(
        '/attendance/stats/${widget.member['id']}',
        queryParameters: {'month': _selectedMonth, 'year': _selectedYear},
      );
      if (mounted) {
        setState(() {
          _total = res.data['total'];
          _present = res.data['present'];
          _percentage = (res.data['percentage'] as num).toDouble();
          _history = List<Map<String, dynamic>>.from(res.data['history']);
          _statsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _statsLoading = false);
    }
  }

  Color _percentageColor(double p) {
    if (p >= 75) return Colors.green;
    if (p >= 50) return Colors.orange;
    return Colors.red;
  }

  void _callParent(String? phone) {
    if (phone == null || phone.isEmpty) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Pozovite: $phone')));
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.member;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(m['full_name'] ?? 'Plivač'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(icon: Icon(Icons.person), text: 'Info'),
              Tab(icon: Icon(Icons.bar_chart), text: 'Statistika'),
              Tab(icon: Icon(Icons.stars), text: 'Veštine'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildInfoTab(m), _buildStatsTab(), _buildSkillsTab()],
        ),
      ),
    );
  }

  // ── TAB 1: INFO ──────────────────────────────────────
  Widget _buildInfoTab(Map<String, dynamic> m) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Avatar header
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE3F2FD),
            child: Text(
              (m['full_name'] ?? '?')[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005696),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            m['full_name'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (m['active'] == true)
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              (m['active'] == true) ? 'Aktivan' : 'Neaktivan',
              style: TextStyle(
                color: (m['active'] == true)
                    ? Colors.green.shade800
                    : Colors.red.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Info cards
          _infoCard(
            Icons.cake,
            'Datum Rođenja',
            m['date_of_birth'] ?? 'N/A',
            Colors.purple,
          ),
          if (m['parent_name'] != null)
            _infoCard(
              Icons.person_outline,
              'Roditelj',
              m['parent_name'],
              Colors.blue,
            ),
          if (m['parent_phone'] != null)
            InkWell(
              onTap: () => _callParent(m['parent_phone']),
              child: _infoCard(
                Icons.phone,
                'Telefon Roditelja',
                m['parent_phone'],
                Colors.teal,
                trailing: const Icon(Icons.call, color: Colors.teal, size: 20),
              ),
            ),
          if (m['notes'] != null && m['notes'].toString().isNotEmpty)
            _infoCard(
              Icons.note_alt_outlined,
              'Beleške',
              m['notes'],
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _infoCard(
    IconData icon,
    String label,
    String value,
    Color color, {
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  // ── TAB 2: STATISTIKA ────────────────────────────────
  Widget _buildStatsTab() {
    return Column(
      children: [
        // ── Month/Year filters ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Month dropdown
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedMonth,
                  decoration: InputDecoration(
                    labelText: 'Mesec',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(
                    12,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_monthNames[i + 1]),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      _selectedMonth = v;
                      _fetchStats();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Year dropdown
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<int>(
                  initialValue: _selectedYear,
                  decoration: InputDecoration(
                    labelText: 'Godina',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                      value: DateTime.now().year - 2 + i,
                      child: Text('${DateTime.now().year - 2 + i}'),
                    ),
                  ),
                  onChanged: (v) {
                    if (v != null) {
                      _selectedYear = v;
                      _fetchStats();
                    }
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Content ──
        Expanded(
          child: _statsLoading
              ? const Center(child: CircularProgressIndicator())
              : _total == 0
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_busy,
                        size: 64,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nema podataka za\n${_monthNames[_selectedMonth]} $_selectedYear',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // ── Big percentage circle ──
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _percentageColor(_percentage),
                            width: 6,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${_percentage.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: _percentageColor(_percentage),
                                ),
                              ),
                              Text(
                                'Prisustvo',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Summary row ──
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _statBadge('Prisutan', '$_present', Colors.green),
                        _statBadge(
                          'Odsutan',
                          '${_total - _present}',
                          Colors.red,
                        ),
                        _statBadge('Ukupno', '$_total', Colors.blue),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── History header ──
                    const Text(
                      'Detaljna Istorija',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── History list ──
                    ..._history.map((h) {
                      final d = DateTime.parse(h['date']);
                      final isPres = h['is_present'] == true;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            isPres ? Icons.check_circle : Icons.cancel,
                            color: isPres ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            DateFormat('dd. MMM yyyy').format(d),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          trailing: Text(
                            isPres ? 'Prisutan ✅' : 'Odsutan ❌',
                            style: TextStyle(
                              color: isPres
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _statBadge(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ── TAB 3: VEŠTINE ────────────────────────────────────
  Widget _buildSkillsTab() {
    if (_skillsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_skills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Nema definisanih veština.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    final masteredCount = _skills.where((s) => s.isMastered).length;

    return Column(
      children: [
        // Progress summary
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events,
                  color: Colors.amber.shade700,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  '$masteredCount / ${_skills.length} savladano',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF005696),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Skills list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _skills.length,
            itemBuilder: (_, i) {
              final skill = _skills[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SwitchListTile(
                  title: Text(
                    skill.skillName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: skill.isMastered
                          ? Colors.green.shade800
                          : Colors.black87,
                    ),
                  ),
                  secondary: Icon(
                    skill.isMastered
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: skill.isMastered ? Colors.green : Colors.grey,
                  ),
                  value: skill.isMastered,
                  activeThumbColor: Colors.green,
                  onChanged: (val) async {
                    // Optimistic update
                    setState(() => skill.isMastered = val);
                    final provider = Provider.of<SkillsProvider>(
                      context,
                      listen: false,
                    );
                    final success = await provider.toggleSkill(
                      widget.member['id'],
                      skill.skillId,
                      val,
                    );
                    if (!success && mounted) {
                      // Revert on failure
                      setState(() => skill.isMastered = !val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Greška pri ažuriranju')),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
