import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class GenerateBillsScreen extends ConsumerStatefulWidget {
  const GenerateBillsScreen({super.key});

  @override
  ConsumerState<GenerateBillsScreen> createState() => _GenerateBillsScreenState();
}

class _GenerateBillsScreenState extends ConsumerState<GenerateBillsScreen> {
  bool _loading = false;
  bool _generating = false;
  Map<String, dynamic>? _settings;
  Map<String, dynamic>? _preview;
  List<dynamic> _schemes = [];
  
  String _billPeriodType = 'monthly';
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;
  bool _applyDiscount = false;
  String? _selectedScheme;

  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final settings = await ApiService.get('/maintenance/settings');
      final schemes = await ApiService.get('/maintenance/discount-schemes');
      setState(() {
        _settings = settings;
        _schemes = schemes.where((s) => s['is_active'] == true).toList();
      });
      _loadPreview();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _loadPreview() async {
    setState(() => _loading = true);
    try {
      final preview = await ApiService.post('/maintenance/bills/preview', {
        'bill_period_type': _billPeriodType,
        'month': _billPeriodType == 'monthly' ? _month : null,
        'year': _year,
        'apply_discount_scheme': _applyDiscount && _billPeriodType == 'yearly',
        'discount_scheme_id': _applyDiscount && _billPeriodType == 'yearly' ? _selectedScheme : null,
      });
      setState(() => _preview = preview);
    } catch (e) {
      debugPrint('Error loading preview: $e');
    }
    setState(() => _loading = false);
  }

  Future<void> _generateBills() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Generate Bills?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will create ${_preview?['total_flats'] ?? 0} bills for ${_billPeriodType == 'monthly' ? '${_months[_month - 1]} ' : ''}$_year',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _generating = true);
    try {
      final result = await ApiService.post('/maintenance/bills/generate', {
        'bill_period_type': _billPeriodType,
        'month': _billPeriodType == 'monthly' ? _month : null,
        'year': _year,
        'apply_discount_scheme': _applyDiscount && _billPeriodType == 'yearly',
        'discount_scheme_id': _applyDiscount && _billPeriodType == 'yearly' ? _selectedScheme : null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${result['bills_created']} bills generated!'), backgroundColor: Colors.green),
        );
        _loadPreview();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Generate Bills'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Configuration Card
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
                  Row(
                    children: const [
                      Icon(Icons.calculate, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Bill Configuration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 24),
                  
                  // Period Type
                  const Text('Bill Period Type', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildPeriodButton('Monthly', 'monthly'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildPeriodButton('Yearly', 'yearly'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Month selector (only for monthly)
                  if (_billPeriodType == 'monthly') ...[
                    const Text('Month', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: DropdownButton<int>(
                        value: _month,
                        isExpanded: true,
                        dropdownColor: AppColors.card,
                        underline: const SizedBox(),
                        style: const TextStyle(color: Colors.white),
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(_months[i]))),
                        onChanged: (v) { setState(() => _month = v!); _loadPreview(); },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Year selector
                  const Text('Year', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: DropdownButton<int>(
                      value: _year,
                      isExpanded: true,
                      dropdownColor: AppColors.card,
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      items: [2025, 2026, 2027].map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                      onChanged: (v) { setState(() => _year = v!); _loadPreview(); },
                    ),
                  ),
                  
                  // Discount scheme for yearly
                  if (_billPeriodType == 'yearly' && _schemes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Apply Discount Scheme', style: TextStyle(color: Colors.white)),
                      value: _applyDiscount,
                      onChanged: (v) { setState(() => _applyDiscount = v); _loadPreview(); },
                      activeColor: AppColors.primary,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_applyDiscount) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedScheme,
                          hint: const Text('Select scheme', style: TextStyle(color: AppColors.textTertiary)),
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          underline: const SizedBox(),
                          style: const TextStyle(color: Colors.white),
                          items: _schemes.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['scheme_name']))).toList(),
                          onChanged: (v) { setState(() => _selectedScheme = v); _loadPreview(); },
                        ),
                      ),
                    ],
                  ],
                  
                  // Current rate info
                  if (_settings != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('₹${_settings!['default_rate_per_sqft']} per sqft', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              Text('Due on ${_settings!['due_date_day']}th of each month', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Preview Card
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
                  Row(
                    children: const [
                      Icon(Icons.preview, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Bill Preview', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 24),
                  
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (_preview != null) ...[
                    // Summary row
                    Row(
                      children: [
                        _buildSummaryItem('Flats', '${_preview!['total_flats']}', Icons.home),
                        _buildSummaryItem('Area', '${_preview!['total_area_sqft']}', Icons.square_foot),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildSummaryItem('Total', '₹${_preview!['total_collection_before_discount']}', Icons.attach_money, color: AppColors.primary),
                        _buildSummaryItem('Net', '₹${_preview!['total_collection_after_discount']}', Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Bills list
                    const Text('Bills Preview', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...(_preview!['bills_preview'] as List).take(5).map((b) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          Text(b['flat_number'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          Text('${b['area_sqft']} sqft', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                          const SizedBox(width: 12),
                          Text('₹${b['final_amount']}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                    if ((_preview!['bills_preview'] as List).length > 5)
                      Text('...and ${(_preview!['bills_preview'] as List).length - 5} more flats', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generating ? null : _generateBills,
                        icon: _generating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.receipt_long),
                        label: Text(_generating ? 'Generating...' : 'Generate ${_preview!['total_flats']} Bills'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final selected = _billPeriodType == value;
    return GestureDetector(
      onTap: () { setState(() => _billPeriodType = value); _loadPreview(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.2) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : AppColors.borderSubtle),
        ),
        child: Center(
          child: Text(label, style: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
