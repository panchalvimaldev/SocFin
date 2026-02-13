import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../core/constants.dart';
import '../../providers/society_provider.dart';
import '../../services/api_service.dart';

class FlatLedgerScreen extends ConsumerStatefulWidget {
  final String flatId;
  final String flatNumber;
  const FlatLedgerScreen({super.key, required this.flatId, this.flatNumber = ''});

  @override
  ConsumerState<FlatLedgerScreen> createState() => _FlatLedgerScreenState();
}

class _FlatLedgerScreenState extends ConsumerState<FlatLedgerScreen> {
  List<Map<String, dynamic>> _ledger = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final soc = ref.read(societyProvider).current;
    if (soc == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get(
        '${ApiConfig.baseUrl}/societies/${soc.id}/maintenance/ledger/${widget.flatId}',
      );
      _ledger = List<Map<String, dynamic>>.from(res.data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid': return AppColors.success;
      case 'partial': return AppColors.primary;
      case 'overdue': return AppColors.danger;
      default: return AppColors.warning;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'paid': return Icons.check_circle;
      case 'partial': return Icons.timelapse;
      default: return Icons.warning_amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalBilled = _ledger.fold<double>(0, (s, b) => s + (b['amount'] ?? 0).toDouble());
    final totalPaid = _ledger.fold<double>(0, (s, b) => s + (b['paid_amount'] ?? 0).toDouble());
    final outstanding = totalBilled - totalPaid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Flat ${widget.flatNumber} - Ledger'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: () async { setState(() => _loading = true); _load(); },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary
                  Row(
                    children: [
                      Expanded(child: _SummaryCard('Billed', formatFullCurrency(totalBilled))),
                      const SizedBox(width: 8),
                      Expanded(child: _SummaryCard('Paid', formatFullCurrency(totalPaid), color: AppColors.success)),
                      const SizedBox(width: 8),
                      Expanded(child: _SummaryCard('Due', formatFullCurrency(outstanding),
                          color: outstanding > 0 ? AppColors.warning : AppColors.success)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('PAYMENT HISTORY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary, letterSpacing: 1.5)),
                  const SizedBox(height: 10),

                  if (_ledger.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No billing records', style: TextStyle(color: AppColors.textTertiary)),
                      ),
                    )
                  else
                    ..._ledger.map((bill) {
                      final status = bill['status'] ?? 'pending';
                      final billed = (bill['amount'] ?? 0).toDouble();
                      final paid = (bill['paid_amount'] ?? 0).toDouble();
                      final month = bill['month'] ?? 0;
                      final year = bill['year'] ?? 0;
                      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final monthName = month > 0 && month <= 12 ? months[month] : '$month';

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
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(_statusIcon(status), size: 20, color: _statusColor(status)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text('$monthName $year',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _statusColor(status).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(status.toUpperCase(),
                                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700,
                                                color: _statusColor(status))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Due: ${bill['due_date'] ?? '-'}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatFullCurrency(billed),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', fontSize: 13)),
                                Text('Paid: ${formatFullCurrency(paid)}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.success)),
                                if (billed - paid > 0)
                                  Text('Due: ${formatFullCurrency(billed - paid)}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.warning)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryCard(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          children: [
            Text(label.toUpperCase(),
                style: const TextStyle(fontSize: 9, color: AppColors.textTertiary, letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: color ?? AppColors.textPrimary, fontFamily: 'JetBrainsMono')),
          ],
        ),
      );
}
