import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../core/constants.dart';
import '../../providers/society_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});
  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String? _typeFilter;
  String? _catFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load({int page = 1}) {
    final soc = ref.read(societyProvider).current;
    if (soc != null) {
      ref.read(transactionListProvider(soc.id).notifier).fetch(
            page: page,
            type: _typeFilter,
            category: _catFilter,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final society = ref.watch(societyProvider);
    final soc = society.current;
    if (soc == null) return const LoadingWidget();

    final txnState = ref.watch(transactionListProvider(soc.id));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('${txnState.total} records',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          if (society.isManager)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () async {
                await Navigator.pushNamed(context, AppRoutes.addTransaction);
                _load();
              },
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // ── Filters ────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18, color: AppColors.textTertiary),
                const SizedBox(width: 10),
                _FilterChip(
                  label: _typeFilter?.toUpperCase() ?? 'ALL TYPES',
                  isActive: _typeFilter != null,
                  onTap: () => _showTypeFilter(),
                ),
                const SizedBox(width: 8),
                if (_typeFilter != null || _catFilter != null)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _typeFilter = null;
                        _catFilter = null;
                      });
                      _load();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                      ),
                      child: const Text('CLEAR',
                          style: TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── List ───────────────────────────────────
          Expanded(
            child: txnState.isLoading
                ? const LoadingWidget()
                : txnState.transactions.isEmpty
                    ? const Center(
                        child: Text('No transactions found',
                            style: TextStyle(color: AppColors.textTertiary)))
                    : RefreshIndicator(
                        onRefresh: () async => _load(),
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: txnState.transactions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final txn = txnState.transactions[i];
                            final isInward = txn.isInward;
                            final color = isInward ? AppColors.success : AppColors.danger;
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.borderSubtle),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38, height: 38,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
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
                                        Text(txn.category,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(txn.date,
                                                style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                            if (txn.vendorName.isNotEmpty) ...[
                                              const Text('  |  ',
                                                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                              Expanded(
                                                child: Text(txn.vendorName,
                                                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary),
                                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${isInward ? '+' : '-'}${formatFullCurrency(txn.amount)}',
                                        style: TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: color, fontFamily: 'JetBrainsMono',
                                        ),
                                      ),
                                      if (txn.isPending)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.warning.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('PENDING',
                                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.warning)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),

          // ── Pagination ─────────────────────────────
          if (txnState.total > 20)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Page ${txnState.page} of ${(txnState.total / 20).ceil()}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 20),
                        onPressed: txnState.page > 1 ? () => _load(page: txnState.page - 1) : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 20),
                        onPressed: txnState.page < (txnState.total / 20).ceil()
                            ? () => _load(page: txnState.page + 1)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showTypeFilter() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All'),
              leading: Icon(Icons.list, color: _typeFilter == null ? AppColors.primary : null),
              selected: _typeFilter == null,
              onTap: () { setState(() => _typeFilter = null); _load(); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('Inward (Income)'),
              leading: Icon(Icons.south_west, color: _typeFilter == 'inward' ? AppColors.success : null),
              selected: _typeFilter == 'inward',
              onTap: () { setState(() => _typeFilter = 'inward'); _load(); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text('Outward (Expense)'),
              leading: Icon(Icons.north_east, color: _typeFilter == 'outward' ? AppColors.danger : null),
              selected: _typeFilter == 'outward',
              onTap: () { setState(() => _typeFilter = 'outward'); _load(); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? AppColors.primary.withOpacity(0.3) : AppColors.border,
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                letterSpacing: 0.5,
              )),
        ),
      );
}
