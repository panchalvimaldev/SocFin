import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/society_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  static const _chartColors = [
    Color(0xFF3B82F6), Color(0xFF10B981), Color(0xFFF59E0B),
    Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFF0EA5E9),
    Color(0xFFEC4899), Color(0xFFF97316),
  ];

  static const _months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];

  @override
  Widget build(BuildContext context) {
    final soc = ref.watch(societyProvider).current;
    if (soc == null) return const LoadingWidget();

    final monthlyAsync = ref.watch(monthlySummaryProvider((societyId: soc.id, year: _year)));
    final catAsync = ref.watch(categorySpendingProvider((societyId: soc.id, year: _year)));
    final annualAsync = ref.watch(annualSummaryProvider((societyId: soc.id, year: _year)));
    final duesAsync = ref.watch(outstandingDuesProvider(soc.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reports'),
        actions: [
          // Year picker
          PopupMenuButton<int>(
            initialValue: _year,
            onSelected: (y) => setState(() => _year = y),
            itemBuilder: (_) => [2024, 2025, 2026]
                .map((y) => PopupMenuItem(value: y, child: Text('$y')))
                .toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text('$_year', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Monthly'),
            Tab(text: 'Categories'),
            Tab(text: 'Dues'),
          ],
        ),
      ),
      drawer: const AppDrawer(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Monthly Tab ────────────────────────────
          monthlyAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (monthly) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Annual summary cards
                annualAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (annual) => GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8, crossAxisSpacing: 8,
                    childAspectRatio: 2.2,
                    children: [
                      _SummaryTile('Total Income', formatFullCurrency((annual['total_income'] ?? 0).toDouble()), color: AppColors.success),
                      _SummaryTile('Total Expense', formatFullCurrency((annual['total_expense'] ?? 0).toDouble()), color: AppColors.danger),
                      _SummaryTile('Net Balance', formatFullCurrency((annual['net_balance'] ?? 0).toDouble()),
                          color: (annual['net_balance'] ?? 0) >= 0 ? AppColors.success : AppColors.danger),
                      _SummaryTile('Collection', '${annual['collection_rate'] ?? 0}%', color: AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bar Chart
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
                      Text('Income vs Expense - $_year',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: BarChart(BarChartData(
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(
                              showTitles: true, reservedSize: 40,
                              getTitlesWidget: (v, _) => Text(formatCurrency(v),
                                  style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                            )),
                            bottomTitles: AxisTitles(sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  v.toInt() < 12 ? _months[v.toInt()] : '',
                                  style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                                ),
                              ),
                            )),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.04)),
                          ),
                          barGroups: monthly.asMap().entries.map((e) => BarChartGroupData(
                            x: e.key, barsSpace: 3,
                            barRods: [
                              BarChartRodData(toY: e.value.totalInward, color: AppColors.success, width: 6,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                              BarChartRodData(toY: e.value.totalOutward, color: AppColors.danger, width: 6,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                            ],
                          )).toList(),
                        )),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Categories Tab ─────────────────────────
          catAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (cats) => cats.isEmpty
                ? const Center(child: Text('No expense data', style: TextStyle(color: AppColors.textTertiary)))
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Pie chart
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Column(
                          children: [
                            const Text('Expense by Category',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 200,
                              child: PieChart(PieChartData(
                                sections: cats.asMap().entries.map((e) => PieChartSectionData(
                                  value: e.value.total,
                                  color: _chartColors[e.key % _chartColors.length],
                                  title: '${e.value.percentage.toStringAsFixed(0)}%',
                                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                  radius: 60,
                                )).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 30,
                              )),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...cats.asMap().entries.map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Container(width: 12, height: 12,
                                    decoration: BoxDecoration(
                                      color: _chartColors[e.key % _chartColors.length],
                                      borderRadius: BorderRadius.circular(3),
                                    )),
                                const SizedBox(width: 12),
                                Expanded(child: Text(e.value.category, style: const TextStyle(fontSize: 13))),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(formatFullCurrency(e.value.total),
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', fontSize: 13)),
                                    Text('${e.value.percentage}% | ${e.value.count} txns',
                                        style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                                  ],
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
          ),

          // ── Dues Tab ───────────────────────────────
          duesAsync.when(
            loading: () => const LoadingWidget(),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (dues) => dues.isEmpty
                ? const Center(child: Text('No outstanding dues', style: TextStyle(color: AppColors.textTertiary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dues.length,
                    itemBuilder: (_, i) {
                      final d = dues[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['flat_number'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('${d['member_name'] ?? 'Unassigned'}  |  ${d['month']}/${d['year']}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                            Text(formatFullCurrency((d['outstanding'] ?? 0).toDouble()),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono',
                                  fontSize: 13, color: AppColors.warning,
                                )),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryTile(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(fontSize: 9, color: AppColors.textTertiary, fontWeight: FontWeight.w500, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800,
                    color: color ?? AppColors.textPrimary, fontFamily: 'JetBrainsMono')),
          ],
        ),
      );
}
