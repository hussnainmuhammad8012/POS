// lib/features/inventory/presentation/stock_movement_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/glass_header.dart';
import '../application/stock_provider.dart';
import 'widgets/stock_tab.dart'; // Reuse the stock tab widget or create a more detailed one

class StockMovementScreen extends StatelessWidget {
  static const routeName = '/stock-movements';

  const StockMovementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GlassHeader(
            title: 'Stock Movements',
            subtitle: 'Track intake, sales, and adjustments',
            actions: [
              ElevatedButton.icon(
                onPressed: () {}, // Trigger Receive Stock Dialog
                icon: const Icon(LucideIcons.plusCircle),
                label: const Text('Receive Stock'),
              ),
            ],
          ),
          const Expanded(
            child: StockTab(), // Reusing the StockTab widget for the full screen view
          ),
        ],
      ),
    );
  }
}
