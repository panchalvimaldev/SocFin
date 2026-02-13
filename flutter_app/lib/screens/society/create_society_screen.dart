import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../config/api_config.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/society_provider.dart';
import '../../services/api_service.dart';

class CreateSocietyScreen extends ConsumerStatefulWidget {
  const CreateSocietyScreen({super.key});
  @override
  ConsumerState<CreateSocietyScreen> createState() => _CreateSocietyScreenState();
}

class _CreateSocietyScreenState extends ConsumerState<CreateSocietyScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _flatsCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _thresholdCtrl = TextEditingController(text: '50000');
  bool _loading = false;

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _addressCtrl.text.isEmpty) {
      _snack('Name and address are required');
      return;
    }
    setState(() => _loading = true);
    try {
      final api = ref.read(apiServiceProvider);
      await api.post(ApiConfig.societies, data: {
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'total_flats': int.tryParse(_flatsCtrl.text) ?? 0,
        'description': _descCtrl.text.trim(),
        'approval_threshold': double.tryParse(_thresholdCtrl.text) ?? 50000,
      });
      _snack('Society created! You are now the Manager.');
      await ref.read(societyProvider.notifier).fetchSocieties();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.switchSociety);
      }
    } catch (e) {
      _snack('Failed to create society');
    }
    setState(() => _loading = false);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Society')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.account_balance_rounded, size: 32, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            const Text('Create New Society',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('You will be assigned as Manager',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            const SizedBox(height: 28),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Society Name *', hintText: 'e.g., Sunrise Apartments'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Address *', hintText: 'Full address with city'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _flatsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Flats', hintText: '440'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _thresholdCtrl,
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
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Create Society'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
