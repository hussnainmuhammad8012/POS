import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glass_header.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/toast_notification.dart';
import '../application/analytics_provider.dart';
import '../../settings/application/settings_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics';

  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _currencyFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    final settings = context.watch<SettingsProvider>();
    final kpi = provider.kpi;

    return Scaffold(
      body: provider.isLoading && provider.revenueTrend.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                GlassHeader(
                  title: 'Analytics',
                  subtitle: 'Deep dive into your store performance',
                  actions: [
                    ElevatedButton.icon(
                      onPressed: () => _showExportDialog(context, provider, settings),
                      icon: const Icon(LucideIcons.download),
                      label: const Text('Export Report'),
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: provider.refreshData,
                    child: ListView(
                      padding: const EdgeInsets.all(24.0),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: KpiCard(
                                title: 'Total Revenue',
                                value: _currencyFormat.format(kpi.totalRevenue),
                                icon: LucideIcons.indianRupee,
                                accentColor: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: KpiCard(
                                title: 'Total Credit',
                                value: _currencyFormat.format(kpi.totalCreditToCollect),
                                icon: LucideIcons.wallet,
                                accentColor: AppColors.DANGER,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: KpiCard(
                                title: 'Net Profit',
                                value: _currencyFormat.format(kpi.netProfit),
                                icon: LucideIcons.trendingUp,
                                accentColor: AppColors.SUCCESS,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: KpiCard(
                                title: 'Total Cost',
                                value: _currencyFormat.format(kpi.totalCost),
                                icon: LucideIcons.shoppingBag,
                                accentColor: Colors.orange,
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
                              child: _RevenueChartCard(trend: provider.revenueTrend),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 1,
                              child: _TopCategoriesCard(categories: provider.salesByCategory),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _TopProductsTableCard(products: provider.topProducts),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showExportDialog(BuildContext context, AnalyticsProvider provider, SettingsProvider settings) {
    showDialog(
      context: context,
      builder: (context) => _ExportReportDialog(
        onExport: (start, end) async {
          final path = await provider.generateReport(
            storeName: settings.storeName,
            storeAddress: settings.storeAddress,
            start: start,
            end: end,
          );
          if (path != null && context.mounted) {
            AppToast.show(
              context,
              title: 'Success',
              message: 'Report saved to $path',
              type: ToastType.success,
            );
          }
        },
      ),
    );
  }
}

class _ExportReportDialog extends StatefulWidget {
  final Future<void> Function(DateTime start, DateTime end) onExport;

  const _ExportReportDialog({required this.onExport});

  @override
  State<_ExportReportDialog> createState() => _ExportReportDialogState();
}

class _ExportReportDialogState extends State<_ExportReportDialog> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AnalyticsProvider>();
    return AlertDialog(
      title: const Text('Export Analytics Report'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Report Range'),
            subtitle: Text('${DateFormat('dd MMM').format(_startDate)} - ${DateFormat('dd MMM').format(_endDate)}'),
            trailing: const Icon(LucideIcons.calendar),
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
              );
              if (range != null) {
                setState(() {
                  _startDate = range.start;
                  _endDate = range.end;
                });
              }
            },
          ),
          const Divider(),
          Wrap(
            spacing: 8,
            children: [
              ActionChip(
                label: const Text('Last Week'),
                onPressed: () => setState(() {
                  _startDate = DateTime.now().subtract(const Duration(days: 7));
                  _endDate = DateTime.now();
                }),
              ),
              ActionChip(
                label: const Text('Last Month'),
                onPressed: () => setState(() {
                  _startDate = DateTime(DateTime.now().year, DateTime.now().month - 1, DateTime.now().day);
                  _endDate = DateTime.now();
                }),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: provider.isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: provider.isLoading
              ? null
              : () async {
                  await widget.onExport(_startDate, _endDate);
                  if (context.mounted) Navigator.pop(context);
                },
          child: provider.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Generate PDF'),
        ),
      ],
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  final Map<String, double> trend;
  const _RevenueChartCard({required this.trend});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final dataPoints = trend.entries.toList();
    
    // Get max value for scaling
    double maxY = 1000;
    for (var e in trend.values) {
      if (e > maxY) maxY = e;
    }
    maxY = (maxY / 1000).ceil() * 1000.0 + 1000;

    return ModernCard(
      title: 'Revenue Over Time',
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        height: 300,
        child: trend.isEmpty
            ? const Center(child: Text('No data for this period'))
            : BarChart(
                BarChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerTheme.color?.withValues(alpha: 0.1) ?? Colors.grey.withValues(alpha: 0.1),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) => Text(
                          value >= 1000 ? '${(value / 1000).toStringAsFixed(0)}k' : value.toStringAsFixed(0),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < dataPoints.length) {
                            final dateStr = dataPoints[value.toInt()].key;
                            final date = DateTime.parse(dateStr);
                            // Only show labels for every few days if there are many points
                            if (dataPoints.length > 10 && value.toInt() % 3 != 0) return const SizedBox();
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(dataPoints.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: dataPoints[i].value,
                          color: primaryColor,
                          width: dataPoints.length > 20 ? 8 : 16,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        ),
                      ],
                    );
                  }),
                  maxY: maxY,
                ),
              ),
      ),
    );
  }
}

class _TopCategoriesCard extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  const _TopCategoriesCard({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const ModernCard(title: 'Top Categories', child: Center(child: Text('No data')));
    }

    final maxVal = (categories.first['value'] as num).toDouble();

    return ModernCard(
      title: 'Top Categories',
      child: Column(
        children: categories.take(5).map((c) {
          final val = (c['value'] as num).toDouble();
          final percent = maxVal > 0 ? val / maxVal : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(c['label'] as String, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('Rs ${(val / 1000).toStringAsFixed(1)}k', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percent,
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
  final List<Map<String, dynamic>> products;
  const _TopProductsTableCard({required this.products});

  @override
  Widget build(BuildContext context) {
    final curFormat = NumberFormat.currency(symbol: 'Rs ', decimalDigits: 0);

    return ModernCard(
      title: 'Top Selling Products',
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: double.infinity,
        child: DataTable(
          horizontalMargin: 24,
          columnSpacing: 24,
          headingRowColor: WidgetStateProperty.resolveWith(
            (states) => Theme.of(context).scaffoldBackgroundColor,
          ),
          columns: const [
            DataColumn(label: Text('Product')),
            DataColumn(label: Text('Units Sold'), numeric: true),
            DataColumn(label: Text('Revenue'), numeric: true),
            DataColumn(label: Text('Net Profit'), numeric: true),
            DataColumn(label: Text('Margin (%)'), numeric: true),
          ],
          rows: products.map((p) {
            final revenue = (p['total_revenue'] as num).toDouble();
            final profit = (p['total_profit'] as num).toDouble();
            final margin = revenue > 0 ? (profit / revenue) * 100 : 0.0;
            
            return DataRow(
              cells: [
                DataCell(Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w500))),
                DataCell(Text(p['total_qty'].toString())),
                DataCell(Text(curFormat.format(revenue))),
                DataCell(Text(curFormat.format(profit))),
                DataCell(Text('${margin.toStringAsFixed(1)}%')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
