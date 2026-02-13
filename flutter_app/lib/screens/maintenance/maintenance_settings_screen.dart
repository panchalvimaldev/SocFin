import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class MaintenanceSettingsScreen extends ConsumerStatefulWidget {
  const MaintenanceSettingsScreen({super.key});

  @override
  ConsumerState<MaintenanceSettingsScreen> createState() => _MaintenanceSettingsScreenState();
}

class _MaintenanceSettingsScreenState extends ConsumerState<MaintenanceSettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _settings = {};
  List<dynamic> _schemes = [];
  
  final _rateController = TextEditingController();
  final _dueDayController = TextEditingController();
  final _lateFeeController = TextEditingController();
  String _billingCycle = 'monthly';
  String _lateFeeType = 'flat';
  bool _discountEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final settings = await ApiService.get('/maintenance/settings');
      final schemes = await ApiService.get('/maintenance/discount-schemes');
      setState(() {
        _settings = settings;
        _schemes = schemes;
        _rateController.text = settings['default_rate_per_sqft']?.toString() ?? '5';
        _dueDayController.text = settings['due_date_day']?.toString() ?? '10';
        _lateFeeController.text = settings['late_fee_amount']?.toString() ?? '0';
        _billingCycle = settings['billing_cycle'] ?? 'monthly';
        _lateFeeType = settings['late_fee_type'] ?? 'flat';
        _discountEnabled = settings['is_discount_scheme_enabled'] ?? true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _saving = true);
    try {
      await ApiService.put('/maintenance/settings', {
        'default_rate_per_sqft': double.tryParse(_rateController.text) ?? 5,
        'billing_cycle': _billingCycle,
        'due_date_day': int.tryParse(_dueDayController.text) ?? 10,
        'late_fee_amount': double.tryParse(_lateFeeController.text) ?? 0,
        'late_fee_type': _lateFeeType,
        'is_discount_scheme_enabled': _discountEnabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Maintenance Settings'),
        backgroundColor: AppColors.surface,
      ),
      body: _loading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rate Settings Card
                  _buildCard(
                    title: 'Billing Rate',
                    icon: Icons.attach_money,
                    iconColor: AppColors.primary,
                    children: [
                      _buildTextField('Rate per Sq.Ft (₹)', _rateController, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      _buildDropdown('Billing Cycle', _billingCycle, ['monthly', 'quarterly', 'yearly'], (v) => setState(() => _billingCycle = v!)),
                      const SizedBox(height: 16),
                      _buildTextField('Due Date (Day of Month)', _dueDayController, keyboardType: TextInputType.number),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Late Fee Card
                  _buildCard(
                    title: 'Late Fee Configuration',
                    icon: Icons.schedule,
                    iconColor: Colors.amber,
                    children: [
                      _buildDropdown('Late Fee Type', _lateFeeType, ['flat', 'percentage'], (v) => setState(() => _lateFeeType = v!)),
                      const SizedBox(height: 16),
                      _buildTextField('Late Fee ${_lateFeeType == 'percentage' ? '(%)' : '(₹)'}', _lateFeeController, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Enable Discount Schemes', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Allow annual payment discounts', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        value: _discountEnabled,
                        onChanged: (v) => setState(() => _discountEnabled = v),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Discount Schemes Card
                  _buildCard(
                    title: 'Active Discount Schemes',
                    icon: Icons.percent,
                    iconColor: Colors.purple,
                    children: [
                      if (_schemes.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No discount schemes configured', style: TextStyle(color: AppColors.textTertiary)),
                        )
                      else
                        ..._schemes.map((s) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['scheme_name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    Text(
                                      'Pay ${s['eligible_months']} months → Get ${s['free_months']} free',
                                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: s['is_active'] ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s['is_active'] ? 'Active' : 'Inactive',
                                  style: TextStyle(color: s['is_active'] ? Colors.green : Colors.grey, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveSettings,
                      icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCard({required String title, required IconData icon, required Color iconColor, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ],
          ),
          const Divider(color: AppColors.borderSubtle, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.card,
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase()))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
