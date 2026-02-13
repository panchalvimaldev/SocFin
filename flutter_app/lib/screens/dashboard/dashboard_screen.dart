import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../core/constants.dart';
import '../../providers/society_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/dashboard/stat_card.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});
  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    final soc = ref.read(societyProvider).current;
    if (soc != null) {
      Future.microtask(() => ref.read(notificationProvider.notifier).fetch(soc.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final society = ref.watch(societyProvider);
    final soc = society.current;
    if (soc == null) return const LoadingWidget(message: 'Loading...');

    final dashAsync = ref.watch(dashboardProvider(soc.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(soc.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('Financial Overview',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          if (society.isManager)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransaction),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer(builder: (_, ref, __) {
                  final count = ref.watch(notificationProvider).unreadCount;
                  if (count == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: AppColors.danger, shape: BoxShape.circle),
                    child: Text('${count > 9 ? '9+' : count}',
                        style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700)),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: dashAsync.when(
        loading: () => const LoadingWidget(message: 'Loading dashboard...'),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider(soc.id)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // ── Stats Grid ─────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    label: 'Balance',
                    value: data.societyBalance,
                    icon: Icons.account_balance_wallet,
                    color: data.societyBalance >= 0 ? AppColors.success : AppColors.danger,
                  ),
                  StatCard(
                    label: 'Income',
                    value: data.totalInward,
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                  StatCard(
                    label: 'Expense',
                    value: data.totalOutward,
                    icon: Icons.trending_down,
                    color: AppColors.danger,
                  ),
                  StatCard(
                    label: 'Pending Dues',
                    value: data.pendingDues.toDouble(),
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    isCurrency: false,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Monthly Chart ──────────────────────
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
                    const Text('Monthly Trend',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          barTouchData: BarTouchData(enabled: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (v, _) => Text(
                                  formatCurrency(v),
                                  style: const TextStyle(fontSize: 9, color: AppColors.textTertiary),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i >= 0 && i < data.monthlyTrend.length) {
                                    final m = data.monthlyTrend[i]['month'] ?? '';
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(m.toString().length >= 7 ? m.toString().substring(5) : m.toString(),
                                          style: const TextStyle(fontSize: 9, color: AppColors.textTertiary)),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (_) => FlLine(
                              color: Colors.white.withOpacity(0.04),
                              strokeWidth: 1,
                            ),
                          ),
                          barGroups: data.monthlyTrend.asMap().entries.map((e) {
                            final inward = (e.value['inward'] ?? 0).toDouble();
                            final outward = (e.value['outward'] ?? 0).toDouble();
                            return BarChartGroupData(
                              x: e.key,
                              barsSpace: 3,
                              barRods: [
                                BarChartRodData(
                                    toY: inward, color: AppColors.success, width: 8,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                                BarChartRodData(
                                    toY: outward, color: AppColors.danger, width: 8,
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Legend(color: AppColors.success, label: 'Income'),
                        const SizedBox(width: 20),
                        _Legend(color: AppColors.danger, label: 'Expense'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Quick Stats ────────────────────────
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
                    const Text('Quick Stats',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _QuickStatRow(icon: Icons.people, label: 'Members', value: '${data.memberCount}'),
                    _QuickStatRow(icon: Icons.home, label: 'Flats', value: '${data.flatCount}'),
                    if (society.isManager || society.isCommittee)
                      _QuickStatRow(
                        icon: Icons.check_circle_outline,
                        label: 'Pending Approvals',
                        value: '${data.pendingApprovals}',
                        valueColor: data.pendingApprovals > 0 ? AppColors.warning : null,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Recent Transactions ────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Transactions',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.transactions),
                          child: const Text('View All', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    if (data.recentTransactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No transactions yet',
                            style: TextStyle(color: AppColors.textTertiary)),
                      )
                    else
                      ...data.recentTransactions.take(8).map((txn) => _TxnTile(txn: txn)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        ],
      );
}

class _QuickStatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _QuickStatRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: valueColor ?? AppColors.textPrimary)),
          ],
        ),
      );
}

class _TxnTile extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isInward = txn['type'] == 'inward';
    final color = isInward ? AppColors.success : AppColors.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(
              isInward ? Icons.south_west : Icons.north_east,
              size: 16, color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn['category'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text(txn['date'] ?? '', style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(
            '${isInward ? '+' : '-'}${formatFullCurrency((txn['amount'] ?? 0).toDouble())}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, fontFamily: 'JetBrainsMono'),
          ),
        ],
      ),
    );
  }
}
