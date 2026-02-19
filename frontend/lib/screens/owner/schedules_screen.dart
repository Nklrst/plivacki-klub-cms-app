import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/schedule_provider.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  static const List<String> _days = [
    'PON',
    'UTO',
    'SRE',
    'CET',
    'PET',
    'SUB',
    'NED',
  ];

  static const Map<String, String> _dayLabels = {
    'PON': 'Ponedeljak',
    'UTO': 'Utorak',
    'SRE': 'Sreda',
    'CET': 'Četvrtak',
    'PET': 'Petak',
    'SUB': 'Subota',
    'NED': 'Nedelja',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ScheduleProvider>(context, listen: false).fetchSchedules();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Termini & Raspored"),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: _days.map((d) => Tab(text: d)).toList(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showScheduleDialog(),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: Consumer<ScheduleProvider>(
          builder: (ctx, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return TabBarView(
              children: _days.map((day) {
                final items = provider.getSchedulesForDay(day);
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Nema termina za ${_dayLabels[day] ?? day}",
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.fetchSchedules(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _buildScheduleCard(items[i]),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScheduleCard(ScheduleItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: item.isActive
                  ? Colors.blue.shade100
                  : Colors.grey.shade200,
              child: Icon(
                Icons.pool,
                color: item.isActive ? Colors.blue : Colors.grey,
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
                          item.groupName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Tooltip(
                        message: 'Popunjenost',
                        triggerMode: TooltipTriggerMode.tap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${item.currentEnrollments}/${item.capacity}",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "🕒 ${item.startTime} - ${item.endTime}",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  if (item.location.isNotEmpty)
                    Text(
                      "📍 ${item.location}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  if (!item.isActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Neaktivan",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _showScheduleDialog(existing: item),
              icon: const Icon(Icons.edit_outlined),
              color: Colors.orange,
              tooltip: 'Izmeni',
            ),
            IconButton(
              onPressed: () => _confirmDelete(item),
              icon: const Icon(Icons.delete_outline),
              color: Colors.red.shade400,
              tooltip: 'Obriši',
            ),
          ],
        ),
      ),
    );
  }

  // ─── Delete Confirmation ──────────────────────────────────

  Future<void> _confirmDelete(ScheduleItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda Brisanja'),
        content: Text(
          'Obrisati termin "${item.groupName}" (${item.startTime} - ${item.endTime})?',
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

    final provider = Provider.of<ScheduleProvider>(context, listen: false);
    final ok = await provider.deleteSchedule(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Termin uspešno obrisan.' : 'Greška pri brisanju.',
          ),
        ),
      );
    }
  }

  // ─── Add / Edit Dialog ────────────────────────────────────

  void _showScheduleDialog({ScheduleItem? existing}) {
    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.groupName ?? '');
    final locationCtrl = TextEditingController(text: existing?.location ?? '');
    final capacityCtrl = TextEditingController(
      text: (existing?.capacity ?? 10).toString(),
    );
    String selectedDay = existing?.dayOfWeek ?? 'PON';
    TimeOfDay? startTime = existing != null
        ? _parseTime(existing.startTime)
        : null;
    TimeOfDay? endTime = existing != null ? _parseTime(existing.endTime) : null;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Izmeni Termin' : 'Novi Termin'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Group Name
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Naziv grupe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Day
                    DropdownButtonFormField<String>(
                      initialValue: selectedDay,
                      decoration: InputDecoration(
                        labelText: 'Dan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: _days
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(_dayLabels[d] ?? d),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => selectedDay = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Start Time
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        startTime != null
                            ? 'Početak: ${_fmtTimeOfDay(startTime!)}'
                            : 'Izaberite početak',
                        style: TextStyle(
                          color: startTime != null
                              ? Colors.black87
                              : Colors.grey,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx2,
                          initialTime:
                              startTime ?? const TimeOfDay(hour: 18, minute: 0),
                        );
                        if (t != null) setDialogState(() => startTime = t);
                      },
                    ),

                    // End Time
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        endTime != null
                            ? 'Kraj: ${_fmtTimeOfDay(endTime!)}'
                            : 'Izaberite kraj',
                        style: TextStyle(
                          color: endTime != null ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      trailing: const Icon(Icons.access_time),
                      onTap: () async {
                        final t = await showTimePicker(
                          context: ctx2,
                          initialTime:
                              endTime ?? const TimeOfDay(hour: 19, minute: 0),
                        );
                        if (t != null) setDialogState(() => endTime = t);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Location
                    TextField(
                      controller: locationCtrl,
                      decoration: InputDecoration(
                        labelText: 'Lokacija',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Capacity
                    TextField(
                      controller: capacityCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Kapacitet',
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
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unesite naziv grupe.')),
                      );
                      return;
                    }
                    if (startTime == null || endTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Izaberite početak i kraj.'),
                        ),
                      );
                      return;
                    }
                    // Validate end > start
                    final startMin = startTime!.hour * 60 + startTime!.minute;
                    final endMin = endTime!.hour * 60 + endTime!.minute;
                    if (endMin <= startMin) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kraj mora biti posle početka.'),
                        ),
                      );
                      return;
                    }

                    final data = {
                      'group_name': nameCtrl.text.trim(),
                      'day_of_week': selectedDay,
                      'start_time': _timeToStr(startTime!),
                      'end_time': _timeToStr(endTime!),
                      'location': locationCtrl.text.trim(),
                      'capacity': int.tryParse(capacityCtrl.text) ?? 10,
                    };

                    Navigator.of(ctx).pop();

                    final provider = Provider.of<ScheduleProvider>(
                      context,
                      listen: false,
                    );
                    bool ok;
                    if (isEdit) {
                      ok = await provider.updateSchedule(existing.id, data);
                    } else {
                      ok = await provider.addSchedule(data);
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? (isEdit
                                      ? 'Termin uspešno izmenjen.'
                                      : 'Termin uspešno dodat.')
                                : 'Greška pri čuvanju.',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(isEdit ? 'Sačuvaj' : 'Dodaj'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── Time Helpers ─────────────────────────────────────────

  TimeOfDay? _parseTime(String time) {
    if (time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  String _fmtTimeOfDay(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _timeToStr(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';
  }
}
