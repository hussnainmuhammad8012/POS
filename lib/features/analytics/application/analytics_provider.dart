import 'package:flutter/material.dart';
import '../data/analytics_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/services/data_sync_service.dart';
import 'pdf_report_service.dart';

class AnalyticsKpi {
  final double totalRevenue;
  final double netProfit;
  final double totalCost;
  final double totalCreditToCollect;
  final double totalSupplierDues;
  final int transactions;
  final int lowStockItems;

  const AnalyticsKpi({
    required this.totalRevenue,
    required this.netProfit,
    required this.totalCost,
    required this.totalCreditToCollect,
    required this.totalSupplierDues,
    required this.transactions,
    required this.lowStockItems,
  });
}

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _analyticsRepository;
  final TransactionRepository _transactionRepository;
  final DataSyncService? _syncService;

  AnalyticsProvider({
    required AnalyticsRepository analyticsRepository,
    required TransactionRepository transactionRepository,
    DataSyncService? syncService,
  })  : _analyticsRepository = analyticsRepository,
        _transactionRepository = transactionRepository,
        _syncService = syncService,
        _pdfService = PdfReportService() {
    // Initial load
    refreshData();
    // Listen to mobile updates
    _syncService?.addListener(refreshData);
  }

  @override
  void dispose() {
    _syncService?.removeListener(refreshData);
    super.dispose();
  }

  final PdfReportService _pdfService;

  AnalyticsKpi _kpi = const AnalyticsKpi(
    totalRevenue: 0,
    netProfit: 0,
    totalCost: 0,
    totalCreditToCollect: 0,
    totalSupplierDues: 0,
    transactions: 0,
    lowStockItems: 0,
  );

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  List<Map<String, dynamic>> _salesByCategory = [];
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _leastProducts = [];
  List<Map<String, dynamic>> _topSuppliers = [];
  Map<String, double> _revenueTrend = {};
  bool _isLoading = false;

  AnalyticsKpi get kpi => _kpi;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  List<Map<String, dynamic>> get salesByCategory => _salesByCategory;
  List<Map<String, dynamic>> get topProducts => _topProducts;
  List<Map<String, dynamic>> get leastProducts => _leastProducts;
  List<Map<String, dynamic>> get topSuppliers => _topSuppliers;
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
      final now = DateTime.now();
      _endDate = now; // Update end of charts range to now
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // 1. KPIs for "Today" (Strict 24h range)
      final revenueToday = await _analyticsRepository.getTotalRevenue(todayStart, todayEnd);
      final costToday = await _analyticsRepository.getTotalCost(todayStart, todayEnd);
      final transactionsToday = await _transactionRepository.getTransactionsByDateRange(todayStart, todayEnd);
      final creditToday = await _analyticsRepository.getTodayCreditSales(); // Specifically today's credits
      
      // Global metrics that aren't time-bound or have their own logic
      final lowStock = await _analyticsRepository.getLowStockCount();
      final supplierDues = await _analyticsRepository.getTotalSupplierDues();

      _kpi = AnalyticsKpi(
        totalRevenue: revenueToday,
        totalCost: costToday,
        netProfit: revenueToday - costToday,
        totalCreditToCollect: creditToday, // Card says "Credit Today"
        totalSupplierDues: supplierDues,
        transactions: transactionsToday.length,
        lowStockItems: lowStock,
      );

      // 2. Historical Data (User-selected range, defaults to 30 days)
      _salesByCategory = await _analyticsRepository.getSalesByCategory(_startDate, _endDate);
      _topProducts = await _analyticsRepository.getTopPerformingProducts(limit: 10, start: _startDate, end: _endDate);
      _leastProducts = await _analyticsRepository.getLeastPerformingProducts(limit: 5);
      _topSuppliers = await _analyticsRepository.getTopSuppliers(limit: 5);
      _revenueTrend = await _analyticsRepository.getRevenueOverTime(_startDate, _endDate);

    } catch (e) {
      debugPrint('Error refreshing analytics: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> generateReport({
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
        totalSupplierDues: await _analyticsRepository.getTotalSupplierDues(),
        transactions: transactions.length,
        lowStockItems: lowStock,
      );

      final reportCategories = await _analyticsRepository.getSalesByCategory(start, end);
      final reportProducts = await _analyticsRepository.getTopPerformingProducts(limit: 50, start: start, end: end);

      return await _pdfService.generateAndSaveReport(
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
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

