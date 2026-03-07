import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/glass_header.dart';
import '../../analytics/application/analytics_provider.dart';
import '../../transactions/application/transactions_provider.dart';

class DashboardScreen extends StatelessWidget {
  static const routeName = '/dashboard';

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final kpi = analytics.todayKpi;

    if (analytics.last7DaysSales.isEmpty && !analytics.isLoading) {
      Future.microtask(() => analytics.refreshData());
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassHeader(
            title: 'Overview',
            subtitle: 'Real-time store metrics and performance',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                _buildKpiRow(context, kpi),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _SalesTrendCard(analytics: analytics),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: _SalesByCategoryTodayCard(analytics: analytics),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _ProductRankingCard(
                        title: 'Top 5 Performing Products',
                        items: analytics.topProducts,
                        isTop: true,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _ProductRankingCard(
                        title: 'Least Performing Products',
                        items: analytics.leastProducts,
                        isTop: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _RecentTransactionsCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, DailyKpi kpi) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isStarAdmin = theme.primaryColor == AppColors.STAR_PRIMARY;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: KpiCard(
              title: 'Sales Today',
              value: 'Rs ${kpi.sales.toStringAsFixed(0)}',
              icon: LucideIcons.indianRupee,
              trend: '+5.2%',
              isTrendPositive: true,
              isPrimary: isStarAdmin || !isDark, 
              accentColor: isStarAdmin ? AppColors.STAR_PRIMARY : (isDark ? AppColors.PRIMARY_ACCENT_DARK : AppColors.PRIMARY_ACCENT_LIGHT),
              softBackground: isDark ? null : (isStarAdmin ? AppColors.STAR_PRIMARY.withAlpha(20) : AppColors.LIGHT_PRIMARY_SOFT),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: KpiCard(
              title: 'Transactions',
              value: kpi.transactions.toString(),
              icon: LucideIcons.receipt,
              trend: '+8%',
              accentColor: isStarAdmin ? AppColors.STAR_BLUE : (isDark ? AppColors.INFO_DARK : AppColors.INFO),
              softBackground: isDark ? null : (isStarAdmin ? AppColors.STAR_BLUE.withAlpha(20) : AppColors.LIGHT_INFO_SOFT),
              isTrendPositive: true,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: KpiCard(
              title: 'Credit Today',
              value: 'Rs ${kpi.credit.toStringAsFixed(0)}',
              icon: LucideIcons.creditCard,
              trend: '+2.1%',
              accentColor: isStarAdmin ? AppColors.STAR_TEAL : (isDark ? AppColors.SUCCESS_DARK : AppColors.SUCCESS),
              softBackground: isDark ? null : (isStarAdmin ? AppColors.STAR_TEAL.withAlpha(20) : AppColors.LIGHT_SUCCESS_SOFT),
              isTrendPositive: false,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: KpiCard(
              title: 'Low Stock',
              value: kpi.lowStockItems.toString(),
              icon: LucideIcons.packageMinus,
              accentColor: isStarAdmin ? AppColors.STAR_YELLOW : (isDark ? AppColors.WARNING_DARK : AppColors.WARNING),
              softBackground: isDark ? null : (isStarAdmin ? AppColors.STAR_YELLOW.withAlpha(20) : AppColors.LIGHT_WARNING_SOFT),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesTrendCard extends StatelessWidget {
  final AnalyticsProvider analytics;

  const _SalesTrendCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = analytics.last7DaysSales;
    final primaryColor = Theme.of(context).primaryColor;

    return ModernCard(
      title: 'Sales Trend',
      padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5000,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                  strokeWidth: 1,
                  dashArray: [4, 4],
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${(value / 1000).toStringAsFixed(0)}k',
                      style: Theme.of(context).textTheme.bodySmall,
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: primaryColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: primaryColor.withValues(alpha: 0.05),
                ),
                spots: [
                  for (var i = 0; i < data.length; i++)
                    FlSpot(i.toDouble(), data[i]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesByCategoryTodayCard extends StatelessWidget {
  final AnalyticsProvider analytics;

  const _SalesByCategoryTodayCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final data = analytics.todaySalesByCategory;
    final total = data.fold<double>(0, (sum, e) => sum + (e['value'] as double));

    return ModernCard(
      title: 'Sales by Category',
      child: data.isEmpty || total == 0
          ? const SizedBox(
              height: 300,
              child: _EmptyState(
                icon: LucideIcons.pieChart,
                message: 'No sales today.',
              ),
            )
          : SizedBox(
              height: 300,
              child: Column(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 50,
                        sections: [
                          for (var i = 0; i < data.length; i++)
                            PieChartSectionData(
                              color: _getChartColor(context, i),
                              value: data[i]['value'] as double,
                              title: '',
                              radius: 40,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    flex: 4,
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final color = _getChartColor(context, index);
                        final percent = ((item['value'] as double) / total * 100).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item['label'] as String,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
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
    );
  }

  Color _getChartColor(BuildContext context, int index) {
    final theme = Theme.of(context);
    final isStarAdmin = theme.primaryColor == AppColors.STAR_PRIMARY;

    if (isStarAdmin) {
      final colors = [AppColors.STAR_PRIMARY, AppColors.STAR_BLUE, AppColors.STAR_TEAL, AppColors.STAR_YELLOW];
      return colors[index % colors.length];
    }

    final colors = [AppColors.primary, AppColors.success, AppColors.info, AppColors.warning, AppColors.danger];
    return colors[index % colors.length];
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard();

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionsProvider>().transactions.take(5).toList();

    return ModernCard(
      title: 'Recent Transactions',
      padding: EdgeInsets.zero,
      child: transactions.isEmpty 
      ? const SizedBox(height: 100, child: Center(child: Text('No transactions yet.')))
      : ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final item = transactions[index];
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              child: const Icon(LucideIcons.receipt, size: 18),
            ),
            title: Text(
              item.customerName ?? 'Walk-in',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(item.invoiceNumber),
            trailing: Text(
              'Rs ${item.finalAmount.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
      ),
    );
  }
}

class _ProductRankingCard extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> items;
  final bool isTop;

  const _ProductRankingCard({
    required this.title,
    required this.items,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      title: title,
      padding: EdgeInsets.zero,
      child: items.isEmpty
          ? const SizedBox(height: 100, child: Center(child: Text('No data available')))
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isTop ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(item['name'] as String),
                  trailing: Text(
                    '${item['total_qty']} units',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
      ),
    );
  }
}
