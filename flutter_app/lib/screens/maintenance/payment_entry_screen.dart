import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/navigation/app_drawer.dart';
import '../../widgets/common/loading_widget.dart';

class PaymentEntryScreen extends ConsumerStatefulWidget {
  const PaymentEntryScreen({super.key});

  @override
  ConsumerState<PaymentEntryScreen> createState() => _PaymentEntryScreenState();
}

class _PaymentEntryScreenState extends ConsumerState<PaymentEntryScreen> {
  bool _loading = true;
  bool _submitting = false;
  List<dynamic> _flats = [];
  List<dynamic> _bills = [];
  List<dynamic> _schemes = [];
  Map<String, dynamic>? _annualPreview;
  
  String? _selectedFlat;
  List<String> _selectedBills = [];
  String _paymentMode = 'upi';
  bool _isAnnualPayment = false;
  String? _selectedScheme;
  
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  final _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFlats();
    _loadSchemes();
  }

  Future<void> _loadFlats() async {
    try {
      final flats = await ApiService.get('/flats');
      setState(() { _flats = flats; _loading = false; });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadSchemes() async {
    try {
      final schemes = await ApiService.get('/maintenance/discount-schemes');
      setState(() => _schemes = schemes.where((s) => s['is_active'] == true).toList());
    } catch (e) {
      debugPrint('Error loading schemes: $e');
    }
  }

  Future<void> _loadBills(String flatId) async {
    try {
      final bills = await ApiService.get('/maintenance/bills?flat_id=$flatId&status=pending');
      setState(() => _bills = bills);
    } catch (e) {
      debugPrint('Error loading bills: $e');
    }
  }

  Future<void> _loadAnnualPreview() async {
    if (_selectedFlat == null || _selectedScheme == null) return;
    try {
      final preview = await ApiService.post('/maintenance/annual-payment/preview', {
        'flat_id': _selectedFlat,
        'year': DateTime.now().year,
        'discount_scheme_id': _selectedScheme,
      });
      setState(() => _annualPreview = preview);
    } catch (e) {
      debugPrint('Error loading preview: $e');
    }
  }

  double _calculateTotal() {
    if (_amountController.text.isNotEmpty) return double.tryParse(_amountController.text) ?? 0;
    if (_isAnnualPayment && _annualPreview != null) return (_annualPreview!['final_payable'] as num).toDouble();
    return _selectedBills.fold(0.0, (sum, billId) {
      final bill = _bills.firstWhere((b) => b['id'] == billId, orElse: () => {});
      final payable = (bill['final_payable_amount'] ?? 0) as num;
      final paid = (bill['paid_amount'] ?? 0) as num;
      return sum + payable - paid;
    });
  }

  Future<void> _submitPayment() async {
    if (_selectedFlat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a flat'), backgroundColor: Colors.red));
      return;
    }
    final amount = _calculateTotal();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ApiService.post('/maintenance/payments', {
        'flat_id': _selectedFlat,
        'bill_ids': _isAnnualPayment ? [] : _selectedBills,
        'amount_paid': amount,
        'payment_mode': _paymentMode,
        'payment_date': DateTime.now().toIso8601String().split('T')[0],
        'transaction_reference': _refController.text,
        'remarks': _remarksController.text,
        'is_annual_payment': _isAnnualPayment,
        'discount_scheme_id': _isAnnualPayment ? _selectedScheme : null,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment recorded! Receipt: ${result['receipt_number']}'), backgroundColor: Colors.green),
        );
        // Reset form
        setState(() {
          _selectedFlat = null;
          _selectedBills = [];
          _bills = [];
          _annualPreview = null;
          _amountController.clear();
          _refController.clear();
          _remarksController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final selectedFlatData = _flats.firstWhere((f) => f['id'] == _selectedFlat, orElse: () => null);
    final total = _calculateTotal();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Record Payment'),
        backgroundColor: AppColors.surface,
      ),
      body: _loading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flat Selection
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
                            Icon(Icons.credit_card, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Payment Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                          ],
                        ),
                        const Divider(color: AppColors.borderSubtle, height: 24),
                        
                        // Flat dropdown
                        const Text('Select Flat', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedFlat,
                            hint: const Text('Choose flat', style: TextStyle(color: AppColors.textTertiary)),
                            isExpanded: true,
                            dropdownColor: AppColors.card,
                            underline: const SizedBox(),
                            style: const TextStyle(color: Colors.white),
                            items: _flats.map((f) => DropdownMenuItem(
                              value: f['id'] as String,
                              child: Text('${f['flat_number']} - ${f['wing']} Wing (${f['area_sqft']} sqft)'),
                            )).toList(),
                            onChanged: (v) {
                              setState(() {
                                _selectedFlat = v;
                                _selectedBills = [];
                                _annualPreview = null;
                              });
                              if (v != null) _loadBills(v);
                            },
                          ),
                        ),
                        
                        if (_selectedFlat != null) ...[
                          const SizedBox(height: 16),
                          
                          // Payment type toggle
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() { _isAnnualPayment = false; _annualPreview = null; }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_isAnnualPayment ? AppColors.primary.withOpacity(0.2) : AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: !_isAnnualPayment ? AppColors.primary : AppColors.borderSubtle),
                                    ),
                                    child: Center(child: Text('Monthly Bills', style: TextStyle(color: !_isAnnualPayment ? AppColors.primary : AppColors.textSecondary))),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () { setState(() => _isAnnualPayment = true); _loadAnnualPreview(); },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _isAnnualPayment ? Colors.green.withOpacity(0.2) : AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: _isAnnualPayment ? Colors.green : AppColors.borderSubtle),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_awesome, size: 16, color: _isAnnualPayment ? Colors.green : AppColors.textSecondary),
                                        const SizedBox(width: 4),
                                        Text('Annual', style: TextStyle(color: _isAnnualPayment ? Colors.green : AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Monthly bills selection
                          if (!_isAnnualPayment) ...[
                            const Text('Pending Bills', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                            const SizedBox(height: 8),
                            if (_bills.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                                child: const Center(child: Text('No pending bills', style: TextStyle(color: AppColors.textTertiary))),
                              )
                            else
                              ..._bills.map((bill) {
                                final isSelected = _selectedBills.contains(bill['id']);
                                final payable = (bill['final_payable_amount'] ?? 0) - (bill['paid_amount'] ?? 0);
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedBills.remove(bill['id']);
                                      } else {
                                        _selectedBills.add(bill['id']);
                                      }
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: isSelected ? AppColors.primary.withOpacity(0.5) : AppColors.borderSubtle),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(isSelected ? Icons.check_box : Icons.check_box_outline_blank, color: isSelected ? AppColors.primary : AppColors.textTertiary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${bill['month']}/${bill['year']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                              Text('Due: ${bill['due_date']}', style: const TextStyle(color: AppColors.textTertiary, fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        Text('₹${payable.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                          ],
                          
                          // Annual payment scheme selection
                          if (_isAnnualPayment && _schemes.isNotEmpty) ...[
                            const Text('Discount Scheme', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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
                                onChanged: (v) { setState(() => _selectedScheme = v); _loadAnnualPreview(); },
                              ),
                            ),
                            if (_annualPreview != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Annual Total', style: TextStyle(color: AppColors.textSecondary)),
                                        Text('₹${_annualPreview!['total_before_discount']}', style: const TextStyle(color: Colors.white)),
                                      ],
                                    ),
                                    if (_annualPreview!['discount_amount'] > 0) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Discount (${_annualPreview!['free_months']} months free)', style: const TextStyle(color: Colors.green, fontSize: 12)),
                                          Text('-₹${_annualPreview!['discount_amount']}', style: const TextStyle(color: Colors.green)),
                                        ],
                                      ),
                                    ],
                                    const Divider(color: Colors.green, height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Final Payable', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                        Text('₹${_annualPreview!['final_payable']}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),
                          
                          // Payment mode
                          const Text('Payment Mode', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['upi', 'bank', 'cash', 'cheque'].map((mode) => ChoiceChip(
                              label: Text(mode.toUpperCase()),
                              selected: _paymentMode == mode,
                              onSelected: (_) => setState(() => _paymentMode = mode),
                              selectedColor: AppColors.primary.withOpacity(0.3),
                              labelStyle: TextStyle(color: _paymentMode == mode ? AppColors.primary : AppColors.textSecondary, fontSize: 12),
                            )).toList(),
                          ),
                          const SizedBox(height: 16),
                          
                          // Transaction reference
                          const Text('Transaction Reference', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _refController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'UPI ID / Cheque No.',
                              hintStyle: const TextStyle(color: AppColors.textTertiary),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Custom amount
                          const Text('Custom Amount (optional)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Leave empty to use calculated',
                              hintStyle: const TextStyle(color: AppColors.textTertiary),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppColors.borderSubtle)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary Card
                  if (selectedFlatData != null)
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
                              Icon(Icons.receipt, color: Colors.green, size: 20),
                              SizedBox(width: 8),
                              Text('Payment Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                            ],
                          ),
                          const Divider(color: AppColors.borderSubtle, height: 24),
                          
                          // Flat info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.home, color: AppColors.primary, size: 32),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(selectedFlatData['flat_number'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text('${selectedFlatData['wing']} Wing • ${selectedFlatData['area_sqft']} sqft', style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Total
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                              Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 24)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitting || total <= 0 ? null : _submitPayment,
                              icon: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check),
                              label: Text(_submitting ? 'Recording...' : 'Record Payment ₹${total.toStringAsFixed(0)}'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 14)),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
