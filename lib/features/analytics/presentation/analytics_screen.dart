import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  static const routeName = '/analytics';

  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _range = 'Today';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics & Reports',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          _buildRangeSelector(context),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildRangeKpiCard('Sales', '₹12,300', Icons.sell),
              const SizedBox(width: 12),
              _buildRangeKpiCard('Transactions', '87', Icons.receipt_long),
              const SizedBox(width: 12),
              _buildRangeKpiCard('Profit', '₹3,450', Icons.trending_up),
              const SizedBox(width: 12),
              _buildRangeKpiCard('Customers', '53', Icons.people),
            ],
          ),
          const SizedBox(height: 16),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Sales Overview'),
              Tab(text: 'Best & Worst Sellers'),
              Tab(text: 'Profit Analysis'),
              Tab(text: 'Customer Insights'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _SalesOverviewTab(),
                _BestWorstSellersTab(),
                _ProfitAnalysisTab(),
                _CustomerInsightsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(BuildContext context) {
    final ranges = [
      'Today',
      'Yesterday',
      'This Week',
      'This Month',
      'Last Month',
      'Custom Range',
    ];
    return Row(
      children: [
        Wrap(
          spacing: 8,
          children: ranges.map((r) {
            final selected = _range == r;
            return ChoiceChip(
              label: Text(r),
              selected: selected,
              onSelected: (_) async {
                if (r == 'Custom Range') {
                  // You would show a date range picker here.
                }
                setState(() => _range = r);
              },
            );
          }).toList(),
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {
            // Export logic goes here
          },
          icon: const Icon(Icons.download),
          label: const Text('Export to PDF/Excel'),
        ),
      ],
    );
  }

  Widget _buildRangeKpiCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesOverviewTab extends StatelessWidget {
  const _SalesOverviewTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.show_chart, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Sales Trend',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(show: false),
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: true),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            spots: [
                              FlSpot(0, 5),
                              FlSpot(1, 8),
                              FlSpot(2, 12),
                              FlSpot(3, 10),
                              FlSpot(4, 14),
                              FlSpot(5, 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.timelapse, color: AppColors.info),
                      SizedBox(width: 8),
                      Text(
                        'Sales by Hour',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(show: false),
                        gridData: FlGridData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 9, barRods: [
                            BarChartRodData(toY: 8),
                          ]),
                          BarChartGroupData(x: 10, barRods: [
                            BarChartRodData(toY: 12),
                          ]),
                          BarChartGroupData(x: 11, barRods: [
                            BarChartRodData(toY: 16),
                          ]),
                          BarChartGroupData(x: 12, barRods: [
                            BarChartRodData(toY: 10),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BestWorstSellersTab extends StatelessWidget {
  const _BestWorstSellersTab();

  @override
  Widget build(BuildContext context) {
    final best = [
      {'name': 'Bottled Water 1L', 'qty': 50},
      {'name': 'Chips Masala', 'qty': 40},
      {'name': 'Cold Drink 500ml', 'qty': 35},
    ];
    final worst = [
      {'name': 'Exotic Jam', 'qty': 1},
      {'name': 'Premium Cereal', 'qty': 2},
      {'name': 'Imported Sauce', 'qty': 3},
    ];

    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.trending_up, color: AppColors.success),
                      SizedBox(width: 8),
                      Text(
                        'Top 10 Products',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: best.length,
                      itemBuilder: (context, index) {
                        final item = best[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppColors.success.withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(item['name'] as String),
                          trailing: Text('x${item['qty']}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.trending_down, color: AppColors.error),
                      SizedBox(width: 8),
                      Text(
                        'Bottom 10 Products',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: worst.length,
                      itemBuilder: (context, index) {
                        final item = worst[index];
                        return ListTile(
                          leading: CircleAvatar(
                            radius: 14,
                            backgroundColor:
                                AppColors.error.withOpacity(0.1),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(item['name'] as String),
                          trailing: Text('x${item['qty']}'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfitAnalysisTab extends StatelessWidget {
  const _ProfitAnalysisTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: const [
            _ProfitSummaryCard(
              label: 'Gross Profit',
              value: '₹4,560',
            ),
            SizedBox(width: 12),
            _ProfitSummaryCard(
              label: 'Profit Margin',
              value: '28%',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profit by Category',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        titlesData: FlTitlesData(show: false),
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [
                            BarChartRodData(toY: 16),
                          ]),
                          BarChartGroupData(x: 1, barRods: [
                            BarChartRodData(toY: 12),
                          ]),
                          BarChartGroupData(x: 2, barRods: [
                            BarChartRodData(toY: 10),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Product Profitability',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Units Sold')),
                          DataColumn(label: Text('Revenue')),
                          DataColumn(label: Text('COGS')),
                          DataColumn(label: Text('Profit')),
                          DataColumn(label: Text('Margin')),
                        ],
                        rows: [
                          _profitRow('Bottled Water 1L', 50, 2500, 1500),
                          _profitRow('Chips Masala', 40, 1600, 900),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static DataRow _profitRow(
    String name,
    int units,
    double revenue,
    double cost,
  ) {
    final profit = revenue - cost;
    final margin = profit / revenue * 100;
    return DataRow(
      cells: [
        DataCell(Text(name)),
        DataCell(Text(units.toString())),
        DataCell(Text('₹${revenue.toStringAsFixed(0)}')),
        DataCell(Text('₹${cost.toStringAsFixed(0)}')),
        DataCell(Text('₹${profit.toStringAsFixed(0)}')),
        DataCell(Text('${margin.toStringAsFixed(1)}%')),
      ],
    );
  }
}

class _CustomerInsightsTab extends StatelessWidget {
  const _CustomerInsightsTab();

  @override
  Widget build(BuildContext context) {
    final topCustomers = [
      {'name': 'Rahul', 'spent': 3200.0},
      {'name': 'Sneha', 'spent': 2800.0},
      {'name': 'Amit', 'spent': 2100.0},
    ];

    return Column(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top 10 Customers by Spending',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: topCustomers.length,
                      itemBuilder: (context, index) {
                        final c = topCustomers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              (c['name'] as String)
                                  .substring(0, 1)
                                  .toUpperCase(),
                            ),
                          ),
                          title: Text(c['name'] as String),
                          trailing: Text(
                            '₹${(c['spent'] as double).toStringAsFixed(0)}',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Count Over Time',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        titlesData: FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 4),
                              FlSpot(1, 6),
                              FlSpot(2, 5),
                              FlSpot(3, 7),
                              FlSpot(4, 9),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfitSummaryCard extends StatelessWidget {
  final String label;
  final String value;

  const _ProfitSummaryCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

