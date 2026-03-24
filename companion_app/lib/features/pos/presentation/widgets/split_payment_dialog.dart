import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';

class SplitPaymentDialog extends StatefulWidget {
  final double total;

  const SplitPaymentDialog({required this.total});

  @override
  State<SplitPaymentDialog> createState() => _SplitPaymentDialogState();
}

class _SplitPaymentDialogState extends State<SplitPaymentDialog> {
  late TextEditingController _cashController;
  double _creditAmount = 0.0;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _cashController = TextEditingController(text: widget.total.toStringAsFixed(2));
    _cashController.addListener(_updateCredit);
  }

  void _updateCredit() {
    final cash = double.tryParse(_cashController.text) ?? 0.0;
    setState(() {
      _creditAmount = (widget.total - cash).clamp(0, widget.total);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:'),
                Text('Rs ${widget.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _cashController,
              decoration: const InputDecoration(
                labelText: 'Cash Received',
                prefixIcon: Icon(LucideIcons.banknote),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Remaining to Credit:'),
                Text('Rs ${_creditAmount.toStringAsFixed(2)}', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _creditAmount > 0 ? AppColors.DANGER : Colors.green,
                  )
                ),
              ],
            ),
            if (_creditAmount > 0) ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Due Date', style: TextStyle(fontSize: 14)),
                subtitle: Text(_dueDate == null ? 'Not set' : DateFormat('MMM dd, yyyy').format(_dueDate!)),
                trailing: const Icon(LucideIcons.calendar),
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
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'cash': double.tryParse(_cashController.text) ?? 0.0,
              'credit': _creditAmount,
              'dueDate': _dueDate,
            });
          },
          child: const Text('CONFIRM'),
        ),
      ],
    );
  }
}
