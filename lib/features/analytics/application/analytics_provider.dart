import 'package:flutter/material.dart';

class DailyKpi {
  final double sales;
  final int transactions;
  final int activeCustomers;
  final int lowStockItems;
  final double profit;
  final bool salesUpVsYesterday;

  const DailyKpi({
    required this.sales,
    required this.transactions,
    required this.activeCustomers,
    required this.lowStockItems,
    required this.profit,
    required this.salesUpVsYesterday,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  DailyKpi _todayKpi = const DailyKpi(
    sales: 0,
    transactions: 0,
    activeCustomers: 0,
    lowStockItems: 0,
    profit: 0,
    salesUpVsYesterday: false,
  );

  DailyKpi get todayKpi => _todayKpi;

  // Placeholder data for charts; a production implementation would compute
  // these from the database with SQL aggregations.
  List<double> get last7DaysSales => [120, 80, 150, 200, 170, 210, 260];

  List<Map<String, Object>> get todaySalesByCategory => [
        {'label': 'Beverages', 'value': 40.0},
        {'label': 'Snacks', 'value': 35.0},
        {'label': 'Household', 'value': 25.0},
      ];

  void updateTodayKpi(DailyKpi kpi) {
    _todayKpi = kpi;
    notifyListeners();
  }
}

