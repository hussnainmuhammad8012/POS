import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/toast_notification.dart';
import '../application/suppliers_provider.dart';

class SupplierLedgerScreen extends StatefulWidget {
  final Supplier supplier;

  const SupplierLedgerScreen({super.key, required this.supplier});

  @override
  State<SupplierLedgerScreen> createState() => _SupplierLedgerScreenState();
}

class _SupplierLedgerScreenState extends State<SupplierLedgerScreen> {
  List<SupplierLedger>? _ledgers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLedgers();
  }

  Future<void> _loadLedgers() async {
    setState(() => _isLoading = true);
    try {
      final ledgers = await context.read<SuppliersProvider>().getLedger(widget.supplier.id!);
      if (mounted) {
        setState(() {
          _ledgers = ledgers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.show(context, title: 'Error', message: 'Failed to load ledger', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for supplier updates entirely from the provider 
    // to keep the Current Due updated in real time.
    final provider = context.watch<SuppliersProvider>();
    final supplierId = widget.supplier.id;
    final updatedSupplier = provider.suppliers.firstWhere(
      (s) => s.id == supplierId, 
      orElse: () => widget.supplier
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${updatedSupplier.name} Ledger'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Current Due: Rs ${updatedSupplier.currentDue.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.DANGER,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ledger History', style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, updatedSupplier),
                  icon: const Icon(LucideIcons.banknote),
                  label: const Text('Record Payment Made'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.darkBackground,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _ledgers == null || _ledgers!.isEmpty
                      ? const Center(child: Text('No ledger entries found for this supplier.'))
                      : ListView.separated(
                          itemCount: _ledgers!.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final entry = _ledgers![index];
                            final isPurchase = entry.type == 'PURCHASE';
                            final isPayment = entry.type == 'PAYMENT';
                            final isSystemNote = entry.type == 'SYSTEM_NOTE';

                            Color getIconColor() {
                              if (isPurchase) return AppColors.DANGER;
                              if (isPayment) return Colors.green;
                              return Theme.of(context).colorScheme.secondary;
                            }

                            IconData getIcon() {
                              if (isPurchase) return LucideIcons.packagePlus;
                              if (isPayment) return LucideIcons.banknote;
                              return LucideIcons.info;
                            }

                            String getTitle() {
                              if (isPurchase) return 'Purchase';
                              if (isPayment) return 'Payment Made';
                              return 'System Note';
                            }

                            return ListTile(
                              leading: Icon(getIcon(), color: getIconColor()),
                              title: Text(getTitle(), style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('MMM dd, yyyy HH:mm').format(entry.createdAt)),
                                  if (entry.notes != null && entry.notes!.isNotEmpty)
                                    Text('Notes: ${entry.notes}', style: const TextStyle(fontStyle: FontStyle.italic)),
                                ],
                              ),
                              trailing: isSystemNote
                                  ? const SizedBox.shrink()
                                  : Text(
                                      '${isPurchase ? "+" : "-"} Rs ${entry.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: getIconColor(),
                                        fontSize: 16,
                                      ),
                                    ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Supplier supplier) {
    if (supplier.currentDue <= 0) {
      AppToast.show(context, title: 'Notice', message: 'No dues pending for this supplier.', type: ToastType.info);
      // Let them record payment anyway if they wish, could be an advance.
    }

    final controller = TextEditingController(text: supplier.currentDue > 0 ? supplier.currentDue.toStringAsFixed(2) : '');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment Made'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current pending amount: Rs ${supplier.currentDue.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            CustomTextField(
              controller: controller,
              label: 'Amount Paid',
              prefixIcon: LucideIcons.banknote,
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: notesController,
              label: 'Notes / Reference (Optional)',
              prefixIcon: LucideIcons.stickyNote,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount <= 0) {
                AppToast.show(context, title: 'Error', message: 'Invalid amount', type: ToastType.error);
                return;
              }

              try {
                await context.read<SuppliersProvider>().recordPayment(
                  supplier.id!,
                  amount,
                  notes: notesController.text.isNotEmpty ? notesController.text : 'Manual Payment Recorded',
                );
                
                if (context.mounted) {
                   Navigator.pop(context);
                   _loadLedgers(); // Refresh ledger locally
                   AppToast.show(
                     context,
                     title: 'Payment Recorded',
                     message: 'Recorded payment of Rs ${amount.toStringAsFixed(2)}.',
                     type: ToastType.success,
                   );
                }
              } catch (e) {
                if (context.mounted) {
                  AppToast.show(
                    context,
                    title: 'Payment Failed',
                    message: e.toString(),
                    type: ToastType.error,
                  );
                }
              }
            },
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );
  }
}
