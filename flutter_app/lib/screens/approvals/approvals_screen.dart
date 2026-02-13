import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/society_provider.dart';
import '../../providers/approval_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class ApprovalsScreen extends ConsumerWidget {
  const ApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final society = ref.watch(societyProvider);
    final soc = society.current;
    if (soc == null) return const LoadingWidget();

    final approvalsAsync = ref.watch(approvalsProvider(soc.id));

    return Scaffold(
      appBar: AppBar(title: const Text('Expense Approvals')),
      drawer: const AppDrawer(),
      body: approvalsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (approvals) {
          final pending = approvals.where((a) => a.isPending).toList();
          final processed = approvals.where((a) => !a.isPending).toList();

          if (approvals.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, size: 48, color: AppColors.textTertiary),
                  SizedBox(height: 16),
                  Text('No approval requests', style: TextStyle(color: AppColors.textTertiary)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(approvalsProvider(soc.id)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  Text('PENDING APPROVAL',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  ...pending.map((a) => _ApprovalCard(
                        approval: a,
                        canApprove: society.canApprove,
                        societyId: soc.id,
                      )),
                  const SizedBox(height: 24),
                ],
                if (processed.isNotEmpty) ...[
                  Text('HISTORY',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  ...processed.map((a) => _HistoryTile(approval: a)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  final dynamic approval;
  final bool canApprove;
  final String societyId;

  const _ApprovalCard({
    required this.approval,
    required this.canApprove,
    required this.societyId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('PENDING',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.warning)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(approval.category,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 12),
          Text(formatFullCurrency(approval.amount),
              style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: AppColors.warning, fontFamily: 'JetBrainsMono',
              )),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(approval.requestedByName,
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(width: 12),
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Text(formatDate(approval.createdAt),
                  style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          if (approval.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(approval.description,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (canApprove) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAction(context, ref, 'approve'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAction(context, ref, 'reject'),
                    icon: const Icon(Icons.close, size: 18, color: AppColors.danger),
                    label: const Text('Reject', style: TextStyle(color: AppColors.danger)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String action) async {
    final commentCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action == 'approve' ? 'Approve' : 'Reject'} Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(approval.category, style: const TextStyle(color: AppColors.textTertiary)),
                  const SizedBox(height: 4),
                  Text(formatFullCurrency(approval.amount),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'JetBrainsMono')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentCtrl,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Comments (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: action == 'approve'
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.success)
                : ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: Text(action == 'approve' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final api = ref.read(apiServiceProvider);
        final url = action == 'approve'
            ? ApiConfig.approve(societyId, approval.id)
            : ApiConfig.reject(societyId, approval.id);
        await api.post(url, data: {'comments': commentCtrl.text});
        ref.invalidate(approvalsProvider(societyId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Expense ${action}d successfully')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to $action')));
        }
      }
    }
  }
}

class _HistoryTile extends StatelessWidget {
  final dynamic approval;
  const _HistoryTile({required this.approval});

  @override
  Widget build(BuildContext context) {
    final isApproved = approval.status == 'approved';
    final color = isApproved ? AppColors.success : AppColors.danger;
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
          Icon(isApproved ? Icons.check_circle : Icons.cancel, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(approval.category, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text('By ${approval.requestedByName}',
                    style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(formatFullCurrency(approval.amount),
              style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'JetBrainsMono', fontSize: 13, color: color)),
        ],
      ),
    );
  }
}
