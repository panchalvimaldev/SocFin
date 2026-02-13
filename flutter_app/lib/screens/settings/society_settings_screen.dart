import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../core/constants.dart';
import '../../providers/society_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/navigation/app_drawer.dart';

class SocietySettingsScreen extends ConsumerStatefulWidget {
  const SocietySettingsScreen({super.key});
  @override
  ConsumerState<SocietySettingsScreen> createState() => _SocietySettingsScreenState();
}

class _SocietySettingsScreenState extends ConsumerState<SocietySettingsScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _flatsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final soc = ref.read(societyProvider).current;
    if (soc == null) return;
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.get(ApiConfig.society(soc.id));
      final s = res.data;
      _nameCtrl.text = s['name'] ?? '';
      _addressCtrl.text = s['address'] ?? '';
      _flatsCtrl.text = '${s['total_flats'] ?? 0}';
      _descCtrl.text = s['description'] ?? '';
      _thresholdCtrl.text = '${s['approval_threshold'] ?? 50000}';
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.isEmpty) {
      _snack('Society name is required');
      return;
    }
    setState(() => _saving = true);
    final soc = ref.read(societyProvider).current!;
    try {
      final api = ref.read(apiServiceProvider);
      await api.put(ApiConfig.society(soc.id), data: {
        'name': _nameCtrl.text,
        'address': _addressCtrl.text,
        'total_flats': int.tryParse(_flatsCtrl.text) ?? 0,
        'description': _descCtrl.text,
        'approval_threshold': double.tryParse(_thresholdCtrl.text) ?? 50000,
      });
      _snack('Settings updated');
      ref.read(societyProvider.notifier).fetchSocieties();
    } catch (e) {
      _snack('Failed to update');
    }
    setState(() => _saving = false);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _flatsCtrl.dispose();
    _descCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final society = ref.watch(societyProvider);
    final isManager = society.isManager;

    return Scaffold(
      appBar: AppBar(title: const Text('Society Settings')),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Threshold Info
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
                      const Text('Approval Threshold',
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(
                        formatFullCurrency(double.tryParse(_thresholdCtrl.text) ?? 50000),
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
                            color: AppColors.primary, fontFamily: 'JetBrainsMono'),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Outward expenses above this amount require committee approval.',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Form
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
                      const Text('Society Details',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameCtrl,
                        enabled: isManager,
                        decoration: const InputDecoration(labelText: 'Society Name'),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _addressCtrl,
                        enabled: isManager,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Address'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _flatsCtrl,
                              enabled: isManager,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Total Flats'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextField(
                              controller: _thresholdCtrl,
                              enabled: isManager,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontFamily: 'JetBrainsMono'),
                              decoration: const InputDecoration(labelText: 'Threshold (Rs.)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descCtrl,
                        enabled: isManager,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      if (isManager) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.save, size: 18),
                            label: const Text('Save Changes'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
