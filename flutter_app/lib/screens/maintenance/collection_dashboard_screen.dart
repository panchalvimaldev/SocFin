import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class CollectionDashboardScreen extends ConsumerStatefulWidget {
  const CollectionDashboardScreen({super.key});

  @override
  ConsumerState<CollectionDashboardScreen> createState() => _CollectionDashboardScreenState();
}

class _CollectionDashboardScreenState extends ConsumerState<CollectionDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic>? _dashboard;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.get('/maintenance/collection-dashboard?year=$_year&month=$_month');
      setState(() => _dashboard = data);
    } catch (e) {
      debugPrint('Error: $e');
    }
    setState(() => _loading = false);
  }

  String _formatCurrency(num amount) {
    if (amount >= 100000) return '₹${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '₹${(amount / 1000).toStringAsFixed(1)}K';
    return '₹${amount.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Collection Dashboard'),
        backgroundColor: AppColors.surface,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today, size: 20),
            onSelected: (m) { setState(() => _month = m); _loadDashboard(); },
            itemBuilder: (_) => List.generate(12, (i) => PopupMenuItem(value: i + 1, child: Text(_months[i]))),
          ),
          PopupMenuButton<int>(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(child: Text('$_year', style: const TextStyle(fontWeight: FontWeight.w600))),
            ),
            onSelected: (y) { setState(() => _year = y); _loadDashboard(); },
            itemBuilder: (_) => [2025, 2026, 2027].map((y) => PopupMenuItem(value: y, child: Text('$y'))).toList(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingWidget()
          : _dashboard == null
              ? const Center(child: Text('No data', style: TextStyle(color: AppColors.textTertiary)))
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards Row 1
                        Row(
                          children: [
                            _buildSummaryCard('Collected', _formatCurrency(_dashboard!['total_collected'] ?? 0), Colors.green, Icons.trending_up, '${_dashboard!['collection_percentage']}% of billed'),
                            const SizedBox(width: 12),
                            _buildSummaryCard('Outstanding', _formatCurrency(_dashboard!['total_outstanding'] ?? 0), Colors.amber, Icons.schedule, '${_dashboard!['pending_flats']} flats pending'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Summary Cards Row 2
                        Row(
                          children: [
                            _buildSummaryCard('Overdue', '${_dashboard!['overdue_flats']}', Colors.red, Icons.warning, 'flats overdue'),
                            const SizedBox(width: 12),
                            _buildSummaryCard('Total Billed', _formatCurrency(_dashboard!['total_billed'] ?? 0), AppColors.primary, Icons.receipt, '${_dashboard!['total_flats']} flats'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Collection Progress
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Collection Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                  Text('${_dashboard!['collection_percentage']}%', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (_dashboard!['collection_percentage'] ?? 0) / 100,
                                  backgroundColor: AppColors.borderSubtle,
                                  valueColor: const AlwaysStoppedAnimation(Colors.green),
                                  minHeight: 10,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildProgressLabel('Paid', _dashboard!['paid_flats'], Colors.green),
                                  _buildProgressLabel('Pending', _dashboard!['pending_flats'], Colors.amber),
                                  _buildProgressLabel('Overdue', _dashboard!['overdue_flats'], Colors.red),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Monthly Breakdown
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Monthly Breakdown ($_year)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              ...(_dashboard!['month_wise_collection'] as List? ?? []).map((m) => _buildMonthRow(m)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Recent Payments
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Recent Payments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              if ((_dashboard!['recent_payments'] as List? ?? []).isEmpty)
                                const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: Text('No recent payments', style: TextStyle(color: AppColors.textTertiary))),
                                )
                              else
                                ...(_dashboard!['recent_payments'] as List).map((p) => _buildPaymentItem(p)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                Icon(icon, color: color.withOpacity(0.5), size: 24),
              ],
            ),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text(subtitle, style: TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressLabel(String label, int value, Color color) {
    return Row(
      children: [
        Icon(Icons.circle, color: color, size: 10),
        const SizedBox(width: 4),
        Text('$value $label', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }

  Widget _buildMonthRow(Map<String, dynamic> m) {
    final billed = (m['billed'] as num?) ?? 0;
    final collected = (m['collected'] as num?) ?? 0;
    final progress = billed > 0 ? collected / billed : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text(_months[(m['month'] as int) - 1], style: const TextStyle(color: AppColors.textTertiary, fontSize: 12))),
          Expanded(
            child: Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(color: AppColors.borderSubtle, borderRadius: BorderRadius.circular(4)),
                ),
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatCurrency(collected), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                Text('/ ${_formatCurrency(billed)}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.home, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p['flat_number'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                Text(p['date'] ?? '', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('₹${p['amount']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.borderSubtle,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text((p['mode'] ?? '').toString().toUpperCase(), style: const TextStyle(color: AppColors.textTertiary, fontSize: 9)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
