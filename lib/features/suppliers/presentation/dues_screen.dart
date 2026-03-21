import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/models/entities.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/toast_notification.dart';
import '../application/suppliers_provider.dart';

class DuesScreen extends StatefulWidget {
  const DuesScreen({super.key});

  @override
  State<DuesScreen> createState() => _DuesScreenState();
}

class _DuesScreenState extends State<DuesScreen> {
  Supplier? _selectedSupplier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuppliersProvider>().loadSuppliers();
    });
  }

  void _selectSupplier(Supplier supplier) {
    setState(() => _selectedSupplier = supplier);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SuppliersProvider>();
    // Filter to only show suppliers with currentDue > 0
    final debtors = provider.filteredSuppliers.where((s) => s.currentDue > 0).toList();
    final totalDues = debtors.fold(0.0, (sum, s) => sum + s.currentDue);

    return Column(
      children: [
        const GlassHeader(
          title: 'Dues Management',
          subtitle: 'Track outstanding balances and payments to suppliers',
        ),
        Expanded(
            child: Row(
              children: [
                // Left Panel - Debtors List with Summary
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Column(
                    children: [
                      // Total Summary Card
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ModernCard(
                          backgroundColor: AppColors.WARNING.withValues(alpha: 0.1),
                          borderColor: AppColors.WARNING.withValues(alpha: 0.3),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.WARNING.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.alertTriangle, color: AppColors.WARNING),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Total Supplier Dues', 
                                      style: TextStyle(fontSize: 13, color: AppColors.WARNING, fontWeight: FontWeight.bold)
                                    ),
                                    Text('Rs ${NumberFormat('#,##0').format(totalDues)}', 
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: AppColors.WARNING, 
                                        fontWeight: FontWeight.bold
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Search Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: CustomTextField(
                          hint: 'Search suppliers...',
                          prefixIcon: LucideIcons.search,
                          onChanged: (v) => provider.setSearchQuery(v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      // Debtors List
                      Expanded(
                        child: debtors.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(LucideIcons.truck, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                                    const SizedBox(height: 16),
                                    const Text('No outstanding dues'),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: debtors.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final s = debtors[index];
                                  final isSelected = _selectedSupplier?.id == s.id;
                                  return ModernCard(
                                    onTap: () => _selectSupplier(s),
                                    padding: const EdgeInsets.all(16),
                                    borderColor: isSelected ? Theme.of(context).primaryColor : null,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Theme.of(context).primaryColor.withAlpha(30),
                                          child: Text(s.name[0].toUpperCase(), 
                                            style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                              Text(s.phone ?? 'No phone', style: Theme.of(context).textTheme.bodySmall),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          'Rs ${NumberFormat('#,##0').format(s.currentDue)}',
                                          style: const TextStyle(color: AppColors.WARNING, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                // Right Panel - Ledger
                Expanded(
                  child: _selectedSupplier == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.bookOpen, size: 64, color: Colors.grey.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              const Text('Select a supplier to view dues ledger', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : _SupplierDuesLedgerView(
                          supplier: provider.suppliers.firstWhere((s) => s.id == _selectedSupplier!.id, orElse: () => _selectedSupplier!),
                        ),
                ),
              ],
            ),
          ),
        ],
      );
  }
}

class _SupplierDuesLedgerView extends StatefulWidget {
  final Supplier supplier;

  const _SupplierDuesLedgerView({required this.supplier});

  @override
  State<_SupplierDuesLedgerView> createState() => _SupplierDuesLedgerViewState();
}

class _SupplierDuesLedgerViewState extends State<_SupplierDuesLedgerView> {
  List<SupplierLedger>? _ledgers;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLedgers();
  }

  @override
  void didUpdateWidget(covariant _SupplierDuesLedgerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.supplier.id != widget.supplier.id ||
        oldWidget.supplier.currentDue != widget.supplier.currentDue ||
        oldWidget.supplier.totalPurchased != widget.supplier.totalPurchased) {
      _loadLedgers();
    }
  }

  Future<void> _loadLedgers() async {
    setState(() => _isLoading = true);
    try {
      final data = await context.read<SuppliersProvider>().getLedger(widget.supplier.id!);
      if (mounted) {
        setState(() {
          _ledgers = data.where((l) => l.type != 'SYSTEM_NOTE').toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ledgers = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.supplier.name, style: Theme.of(context).textTheme.headlineMedium),
                  Text('Pending Payable: Rs ${widget.supplier.currentDue.toStringAsFixed(2)}', 
                    style: const TextStyle(color: AppColors.WARNING, fontSize: 18, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showPaymentDialog(context),
                icon: const Icon(LucideIcons.banknote),
                label: const Text('Record Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBackground,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Ledger History', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : (_ledgers == null || _ledgers!.isEmpty)
                    ? const Center(child: Text('No purchase/payment history found'))
                    : ListView.separated(
                        itemCount: _ledgers!.length,
                        separatorBuilder: (_, __) => const Divider(),
                        itemBuilder: (context, index) {
                          final entry = _ledgers![index];
                          final isPurchase = entry.type == 'PURCHASE';
                          
                          // Check if overdue
                          final isOverdue = isPurchase && entry.dueDate != null && DateTime.now().isAfter(entry.dueDate!);
                          
                          return ListTile(
                            leading: Icon(
                              isPurchase ? LucideIcons.shoppingCart : LucideIcons.checkCircle2,
                              color: isPurchase ? AppColors.WARNING : Colors.green,
                            ),
                            title: Row(
                              children: [
                                Text(isPurchase ? 'Stock Purchased' : 'Payment Sent'),
                                if (isOverdue) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.DANGER.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('OVERDUE', style: TextStyle(color: AppColors.DANGER, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                ]
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(DateFormat('MMM dd, yyyy HH:mm').format(entry.createdAt)),
                                if (entry.notes != null && entry.notes!.isNotEmpty)
                                  Text(entry.notes!, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                if (isPurchase && entry.dueDate != null)
                                  Text('Due by: ${DateFormat('MMM dd, yyyy').format(entry.dueDate!)}', 
                                    style: TextStyle(color: isOverdue ? AppColors.DANGER : null, fontWeight: isOverdue ? FontWeight.bold : null)
                                  ),
                              ],
                            ),
                            trailing: Text(
                              '${isPurchase ? "+" : "-"} Rs ${entry.amount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isPurchase ? AppColors.WARNING : Colors.green,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context) {
    final controller = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment to Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              label: 'Notes / Cheque No.',
              prefixIcon: LucideIcons.stickyNote,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount <= 0) return;

              try {
                await context.read<SuppliersProvider>().recordPayment(
                  widget.supplier.id!,
                  amount,
                  notes: notesController.text,
                );
                if (context.mounted) {
                   Navigator.pop(context);
                   _loadLedgers(); // refresh ledger view
                   AppToast.show(
                     context,
                     title: 'Payment Recorded',
                     message: 'Paid Rs ${amount.toStringAsFixed(2)} to ${widget.supplier.name}.',
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
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }
}
