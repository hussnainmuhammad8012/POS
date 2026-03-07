import 'package:flutter/material.dart';
import '../data/analytics_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import 'pdf_report_service.dart';

class AnalyticsKpi {
  final double totalRevenue;
  final double netProfit;
  final double totalCost;
  final double totalCreditToCollect;
  final int transactions;
  final int lowStockItems;

  const AnalyticsKpi({
    required this.totalRevenue,
    required this.netProfit,
    required this.totalCost,
    required this.totalCreditToCollect,
    required this.transactions,
    required this.lowStockItems,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _analyticsRepository;
  final TransactionRepository _transactionRepository;

  AnalyticsProvider({
    required AnalyticsRepository analyticsRepository,
    required TransactionRepository transactionRepository,
  })  : _analyticsRepository = analyticsRepository,
        _transactionRepository = transactionRepository,
        _pdfService = PdfReportService() {
    // Initial load
    refreshData();
  }

  final PdfReportService _pdfService;

  AnalyticsKpi _kpi = const AnalyticsKpi(
    totalRevenue: 0,
    netProfit: 0,
    totalCost: 0,
    totalCreditToCollect: 0,
    transactions: 0,
    lowStockItems: 0,
  );

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<Map<String, dynamic>> _salesByCategory = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _leastProducts = [];
  Map<String, double> _revenueTrend = {};
  bool _isLoading = false;

  AnalyticsKpi get kpi => _kpi;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  List<Map<String, dynamic>> get salesByCategory => _salesByCategory;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get leastProducts => _leastProducts;
  Map<String, double> get revenueTrend => _revenueTrend;
  bool get isLoading => _isLoading;

  void setDateRange(DateTime start, DateTime end) {
    _startDate = start;
    _endDate = end;
    refreshData();
  }

  Future<void> refreshData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final revenue = await _analyticsRepository.getTotalRevenue(_startDate, _endDate);
      final cost = await _analyticsRepository.getTotalCost(_startDate, _endDate);
      final credit = await _analyticsRepository.getTotalCreditToCollect();
      final lowStock = await _analyticsRepository.getLowStockCount();
      final transactions = await _transactionRepository.getTransactionsByDateRange(_startDate, _endDate);

      _kpi = AnalyticsKpi(
        totalRevenue: revenue,
        totalCost: cost,
        netProfit: revenue - cost,
        totalCreditToCollect: credit,
        transactions: transactions.length,
        lowStockItems: lowStock,
      );

      _salesByCategory = await _analyticsRepository.getSalesByCategory(_startDate, _endDate);
      _topProducts = await _analyticsRepository.getTopPerformingProducts(limit: 10, start: _startDate, end: _endDate);
      _leastProducts = await _analyticsRepository.getLeastPerformingProducts(limit: 5);
      _revenueTrend = await _analyticsRepository.getRevenueOverTime(_startDate, _endDate);

    } catch (e) {
      debugPrint('Error refreshing analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateReport({
    required String storeName,
    required String storeAddress,
    required DateTime start,
    required DateTime end,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Fetch specific data for the report range if it differs from current view
      final revenue = await _analyticsRepository.getTotalRevenue(start, end);
      final cost = await _analyticsRepository.getTotalCost(start, end);
      final credit = await _analyticsRepository.getTotalCreditToCollect();
      final lowStock = await _analyticsRepository.getLowStockCount();
      final transactions = await _transactionRepository.getTransactionsByDateRange(start, end);

      final reportKpi = AnalyticsKpi(
        totalRevenue: revenue,
        totalCost: cost,
        netProfit: revenue - cost,
        totalCreditToCollect: credit,
        transactions: transactions.length,
        lowStockItems: lowStock,
      );

      final reportCategories = await _analyticsRepository.getSalesByCategory(start, end);
      final reportProducts = await _analyticsRepository.getTopPerformingProducts(limit: 50, start: start, end: end);

      await _pdfService.generateAndSaveReport(
        storeName: storeName,
        storeAddress: storeAddress,
        start: start,
        end: end,
        kpi: reportKpi,
        topProducts: reportProducts,
        topCategories: reportCategories,
      );
    } catch (e) {
      debugPrint('Error generating report: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

