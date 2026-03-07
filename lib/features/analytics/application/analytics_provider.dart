import 'package:flutter/material.dart';
import '../data/analytics_repository.dart';
import '../../../core/repositories/transaction_repository.dart';

class DailyKpi {
  final double sales;
  final int transactions;
  final double credit;
  final int lowStockItems;
  final bool salesUpVsYesterday;

  const DailyKpi({
    required this.sales,
    required this.transactions,
    required this.credit,
    required this.lowStockItems,
    required this.salesUpVsYesterday,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _analyticsRepository;
  final TransactionRepository _transactionRepository;

  AnalyticsProvider({
    required AnalyticsRepository analyticsRepository,
    required TransactionRepository transactionRepository,
  })  : _analyticsRepository = analyticsRepository,
        _transactionRepository = transactionRepository;

  DailyKpi _todayKpi = const DailyKpi(
    sales: 0,
    transactions: 0,
    credit: 0,
    lowStockItems: 0,
    salesUpVsYesterday: false,
  );

  List<double> _last7DaysSales = [];
  List<Map<String, dynamic>> _todaySalesByCategory = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _leastProducts = [];
  bool _isLoading = false;

  DailyKpi get todayKpi => _todayKpi;
  List<double> get last7DaysSales => _last7DaysSales;
  List<Map<String, dynamic>> get todaySalesByCategory => _todaySalesByCategory;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get leastProducts => _leastProducts;
  bool get isLoading => _isLoading;

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch data using repository methods
      final credit = await _analyticsRepository.getTodayCreditSales();
      final lowStock = await _analyticsRepository.getLowStockCount();
      
      // Get sales and transactions from TransactionRepository
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      
      final sales = await _transactionRepository.getSalesTotalForDateRange(start, end);
      final transactions = await _transactionRepository.getTransactionsByDateRange(start, end);

      _todayKpi = DailyKpi(
        sales: sales,
        transactions: transactions.length,
        credit: credit,
        lowStockItems: lowStock,
        salesUpVsYesterday: false, // Added to maintain syntactic correctness with DailyKpi definition
      );

      // Fetch other analytics
      _todaySalesByCategory = await _analyticsRepository.getTodaySalesByCategory();
      _topProducts = await _analyticsRepository.getTopPerformingProducts();
      _leastProducts = await _analyticsRepository.getLeastPerformingProducts();

      // Fetch sales trend (last 7 days)
      final trendData = await _transactionRepository.getDailySalesForLastNDays(7);
      _last7DaysSales = trendData.values.toList();

    } catch (e) {
      debugPrint('Error refreshing analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

