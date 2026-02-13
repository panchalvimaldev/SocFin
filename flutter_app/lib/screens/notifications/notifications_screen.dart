import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../core/constants.dart';
import '../../providers/society_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    final soc = ref.read(societyProvider).current;
    if (soc != null) {
      Future.microtask(() => ref.read(notificationProvider.notifier).fetch(soc.id));
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'approval': return Icons.warning_amber_rounded;
      case 'billing': return Icons.receipt_long;
      default: return Icons.info_outline;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'approval': return AppColors.warning;
      case 'billing': return AppColors.primary;
      default: return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final soc = ref.watch(societyProvider).current;
    final notifState = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Text('${notifState.unreadCount} unread',
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
        actions: [
          if (notifState.unreadCount > 0)
            TextButton(
              onPressed: () {
                if (soc != null) {
                  ref.read(notificationProvider.notifier).markAllRead(soc.id);
                }
              },
              child: const Text('Mark All Read', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: notifState.isLoading
          ? const LoadingWidget()
          : notifState.notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: AppColors.textTertiary),
                      SizedBox(height: 16),
                      Text('No notifications yet', style: TextStyle(color: AppColors.textTertiary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    if (soc != null) ref.read(notificationProvider.notifier).fetch(soc.id);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notifState.notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) {
                      final notif = notifState.notifications[i];
                      final color = _typeColor(notif.type);
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: notif.read ? AppColors.borderSubtle : AppColors.primary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(_typeIcon(notif.type), size: 18, color: color),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(notif.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: notif.read ? AppColors.textSecondary : AppColors.textPrimary,
                                            )),
                                      ),
                                      if (!notif.read)
                                        Container(
                                          width: 8, height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(notif.message,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 12, color: AppColors.textTertiary),
                                      const SizedBox(width: 4),
                                      Text(timeAgo(notif.createdAt),
                                          style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                      const Spacer(),
                                      if (!notif.read)
                                        GestureDetector(
                                          onTap: () => ref.read(notificationProvider.notifier).markRead(notif.id),
                                          child: const Text('Mark Read',
                                              style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
