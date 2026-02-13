import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/society_provider.dart';
import '../../providers/maintenance_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});
  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _showGenerateDialog() {
    int month = DateTime.now().month;
    int year = DateTime.now().year;
    final amtCtrl = TextEditingController(text: '5000');
    final feeCtrl = TextEditingController(text: '500');
    DateTime dueDate = DateTime.now().add(const Duration(days: 10));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Generate Monthly Bills'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: month,
                        decoration: const InputDecoration(labelText: 'Month'),
                        items: List.generate(12, (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][i]),
                        )),
                        onChanged: (v) => setDialogState(() => month = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: '$year',
                        decoration: const InputDecoration(labelText: 'Year'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => year = int.tryParse(v) ?? year,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: amtCtrl,
                  decoration: const InputDecoration(labelText: 'Amount per Flat (Rs.)'),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontFamily: 'JetBrainsMono'),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx, initialDate: dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 90)),
                    );
                    if (picked != null) setDialogState(() => dueDate = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Due Date'),
                    child: Text('${dueDate.day}/${dueDate.month}/${dueDate.year}'),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: feeCtrl,
                  decoration: const InputDecoration(labelText: 'Late Fee (Rs.)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final soc = ref.read(societyProvider).current!;
                try {
                  final api = ref.read(apiServiceProvider);
                  final res = await api.post(ApiConfig.generateBills(soc.id), data: {
                    'month': month,
                    'year': year,
                    'amount_per_flat': double.parse(amtCtrl.text),
                    'due_date': '${dueDate.year}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}',
                    'late_fee': double.parse(feeCtrl.text),
                  });
                  Navigator.pop(ctx);
                  _snack('${res.data['bills_created']} bills generated');
                  ref.invalidate(maintenanceBillsProvider(soc.id));
                } catch (e) {
                  _snack('Failed to generate bills');
                }
              },
              child: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPayDialog(Map<String, dynamic> bill) {
    final amtCtrl = TextEditingController(
        text: ((bill['amount'] ?? 0) - (bill['paid_amount'] ?? 0)).toStringAsFixed(0));
    String mode = 'bank';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Record Payment - ${bill['flat_number']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Bill Amount:', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      Text(formatFullCurrency((bill['amount'] ?? 0).toDouble()),
                          style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13)),
                    ]),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Outstanding:', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      Text(
                        formatFullCurrency(((bill['amount'] ?? 0) - (bill['paid_amount'] ?? 0)).toDouble()),
                        style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13, color: AppColors.warning),
                      ),
                    ]),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amtCtrl,
                decoration: const InputDecoration(labelText: 'Amount Received (Rs.)'),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontFamily: 'JetBrainsMono'),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Payment Mode'),
                items: ['cash', 'upi', 'bank']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
                    .toList(),
                onChanged: (v) => setDialogState(() => mode = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final soc = ref.read(societyProvider).current!;
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.post(ApiConfig.recordPayment(soc.id), data: {
                    'bill_id': bill['id'],
                    'amount_paid': double.parse(amtCtrl.text),
                    'payment_mode': mode,
                  });
                  Navigator.pop(ctx);
                  _snack('Payment recorded');
                  ref.invalidate(maintenanceBillsProvider(soc.id));
                } catch (e) {
                  _snack('Failed to record payment');
                }
              },
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return AppColors.success;
      case 'partial': return AppColors.primary;
      case 'overdue': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final society = ref.watch(societyProvider);
    final soc = society.current;
    if (soc == null) return const LoadingWidget();

    final billsAsync = ref.watch(maintenanceBillsProvider(soc.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Maintenance Billing'),
        actions: [
          if (society.isManager)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _showGenerateDialog,
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: billsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (bills) {
          final totalBilled = bills.fold<double>(0, (s, b) => s + b.amount);
          final totalPaid = bills.fold<double>(0, (s, b) => s + b.paidAmount);
          final paidCount = bills.where((b) => b.status == 'paid').length;
          final pendingCount = bills.where((b) => b.status != 'paid').length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(maintenanceBillsProvider(soc.id)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8, crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    _SummaryTile('Total Billed', formatFullCurrency(totalBilled)),
                    _SummaryTile('Collected', formatFullCurrency(totalPaid), color: AppColors.success),
                    _SummaryTile('Paid', '$paidCount', color: AppColors.success),
                    _SummaryTile('Pending', '$pendingCount', color: AppColors.warning),
                  ],
                ),
                const SizedBox(height: 20),

                if (bills.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No bills generated yet',
                          style: TextStyle(color: AppColors.textTertiary)),
                    ),
                  )
                else
                  ...bills.map((bill) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
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
                                  Row(
                                    children: [
                                      Text(bill.flatNumber,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(bill.status).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(bill.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 9, fontWeight: FontWeight.w700,
                                              color: _statusColor(bill.status),
                                            )),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${bill.month}/${bill.year}  |  ${bill.memberName.isNotEmpty ? bill.memberName : 'Unassigned'}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatFullCurrency(bill.amount),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', fontSize: 13)),
                                if (bill.paidAmount > 0)
                                  Text('Paid: ${formatFullCurrency(bill.paidAmount)}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.success)),
                              ],
                            ),
                            if (society.isManager && !bill.isPaid) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.payment, size: 20, color: AppColors.primary),
                                onPressed: () => _showPayDialog({
                                  'id': bill.id,
                                  'flat_number': bill.flatNumber,
                                  'amount': bill.amount,
                                  'paid_amount': bill.paidAmount,
                                }),
                              ),
                            ],
                          ],
                        ),
                      )),
              ],
            ),
          );
        },
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
                style: const TextStyle(fontSize: 9, color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
                    color: color ?? AppColors.textPrimary, fontFamily: 'JetBrainsMono')),
          ],
        ),
      );
}
