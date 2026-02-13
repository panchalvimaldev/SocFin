import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';
import '../../providers/society_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});
  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  String _type = 'inward';
  String? _category;
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _vendorCtrl = TextEditingController();
  String _paymentMode = 'bank';
  DateTime _date = DateTime.now();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      setState(() {
        _type = _tabCtrl.index == 0 ? 'inward' : 'outward';
        _category = null;
      });
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _vendorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_category == null || _amountCtrl.text.isEmpty) {
      _snack('Please fill category and amount');
      return;
    }
    setState(() => _loading = true);
    final soc = ref.read(societyProvider).current!;
    try {
      final api = ref.read(apiServiceProvider);
      final res = await api.post(ApiConfig.transactions(soc.id), data: {
        'type': _type,
        'category': _category,
        'amount': double.parse(_amountCtrl.text),
        'description': _descCtrl.text,
        'vendor_name': _vendorCtrl.text,
        'payment_mode': _paymentMode,
        'date': '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      });
      final status = res.data['approval_status'];
      _snack(status == 'pending'
          ? 'Transaction sent for committee approval'
          : 'Transaction recorded successfully');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack('Failed to create transaction');
    }
    setState(() => _loading = false);
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final soc = ref.watch(societyProvider).current;
    if (soc == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final catAsync = ref.watch(transactionCategoriesProvider(soc.id));
    final cats = catAsync.whenOrNull(data: (d) => _type == 'inward' ? d.inward : d.outward) ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Type Tabs ─────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textTertiary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.south_west, size: 16), SizedBox(width: 6), Text('Inward')])),
                  Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.north_east, size: 16), SizedBox(width: 6), Text('Outward')])),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Category ──────────────────────────────
            const Text('Category *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _category,
              hint: const Text('Select category'),
              decoration: const InputDecoration(),
              items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v),
            ),
            const SizedBox(height: 18),

            // ── Amount + Date Row ─────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount (Rs.) *',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontFamily: 'JetBrainsMono'),
                        decoration: const InputDecoration(hintText: '0.00'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppColors.textTertiary),
                              const SizedBox(width: 8),
                              Text(
                                '${_date.day}/${_date.month}/${_date.year}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Payment Mode ──────────────────────────
            const Text('Payment Mode',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: ['cash', 'upi', 'bank'].map((mode) {
                final isSelected = _paymentMode == mode;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(mode.toUpperCase()),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _paymentMode = mode),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // ── Vendor (outward only) ─────────────────
            if (_type == 'outward') ...[
              const Text('Vendor Name',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _vendorCtrl,
                decoration: const InputDecoration(hintText: 'Vendor / Payee name'),
              ),
              const SizedBox(height: 18),
            ],

            // ── Description ───────────────────────────
            const Text('Description',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Add a note...'),
            ),
            const SizedBox(height: 28),

            // ── Submit ────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _submit,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Record Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
