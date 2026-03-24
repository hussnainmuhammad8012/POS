import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class ConfirmPaymentDialog extends StatefulWidget {
  final double total;
  final Map<String, dynamic>? customer;
  final List<String> paymentMethods;

  const ConfirmPaymentDialog({
    super.key,
    required this.total,
    this.customer,
    required this.paymentMethods,
  });

  @override
  State<ConfirmPaymentDialog> createState() => _ConfirmPaymentDialogState();
}

class _ConfirmPaymentDialogState extends State<ConfirmPaymentDialog> {
  late TextEditingController _cashController;
  double _creditAmount = 0.0;
  DateTime? _dueDate;
  late String _selectedMethod;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(text: widget.total.toStringAsFixed(2));
    _selectedMethod = widget.paymentMethods.isNotEmpty ? widget.paymentMethods.first : 'CASH';
    _cashController.addListener(_updateCredit);
    
    // Explicitly check for walk-in on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isWalkIn) {
        _cashController.text = widget.total.toStringAsFixed(2);
      }
    });
  }

  bool get _isWalkIn => widget.customer == null || widget.customer!['id'] == null || widget.customer!['name'] == 'Walk-in Customer';

  void _updateCredit() {
    if (_isWalkIn) {
      final val = double.tryParse(_cashController.text) ?? 0.0;
      if (val < widget.total) {
        // Force total if they try to enter less for walk-in
        _cashController.text = widget.total.toStringAsFixed(2);
        _cashController.selection = TextSelection.collapsed(offset: _cashController.text.length);
      }
    }
    
    final cash = double.tryParse(_cashController.text) ?? 0.0;
    setState(() {
      _creditAmount = (widget.total - cash).clamp(0, widget.total);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Center(child: Text('Confirm Payment')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.STAR_PRIMARY.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bill:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Rs ${widget.total.toStringAsFixed(2)}', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.STAR_PRIMARY)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              autofocus: true,
              enabled: !_isWalkIn, // Keep it editable but we enforce it in listener
              decoration: InputDecoration(
                labelText: _isWalkIn ? 'Cash Received (Fixed for Walk-in)' : 'Cash Received',
                prefixIcon: const Icon(LucideIcons.banknote),
                hintText: widget.total.toStringAsFixed(2),
                suffixIcon: _isWalkIn ? null : IconButton(
                  icon: const Icon(LucideIcons.delete),
                  onPressed: () => _cashController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(LucideIcons.creditCard),
              ),
              items: widget.paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
              onChanged: (v) => setState(() => _selectedMethod = v!),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Credit Amount:'),
                Text('Rs ${_creditAmount.toStringAsFixed(2)}', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _creditAmount > 0 ? AppColors.DANGER : AppColors.SUCCESS,
                    fontSize: 16,
                  )
                ),
              ],
            ),
            if (_creditAmount > 0) ...[
              const SizedBox(height: 16),
              if (_isWalkIn)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Note: Credit is only allowed for registered customers.',
                    style: TextStyle(color: AppColors.DANGER, fontSize: 10, fontStyle: FontStyle.italic),
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(LucideIcons.calendar),
                title: const Text('Return Due Date'),
                subtitle: Text(_dueDate == null ? 'Not Selected' : DateFormat('dd MMM, yyyy').format(_dueDate!)),
                trailing: const Icon(LucideIcons.chevronRight),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_creditAmount > 0 && widget.customer == null) ? null : () {
            final cash = double.tryParse(_cashController.text) ?? 0.0;
            Navigator.pop(context, {
              'cashPaid': cash,
              'creditAmount': _creditAmount,
              'dueDate': _dueDate,
              'paymentMethod': _selectedMethod,
            });
          },
          child: const Text('COMPLETE SALE'),
        ),
      ],
    );
  }
}
