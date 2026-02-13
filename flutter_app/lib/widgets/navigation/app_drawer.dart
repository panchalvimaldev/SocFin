import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/society_provider.dart';
import '../../providers/notification_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final society = ref.watch(societyProvider);
    final notifs = ref.watch(notificationProvider);
    final role = society.role;

    final navItems = _getNavItems(role, notifs.unreadCount);

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(
                          auth.user?.name.isNotEmpty == true
                              ? auth.user!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.user?.name ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              auth.user?.email ?? '',
                              style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Society + Role Badge
                  if (society.current != null) ...[
                    Text(
                      society.current!.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _roleColor(role).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _roleColor(role).withOpacity(0.3)),
                      ),
                      child: Text(
                        role.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _roleColor(role),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Nav Items ───────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                itemCount: navItems.length,
                itemBuilder: (context, i) {
                  final item = navItems[i];
                  final isActive =
                      ModalRoute.of(context)?.settings.name == item['route'];
                  return _NavTile(
                    icon: item['icon'] as IconData,
                    label: item['label'] as String,
                    badge: item['badge'] as int? ?? 0,
                    isActive: isActive,
                    onTap: () {
                      Navigator.pop(context);
                      if (!isActive) {
                        Navigator.pushReplacementNamed(context, item['route'] as String);
                      }
                    },
                  );
                },
              ),
            ),

            // ── Footer ─────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderSubtle)),
              ),
              child: Column(
                children: [
                  _NavTile(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Switch Society',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.switchSociety);
                    },
                  ),
                  _NavTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: AppColors.danger,
                    onTap: () {
                      ref.read(authProvider.notifier).logout();
                      ref.read(societyProvider.notifier).clear();
                      Navigator.pushNamedAndRemoveUntil(
                          context, AppRoutes.login, (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getNavItems(String role, int unread) {
    final base = <Map<String, dynamic>>[
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard', 'route': AppRoutes.dashboard},
      {'icon': Icons.swap_horiz_rounded, 'label': 'Transactions', 'route': AppRoutes.transactions},
    ];

    if (role == 'manager') {
      base.addAll([
        {'icon': Icons.add_circle_outline, 'label': 'Add Transaction', 'route': AppRoutes.addTransaction},
        {'icon': Icons.receipt_long_rounded, 'label': 'Maintenance', 'route': AppRoutes.maintenance},
        {'icon': Icons.check_circle_outline, 'label': 'Approvals', 'route': AppRoutes.approvals},
        {'icon': Icons.bar_chart_rounded, 'label': 'Reports', 'route': AppRoutes.reports},
        {'icon': Icons.people_outline, 'label': 'Members', 'route': AppRoutes.members},
        {'icon': Icons.settings_outlined, 'label': 'Settings', 'route': AppRoutes.settings},
      ]);
    } else if (role == 'committee') {
      base.addAll([
        {'icon': Icons.check_circle_outline, 'label': 'Approvals', 'route': AppRoutes.approvals},
        {'icon': Icons.bar_chart_rounded, 'label': 'Reports', 'route': AppRoutes.reports},
      ]);
    } else if (role == 'auditor') {
      base.addAll([
        {'icon': Icons.receipt_long_rounded, 'label': 'Maintenance', 'route': AppRoutes.maintenance},
        {'icon': Icons.bar_chart_rounded, 'label': 'Reports', 'route': AppRoutes.reports},
      ]);
    } else {
      base.addAll([
        {'icon': Icons.receipt_long_rounded, 'label': 'My Bills', 'route': AppRoutes.maintenance},
        {'icon': Icons.bar_chart_rounded, 'label': 'Reports', 'route': AppRoutes.reports},
      ]);
    }

    base.add({
      'icon': Icons.notifications_outlined,
      'label': 'Notifications',
      'route': AppRoutes.notifications,
      'badge': unread,
    });

    return base;
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'manager':
        return AppColors.primary;
      case 'committee':
        return AppColors.warning;
      case 'auditor':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.success;
    }
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final bool isActive;
  final Color? color;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    this.badge = 0,
    this.isActive = false,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isActive ? AppColors.primary : AppColors.textSecondary);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isActive ? Border.all(color: AppColors.primary.withOpacity(0.2)) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
