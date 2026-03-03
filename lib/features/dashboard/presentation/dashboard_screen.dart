import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../analytics/application/analytics_provider.dart';

class DashboardScreen extends StatelessWidget {
  static const routeName = '/';

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final analytics = context.watch<AnalyticsProvider>();
    final kpi = analytics.todayKpi;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _buildKpiRow(context, kpi),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _SalesTrendCard(analytics: analytics),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _SalesByCategoryTodayCard(analytics: analytics),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: _TopProductsCard(),
                ),
                SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _RecentTransactionsCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, DailyKpi kpi) {
    final salesSubtitle =
        kpi.salesUpVsYesterday ? 'Up vs yesterday' : 'Down vs yesterday';
    final salesIcon = kpi.salesUpVsYesterday
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final salesColor =
        kpi.salesUpVsYesterday ? AppColors.success : AppColors.error;

    return SizedBox(
      height: 110,
      child: Row(
        children: [
          Expanded(
            child: KpiCard(
              title: 'Today\'s Sales',
              value: '₹${kpi.sales.toStringAsFixed(2)}',
              icon: salesIcon,
              accentColor: salesColor,
              subtitle: salesSubtitle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KpiCard(
              title: 'Today\'s Transactions',
              value: kpi.transactions.toString(),
              icon: Icons.receipt_long,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KpiCard(
              title: 'Active Customers',
              value: kpi.activeCustomers.toString(),
              icon: Icons.people_alt,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KpiCard(
              title: 'Low Stock Items',
              value: kpi.lowStockItems.toString(),
              icon: Icons.warning_amber_rounded,
              accentColor: kpi.lowStockItems > 0
                  ? AppColors.warning
                  : AppColors.primaryTeal,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KpiCard(
              title: 'Today\'s Profit',
              value: '₹${kpi.profit.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              accentColor: AppColors.success,
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
    final data = analytics.last7DaysSales;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.show_chart, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  'Sales Trend (Last 7 Days)',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(
                    border: const Border(
                      left: BorderSide(color: Color(0xFFCFD8DC)),
                      bottom: BorderSide(color: Color(0xFFCFD8DC)),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: AppColors.primary,
                      spots: [
                        for (var i = 0; i < data.length; i++)
                          FlSpot(i.toDouble(), data[i]),
                      ],
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
    final total =
        data.fold<double>(0, (sum, e) => sum + (e['value'] as double));

    if (data.isEmpty || total == 0) {
      return const _EmptyState(
        icon: Icons.pie_chart_outline,
        message: 'No sales yet today.\nScan your first item to get started!',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: AppColors.primaryTeal),
                const SizedBox(width: 8),
                Text(
                  'Sales by Category Today',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: [
                          for (var i = 0; i < data.length; i++)
                            PieChartSectionData(
                              color: Colors.primaries[i %
                                  Colors.primaries.length],
                              value: data[i]['value'] as double,
                              title: '',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        final color = Colors.primaries[index %
                            Colors.primaries.length];
                        final percent =
                            ((item['value'] as double) / total * 100)
                                .toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item['label'] as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
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
          ],
        ),
      ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard();

  @override
  Widget build(BuildContext context) {
    // In a full implementation this would be populated from analytics queries.
    final mock = [
      {'name': 'Bottled Water 1L', 'qty': 42},
      {'name': 'Chips - Masala', 'qty': 30},
      {'name': 'Bread (Whole Wheat)', 'qty': 24},
      {'name': 'Cold Drink 500ml', 'qty': 20},
      {'name': 'Detergent 1kg', 'qty': 18},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star_border, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Top 5 Best Selling Products (This Week)',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: mock.length,
                itemBuilder: (context, index) {
                  final item = mock[index];
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        child: Text(
                          item['name']!.toString().substring(0, 1),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['name'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'x${item['qty']}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard();

  @override
  Widget build(BuildContext context) {
    // In a production implementation this would consume TransactionRepository.
    final mock = [
      {'time': '10:02 AM', 'customer': 'Walk-in', 'amount': '₹250.00'},
      {'time': '09:47 AM', 'customer': 'Rahul', 'amount': '₹120.00'},
      {'time': '09:30 AM', 'customer': 'Sneha', 'amount': '₹540.00'},
      {'time': '09:15 AM', 'customer': 'Walk-in', 'amount': '₹90.00'},
      {'time': '09:05 AM', 'customer': 'Amit', 'amount': '₹310.00'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: AppColors.info),
                const SizedBox(width: 8),
                Text(
                  'Recent Transactions',
                  style:
                      Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: mock.length,
                itemBuilder: (context, index) {
                  final item = mock[index];
                  return Row(
                    children: [
                      Icon(Icons.receipt, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['customer'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              item['time'] as String,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        item['amount'] as String,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 12),
              ),
            ),
          ],
        ),
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
          Icon(icon, size: 40, color: AppColors.textSecondary),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

