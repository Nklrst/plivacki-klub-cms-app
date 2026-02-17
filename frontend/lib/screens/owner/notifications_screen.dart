import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Target groups
  bool _allCoaches = false;
  bool _allParents = false;
  bool _entireClub = false;

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // Mock history
  final List<Map<String, String>> _history = [
    {
      'title': 'Otkazani treninzi petak',
      'target': 'Ceo Klub',
      'date': '14.02.2026',
      'body': 'Treninzi u petak su otkazani zbog održavanja bazena.',
    },
    {
      'title': 'Nova sezona upisa',
      'target': 'Svi Roditelji',
      'date': '10.02.2026',
      'body': 'Počinje upis za proleću sezonu. Javite se trenerima.',
    },
    {
      'title': 'Sastanak trenera',
      'target': 'Svi Treneri',
      'date': '05.02.2026',
      'body': 'Sastanak u ponedeljak u 10:00 u kancelariji kluba.',
    },
  ];

  void _sendNotification() {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unesite naslov i tekst poruke.')),
      );
      return;
    }

    if (!_allCoaches && !_allParents && !_entireClub) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izaberite barem jednu ciljnu grupu.')),
      );
      return;
    }

    // Count target addresses (mock)
    int count = 0;
    List<String> groups = [];
    if (_entireClub) {
      count = 45;
      groups.add('Ceo Klub');
    } else {
      if (_allCoaches) {
        count += 5;
        groups.add('Treneri');
      }
      if (_allParents) {
        count += 40;
        groups.add('Roditelji');
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Poruka "$title" poslata na $count adresa (${groups.join(', ')}).',
        ),
      ),
    );

    // Add to mock history
    setState(() {
      _history.insert(0, {
        'title': title,
        'target': groups.join(', '),
        'date': '15.02.2026',
        'body': body,
      });
    });

    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _allCoaches = false;
      _allParents = false;
      _entireClub = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Obaveštenja"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── COMPOSE SECTION ──────────────────────────
            _buildSectionHeader("NOVO OBAVEŠTENJE", Icons.edit, Colors.purple),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Target group
                    const Text(
                      "Ciljna Grupa:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        FilterChip(
                          label: const Text("Svi Treneri"),
                          selected: _allCoaches,
                          selectedColor: Colors.teal.shade100,
                          onSelected: (v) => setState(() {
                            _allCoaches = v;
                            if (v) _entireClub = false;
                          }),
                        ),
                        FilterChip(
                          label: const Text("Svi Roditelji"),
                          selected: _allParents,
                          selectedColor: Colors.orange.shade100,
                          onSelected: (v) => setState(() {
                            _allParents = v;
                            if (v) _entireClub = false;
                          }),
                        ),
                        FilterChip(
                          label: const Text("Ceo Klub"),
                          selected: _entireClub,
                          selectedColor: Colors.purple.shade100,
                          onSelected: (v) => setState(() {
                            _entireClub = v;
                            if (v) {
                              _allCoaches = false;
                              _allParents = false;
                            }
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: "Naslov",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Body
                    TextField(
                      controller: _bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Tekst poruke",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Send button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _sendNotification,
                        icon: const Icon(Icons.send, size: 18),
                        label: const Text("Pošalji"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── HISTORY SECTION ──────────────────────────
            _buildSectionHeader(
              "ISTORIJA OBAVEŠTENJA",
              Icons.history,
              Colors.grey.shade700,
            ),
            const SizedBox(height: 12),

            if (_history.isEmpty)
              Card(
                color: Colors.grey.shade100,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("Nema poslatih obaveštenja."),
                ),
              ),
            ..._history.map((item) => _buildHistoryCard(item)),
          ],
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

  Widget _buildHistoryCard(Map<String, String> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item['title'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item['target'] ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item['body'] ?? '',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              item['date'] ?? '',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
