import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../config/routes.dart';
import '../../providers/society_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class MembersScreen extends ConsumerWidget {
  const MembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final society = ref.watch(societyProvider);
    final soc = society.current;
    if (soc == null) return const LoadingWidget();

    final membersAsync = ref.watch(membersProvider(soc.id));
    final flatsAsync = ref.watch(flatsProvider(soc.id));

    Color roleColor(String role) {
      switch (role) {
        case 'manager': return AppColors.primary;
        case 'committee': return AppColors.warning;
        case 'auditor': return const Color(0xFF8B5CF6);
        default: return AppColors.success;
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Members & Flats'),
          actions: [
            if (society.isManager)
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: () => _showAddMemberDialog(context, ref, soc.id),
              ),
          ],
          bottom: const TabBar(
            labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Members'),
              Tab(text: 'Flats'),
            ],
          ),
        ),
        drawer: const AppDrawer(),
        body: TabBarView(
          children: [
            // ── Members Tab ──────────────────────────
            membersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (members) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(membersProvider(soc.id)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: members.length,
                  itemBuilder: (_, i) {
                    final m = members[i];
                    final c = roleColor(m.role);
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
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: Text(
                              m.userName.isNotEmpty ? m.userName[0].toUpperCase() : '?',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.userName,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text(m.userEmail,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: c.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: c.withOpacity(0.3)),
                                ),
                                child: Text(m.role.toUpperCase(),
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c, letterSpacing: 0.8)),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: m.status == 'active'
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(m.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8, fontWeight: FontWeight.w700,
                                      color: m.status == 'active' ? AppColors.success : AppColors.danger,
                                    )),
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

            // ── Flats Tab ────────────────────────────
            flatsAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (flats) => RefreshIndicator(
                onRefresh: () async => ref.invalidate(flatsProvider(soc.id)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: flats.length,
                  itemBuilder: (_, i) {
                    final flat = flats[i];
                    return GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.flatLedger,
                        arguments: {'flatId': flat.id, 'flatNumber': flat.flatNumber},
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
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
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.home_outlined, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(flat.flatNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  Text('${flat.flatType} | ${flat.wing} Wing | Floor ${flat.floor}',
                                      style: const TextStyle(fontSize: 10, color: AppColors.textTertiary)),
                                ],
                              ),
                            ),
                            Text('${flat.areaSqft.toInt()} sqft',
                                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: AppColors.textTertiary)),
                            const SizedBox(width: 8),
                            const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.textTertiary),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref, String societyId) {
    final emailCtrl = TextEditingController();
    String role = 'member';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Member'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'User Email',
                  hintText: 'Enter registered email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              const Text('User must already be registered',
                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'member', child: Text('Member')),
                  DropdownMenuItem(value: 'committee', child: Text('Committee')),
                  DropdownMenuItem(value: 'auditor', child: Text('Auditor')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                ],
                onChanged: (v) => setDialogState(() => role = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (emailCtrl.text.isEmpty) return;
                try {
                  final api = ref.read(apiServiceProvider);
                  await api.post(ApiConfig.members(societyId), data: {
                    'email': emailCtrl.text.trim(),
                    'role': role,
                  });
                  Navigator.pop(ctx);
                  ref.invalidate(membersProvider(societyId));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Member added successfully')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to add member')));
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
