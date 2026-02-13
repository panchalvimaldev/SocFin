import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class MyBillsScreen extends ConsumerStatefulWidget {
  const MyBillsScreen({super.key});

  @override
  ConsumerState<MyBillsScreen> createState() => _MyBillsScreenState();
}

class _MyBillsScreenState extends ConsumerState<MyBillsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<dynamic> _bills = [];
  List<dynamic> _payments = [];
  Map<String, dynamic>? _ledger;
  List<dynamic> _schemes = [];
  Map<String, dynamic>? _annualPreview;
  Map<String, dynamic>? _userFlat;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final flats = await ApiService.get('/flats');
      if (flats.isNotEmpty) {
        setState(() => _userFlat = flats[0]);
        await Future.wait([
          _loadBills(),
          _loadPayments(),
          _loadLedger(flats[0]['id']),
          _loadSchemes(),
        ]);
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _loadBills() async {
    try {
      final bills = await ApiService.get('/maintenance/bills');
      setState(() => _bills = bills);
    } catch (e) { debugPrint('Error loading bills: $e'); }
  }

  Future<void> _loadPayments() async {
    try {
      final payments = await ApiService.get('/maintenance/payments');
      setState(() => _payments = payments);
    } catch (e) { debugPrint('Error loading payments: $e'); }
  }

  Future<void> _loadLedger(String flatId) async {
    try {
      final ledger = await ApiService.get('/maintenance/ledger/$flatId');
      setState(() => _ledger = ledger);
    } catch (e) { debugPrint('Error loading ledger: $e'); }
  }

  Future<void> _loadSchemes() async {
    try {
      final schemes = await ApiService.get('/maintenance/discount-schemes');
      setState(() => _schemes = schemes.where((s) => s['is_active'] == true).toList());
    } catch (e) { debugPrint('Error loading schemes: $e'); }
  }

  Future<void> _loadAnnualPreview() async {
    if (_userFlat == null || _schemes.isEmpty) return;
    try {
      final preview = await ApiService.post('/maintenance/annual-payment/preview', {
        'flat_id': _userFlat!['id'],
        'year': DateTime.now().year,
        'discount_scheme_id': _schemes[0]['id'],
      });
      setState(() => _annualPreview = preview);
    } catch (e) { debugPrint('Error: $e'); }
  }

  void _downloadReceipt(String paymentId) {
    final url = '${ApiConfig.baseUrl}/maintenance/receipts/$paymentId/pdf';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  List<dynamic> get _pendingBills => _bills.where((b) => b['status'] != 'paid').toList();
  List<dynamic> get _paidBills => _bills.where((b) => b['status'] == 'paid').toList();
  double get _totalPending => _pendingBills.fold(0.0, (sum, b) => sum + (b['final_payable_amount'] ?? 0) - (b['paid_amount'] ?? 0));
  double get _totalPaid => _payments.fold(0.0, (sum, p) => sum + (p['amount_paid'] ?? 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('My Maintenance Bills'),
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          tabs: [
            Tab(text: 'Pending (${_pendingBills.length})'),
            Tab(text: 'Paid (${_paidBills.length})'),
            const Tab(text: 'Ledger'),
            const Tab(text: 'Receipts'),
          ],
        ),
      ),
      body: _loading
          ? const LoadingWidget()
          : Column(
              children: [
                // Summary Cards
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildSummaryCard('Outstanding', '₹${_totalPending.toStringAsFixed(0)}', Colors.amber, '${_pendingBills.length} bills'),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Total Paid', '₹${_totalPaid.toStringAsFixed(0)}', Colors.green, '${_payments.length} payments'),
                    ],
                  ),
                ),
                
                // Annual offer card
                if (_schemes.isNotEmpty && _annualPreview == null)
                  GestureDetector(
                    onTap: _loadAnnualPreview,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.2), Colors.blue.withOpacity(0.1)]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.purple),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Pay Annual & Save', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w600)),
                                Text(_schemes[0]['scheme_name'], style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                          const Text('Tap to view →', style: TextStyle(color: Colors.purple, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                
                // Annual preview
                if (_annualPreview != null)
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.purple.withOpacity(0.2), Colors.blue.withOpacity(0.1)]),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_annualPreview!['flat_number']} (${_annualPreview!['area_sqft']} sqft)', style: const TextStyle(color: Colors.white)),
                            IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 18), onPressed: () => setState(() => _annualPreview = null)),
                          ],
                        ),
                        const Divider(color: Colors.purple),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('12 Months Total', style: TextStyle(color: AppColors.textSecondary)),
                            Text('₹${_annualPreview!['total_before_discount']}', style: const TextStyle(color: Colors.white)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Discount (${_annualPreview!['free_months']} free)', style: const TextStyle(color: Colors.green, fontSize: 12)),
                            Text('-₹${_annualPreview!['discount_amount']}', style: const TextStyle(color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Final', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('₹${_annualPreview!['final_payable']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20)),
                          ],
                        ),
                      ],
                    ),
                  ),
                
                // Tabs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingTab(),
                      _buildPaidTab(),
                      _buildLedgerTab(),
                      _buildReceiptsTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.05)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_pendingBills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 48),
            SizedBox(height: 12),
            Text('No pending bills!', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingBills.length,
      itemBuilder: (_, i) => _buildBillCard(_pendingBills[i], isPending: true),
    );
  }

  Widget _buildPaidTab() {
    if (_paidBills.isEmpty) {
      return const Center(child: Text('No paid bills yet', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _paidBills.length,
      itemBuilder: (_, i) => _buildBillCard(_paidBills[i], isPending: false),
    );
  }

  Widget _buildBillCard(Map<String, dynamic> bill, {required bool isPending}) {
    final period = bill['bill_period_type'] == 'yearly' ? 'Year ${bill['year']}' : '${bill['month']}/${bill['year']}';
    final amount = isPending ? (bill['final_payable_amount'] ?? 0) - (bill['paid_amount'] ?? 0) : bill['final_payable_amount'];
    final color = isPending ? Colors.amber : Colors.green;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(isPending ? Icons.schedule : Icons.check_circle, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(period, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text('Due: ${bill['due_date']}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${amount.toStringAsFixed(0)}', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: Text(isPending ? 'PENDING' : 'PAID', style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLedgerTab() {
    if (_ledger == null) {
      return const Center(child: Text('No ledger data', style: TextStyle(color: AppColors.textSecondary)));
    }
    final entries = _ledger!['entries'] as List? ?? [];
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (_ledger!['outstanding_balance'] ?? 0) > 0 ? Colors.amber.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_ledger!['flat_number']} Statement', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Text('Balance: ₹${_ledger!['outstanding_balance']}', style: TextStyle(
                color: (_ledger!['outstanding_balance'] ?? 0) > 0 ? Colors.amber : Colors.green,
                fontWeight: FontWeight.bold,
              )),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('No entries', style: TextStyle(color: AppColors.textTertiary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    final isDebit = (e['debit_amount'] ?? 0) > 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e['notes'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                Text((e['entry_date'] ?? '').toString().split('T')[0], style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                isDebit ? '+₹${e['debit_amount']}' : '-₹${e['credit_amount']}',
                                style: TextStyle(color: isDebit ? Colors.red : Colors.green, fontWeight: FontWeight.w600, fontSize: 12),
                              ),
                              Text('Bal: ₹${e['balance_after_entry']}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReceiptsTab() {
    if (_payments.isEmpty) {
      return const Center(child: Text('No receipts yet', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _payments.length,
      itemBuilder: (_, i) {
        final p = _payments[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt, color: Colors.purple),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['receipt_number'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    Text(p['payment_date'] ?? '', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(4)),
                      child: Text((p['payment_mode'] ?? '').toString().toUpperCase(), style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹${p['amount_paid']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _downloadReceipt(p['id']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.download, color: Colors.purple, size: 12),
                          SizedBox(width: 4),
                          Text('Receipt', style: TextStyle(color: Colors.purple, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
