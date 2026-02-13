import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/society_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/society_model.dart';

class SocietySwitchScreen extends ConsumerStatefulWidget {
  const SocietySwitchScreen({super.key});
  @override
  ConsumerState<SocietySwitchScreen> createState() => _SocietySwitchScreenState();
}

class _SocietySwitchScreenState extends ConsumerState<SocietySwitchScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(societyProvider.notifier).fetchSocieties());
  }

  void _selectSociety(SocietyModel society) {
    ref.read(societyProvider.notifier).selectSociety(society);
    ref.read(notificationProvider.notifier).fetch(society.id);
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final society = ref.watch(societyProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.account_balance_rounded,
                      size: 36, color: AppColors.primary),
                ),
                const SizedBox(height: 20),
                Text(
                  'Welcome, ${auth.user?.name.split(' ').first ?? ''}',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 6),
                const Text('Choose a society to continue',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                const SizedBox(height: 32),

                if (society.isLoading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (society.societies.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.account_balance_rounded,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        const Text('No Societies Yet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        const Text(
                          'Create a new society or ask a manager to add you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.createSociety),
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Create Society'),
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  ...society.societies.asMap().entries.map((entry) {
                    final i = entry.key;
                    final s = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _SocietyCard(
                        society: s,
                        roleColor: _roleColor(s.role),
                        onTap: () => _selectSociety(s),
                        delay: Duration(milliseconds: 80 * i),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.createSociety),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Create New Society'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocietyCard extends StatefulWidget {
  final SocietyModel society;
  final Color roleColor;
  final VoidCallback onTap;
  final Duration delay;

  const _SocietyCard({
    required this.society,
    required this.roleColor,
    required this.onTap,
    required this.delay,
  });

  @override
  State<_SocietyCard> createState() => _SocietyCardState();
}

class _SocietyCardState extends State<_SocietyCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_rounded,
                        color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.society.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 15),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.roleColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: widget.roleColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                widget.society.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: widget.roleColor,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.society.address,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textTertiary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.home_outlined,
                                size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text('${widget.society.totalFlats} flats',
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textTertiary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
