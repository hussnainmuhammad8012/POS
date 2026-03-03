import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/modern_card.dart';

class AnalyticsScreen extends StatelessWidget {
  static const routeName = '/analytics';

  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          GlassHeader(
            title: 'Analytics',
            subtitle: 'Deep dive into your store performance',
            actions: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(LucideIcons.calendar),
                label: const Text('Last 30 Days'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(LucideIcons.download),
                label: const Text('Export Report'),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: KpiCard(
                        title: 'Total Revenue',
                        value: 'Rs 124,500.00',
                        icon: LucideIcons.indianRupee,
                        trend: '+14.5%',
                        isTrendPositive: true,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: KpiCard(
                        title: 'Avg Order Value',
                        value: 'Rs 840.50',
                        icon: LucideIcons.shoppingCart,
                        trend: '+2.1%',
                        isTrendPositive: true,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: KpiCard(
                        title: 'Net Profit',
                        value: 'Rs 32,450.00',
                        icon: LucideIcons.trendingUp,
                        trend: '+18.2%',
                        isTrendPositive: true,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: KpiCard(
                        title: 'Refunds',
                        value: 'Rs 1,200.00',
                        icon: LucideIcons.cornerUpLeft,
                        trend: '-5.4%',
                        isTrendPositive: true, // fewer refunds = good
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _RevenueChartCard(),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child: _TopCategoriesCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _TopProductsTableCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primary;

    return ModernCard(
      title: 'Revenue Over Time',
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        height: 300,
        child: BarChart(
          BarChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Theme.of(context).dividerTheme.color,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    '${(value / 1000).toStringAsFixed(0)}k',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final days = ['1', '5', '10', '15', '20', '25', '30'];
                    if (value.toInt() >= 0 && value.toInt() < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          days[value.toInt()],
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ),
            ),
            barGroups: [
              for (int i = 0; i < 7; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: (i * 2000.0) % 15000 + 5000,
                      color: primaryColor,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  const _TopCategoriesCard();

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'name': 'Beverages', 'amount': 'Rs 45K', 'percent': 1.0},
      {'name': 'Groceries', 'amount': 'Rs 32K', 'percent': 0.7},
      {'name': 'Snacks', 'amount': 'Rs 28K', 'percent': 0.6},
      {'name': 'Cleaning', 'amount': 'Rs 12K', 'percent': 0.3},
      {'name': 'Dairy', 'amount': 'Rs 7K', 'percent': 0.15},
    ];

    return ModernCard(
      title: 'Top Categories',
      child: Column(
        children: categories.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(c['amount'] as String, style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: c['percent'] as double,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TopProductsTableCard extends StatelessWidget {
  const _TopProductsTableCard();

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      title: 'Top Selling Products',
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          dividerThickness: 1,
          headingRowColor: WidgetStateProperty.resolveWith(
            (states) => Theme.of(context).scaffoldBackgroundColor,
          ),
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Units Sold')),
            DataColumn(label: Text('Revenue')),
            DataColumn(label: Text('Net Profit')),
            DataColumn(label: Text('Margin')),
          ],
          rows: [
            _buildRow(context, 'Mineral Water 1L', 450, 18000, 4500, 25),
            _buildRow(context, 'Wheat Bread', 380, 15200, 3100, 20),
            _buildRow(context, 'Potato Chips - Salted', 310, 6200, 2400, 38),
            _buildRow(context, 'Dishwashing Liquid', 240, 12000, 4800, 40),
            _buildRow(context, 'Cold Drink 500ml', 190, 7600, 1900, 25),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(BuildContext context, String name, int units, double revenue, double profit, double margin) {
    return DataRow(
      cells: [
        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
        DataCell(Text(units.toString())),
        DataCell(Text('Rs ${revenue.toStringAsFixed(0)}')),
        DataCell(Text('Rs ${profit.toStringAsFixed(0)}')),
        DataCell(Text('${margin.toStringAsFixed(1)}%')),
      ],
    );
  }
}
