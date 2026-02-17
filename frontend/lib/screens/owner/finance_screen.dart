import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/api_client.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  static const _monthNames = [
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

  static const _monthShort = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Maj',
    'Jun',
    'Jul',
    'Avg',
    'Sep',
    'Okt',
    'Nov',
    'Dec',
  ];

  final _currencyFmt = NumberFormat('#,##0', 'sr');

  // ── Bilans state ──
  int _bilansYear = DateTime.now().year;
  bool _bilansLoading = false;
  List<Map<String, dynamic>> _bilansData = [];

  // ── Dugovanja state ──
  int _debtMonth = DateTime.now().month;
  int _debtYear = DateTime.now().year;
  bool _debtLoading = false;
  List<Map<String, dynamic>> _debtors = [];

  // ── Istorija state ──
  bool _historyLoading = false;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchBilans();
    _fetchDebtors();
    _fetchHistory();
  }

  // ═══════════════════════════════════════════════════════
  //  API CALLS
  // ═══════════════════════════════════════════════════════

  Future<void> _fetchBilans() async {
    setState(() => _bilansLoading = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final res = await api.dio.get(
        '/payments/yearly-summary',
        queryParameters: {'year': _bilansYear},
      );
      setState(() {
        _bilansData = List<Map<String, dynamic>>.from(res.data);
        _bilansLoading = false;
      });
    } catch (e) {
      print('Bilans error: $e');
      setState(() => _bilansLoading = false);
    }
  }

  Future<void> _fetchDebtors() async {
    setState(() => _debtLoading = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final res = await api.dio.get(
        '/payments/debtors',
        queryParameters: {'month': _debtMonth, 'year': _debtYear},
      );
      setState(() {
        _debtors = List<Map<String, dynamic>>.from(res.data);
        _debtLoading = false;
      });
    } catch (e) {
      print('Debtors error: $e');
      setState(() => _debtLoading = false);
    }
  }

  Future<void> _fetchHistory() async {
    setState(() => _historyLoading = true);
    try {
      final api = Provider.of<ApiClient>(context, listen: false);
      final res = await api.dio.get('/payments/history');
      setState(() {
        _history = List<Map<String, dynamic>>.from(res.data);
        _historyLoading = false;
      });
    } catch (e) {
      print('History error: $e');
      setState(() => _historyLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finansije & Članarine'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.bar_chart), text: 'Bilans'),
              Tab(icon: Icon(Icons.warning_amber), text: 'Dugovanja'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Istorija Uplata'),
            ],
          ),
        ),
        body: TabBarView(
          children: [_buildBilansTab(), _buildDebtorsTab(), _buildHistoryTab()],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 1: BILANS
  // ═══════════════════════════════════════════════════════

  Widget _buildBilansTab() {
    return Column(
      children: [
        // Year selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text(
                'Godina:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _bilansYear,
                items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    _bilansYear = v;
                    _fetchBilans();
                  }
                },
              ),
            ],
          ),
        ),
        // ── Bar Chart ──
        if (!_bilansLoading && _bilansData.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(height: 200, child: _buildRevenueChart()),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _bilansLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _bilansData.length,
                  itemBuilder: (_, i) => _buildMonthCard(_bilansData[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final maxRevenue = _bilansData.fold<double>(
      0,
      (prev, d) => (d['total_revenue'] as num).toDouble() > prev
          ? (d['total_revenue'] as num).toDouble()
          : prev,
    );
    final maxY = maxRevenue > 0 ? maxRevenue * 1.15 : 100;

    return BarChart(
      BarChartData(
        maxY: maxY.toDouble(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final month = group.x + 1;
              final value = rod.toY;
              return BarTooltipItem(
                '${_monthNames[month]}\n${_currencyFmt.format(value)} RSD',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    '${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt() + 1;
                if (idx < 1 || idx > 12) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    _monthShort[idx],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxRevenue > 0 ? maxRevenue / 4 : 25,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
        ),
        barGroups: _bilansData.map((d) {
          final month = (d['month'] as int) - 1;
          final revenue = (d['total_revenue'] as num).toDouble();
          final isCurrentMonth =
              (d['month'] as int) == DateTime.now().month &&
              _bilansYear == DateTime.now().year;
          return BarChartGroupData(
            x: month,
            barRods: [
              BarChartRodData(
                toY: revenue,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: isCurrentMonth
                      ? [Colors.green.shade400, Colors.green.shade700]
                      : [Colors.green.shade200, Colors.green.shade500],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthCard(Map<String, dynamic> data) {
    final month = data['month'] as int;
    final revenue = (data['total_revenue'] as num).toDouble();
    final count = data['payment_count'] as int;
    final isCurrentMonth =
        month == DateTime.now().month && _bilansYear == DateTime.now().year;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isCurrentMonth ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrentMonth
            ? BorderSide(color: Colors.green.shade300, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: revenue > 0
              ? Colors.green.shade100
              : Colors.grey.shade100,
          child: Text(
            '$month',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: revenue > 0 ? Colors.green.shade800 : Colors.grey,
            ),
          ),
        ),
        title: Text(
          _monthNames[month],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '$count uplata',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Text(
          '${_currencyFmt.format(revenue)} RSD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: revenue > 0 ? Colors.green.shade700 : Colors.grey,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 2: DUGOVANJA
  // ═══════════════════════════════════════════════════════

  Widget _buildDebtorsTab() {
    return Column(
      children: [
        // Month + Year selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Month
              const Text(
                'Mesec:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _debtMonth,
                items: List.generate(12, (i) => i + 1)
                    .map(
                      (m) => DropdownMenuItem(
                        value: m,
                        child: Text(_monthNames[m]),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    _debtMonth = v;
                    _fetchDebtors();
                  }
                },
              ),
              const Spacer(),
              // Year
              DropdownButton<int>(
                value: _debtYear,
                items: List.generate(5, (i) => DateTime.now().year - 2 + i)
                    .map((y) => DropdownMenuItem(value: y, child: Text('$y')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    _debtYear = v;
                    _fetchDebtors();
                  }
                },
              ),
            ],
          ),
        ),
        // Stats bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _debtors.isNotEmpty
                ? Colors.red.shade50
                : Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                _debtors.isNotEmpty ? Icons.warning_amber : Icons.check_circle,
                color: _debtors.isNotEmpty ? Colors.red : Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                _debtors.isNotEmpty
                    ? '${_debtors.length} članova duguje za ${_monthNames[_debtMonth]}'
                    : 'Svi članovi su platili za ${_monthNames[_debtMonth]}!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _debtors.isNotEmpty
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _debtLoading
              ? const Center(child: CircularProgressIndicator())
              : _debtors.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.celebration,
                        size: 48,
                        color: Colors.green.shade300,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sve članarine naplaćene!',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _debtors.length,
                  itemBuilder: (_, i) => _buildDebtorCard(_debtors[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildDebtorCard(Map<String, dynamic> debtor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Text(
            (debtor['full_name'] ?? '?')[0],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
        ),
        title: Text(
          debtor['full_name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (debtor['parent_name'] != null)
              Text(
                'Roditelj: ${debtor['parent_name']}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (debtor['parent_phone'] != null)
              Text(
                'Tel: ${debtor['parent_phone']}',
                style: TextStyle(fontSize: 12, color: Colors.blue.shade400),
              ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _showPaymentDialog(debtor),
          icon: const Text('💰', style: TextStyle(fontSize: 16)),
          label: const Text('Uplata'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  TAB 3: ISTORIJA
  // ═══════════════════════════════════════════════════════

  Widget _buildHistoryTab() {
    if (_historyLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Nema evidentiranih uplata.',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _history.length,
        itemBuilder: (_, i) => _buildHistoryCard(_history[i]),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> p) {
    final method = (p['payment_method'] ?? '').toString();
    final methodLabel = method.contains('CASH') ? 'Keš' : 'Račun';
    final methodIcon = method.contains('CASH')
        ? Icons.money
        : Icons.account_balance;
    final amount = (p['amount'] as num).toDouble();

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(methodIcon, color: Colors.green.shade700, size: 20),
        ),
        title: Text(
          p['member_name'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${_monthNames[p['month'] ?? 0]} ${p['year']} • $methodLabel • ${p['payment_date'] ?? ''}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Text(
          '${_currencyFmt.format(amount)} RSD',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  PAYMENT DIALOG
  // ═══════════════════════════════════════════════════════

  void _showPaymentDialog(Map<String, dynamic> debtor) {
    final amountCtrl = TextEditingController(text: '5000');
    String method = 'CASH';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setDialogState) {
            return AlertDialog(
              title: Text('Evidentiraj uplatu za ${debtor['full_name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period info
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          color: Colors.blue.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_monthNames[_debtMonth]} $_debtYear',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Method
                  const Text(
                    'Način uplate:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Keš',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: 'CASH',
                          groupValue: method,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (v) => setDialogState(() => method = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text(
                            'Račun',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: 'BANK_TRANSFER',
                          groupValue: method,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          onChanged: (v) => setDialogState(() => method = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Amount
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Iznos (RSD)',
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
                  onPressed: () async {
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Unesite validan iznos.')),
                      );
                      return;
                    }

                    Navigator.of(ctx).pop();

                    try {
                      final api = Provider.of<ApiClient>(
                        context,
                        listen: false,
                      );
                      final today = DateFormat(
                        'yyyy-MM-dd',
                      ).format(DateTime.now());
                      await api.dio.post(
                        '/payments/',
                        data: {
                          'member_id': debtor['id'],
                          'amount': amount,
                          'payment_date': today,
                          'payment_method': method,
                          'month': _debtMonth,
                          'year': _debtYear,
                        },
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Uplata od ${_currencyFmt.format(amount)} RSD evidentirana za ${debtor['full_name']}.',
                            ),
                          ),
                        );
                        _fetchDebtors();
                        _fetchHistory();
                        _fetchBilans();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Greška: $e')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Evidentiraj'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
