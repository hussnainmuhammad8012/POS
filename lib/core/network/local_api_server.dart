import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import '../../features/inventory/data/repositories/product_repository.dart';
import '../../features/inventory/data/repositories/category_repository.dart';
import '../../features/inventory/data/repositories/carton_repository.dart';
import '../../features/analytics/data/analytics_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/entities.dart';
import '../../features/settings/application/settings_provider.dart';
import '../repositories/supplier_repository.dart';
import '../services/fcm_service.dart';
import '../services/data_sync_service.dart';

/// Local HTTP server for Companion App
/// Runs on background isolate (handled via app initialization)
class LocalApiServer {
  static final LocalApiServer _instance = LocalApiServer._internal();
  factory LocalApiServer() => _instance;
  LocalApiServer._internal();

  HttpServer? _server;
  String? _sessionKey;
  DateTime? _sessionExpiry;
  int _sessionDurationHours = 24;
  
  ProductRepository? _productRepository;
  CategoryRepository? _categoryRepository;
  CartonRepository? _cartonRepository;
  SupplierRepository? _supplierRepository;
  AnalyticsRepository? _analyticsRepository;
  TransactionRepository? _transactionRepository;
  SettingsProvider? _settingsProvider;
  FCMService? _fcmService;
  DataSyncService? _dataSyncService;
  String? _localIp;
  List<String> _localIps = [];

  // Server state
  bool get isRunning => _server != null;
  String? get baseUrl => (_server != null && _localIp != null) 
    ? 'http://$_localIp:${_server!.port}' 
    : null;

  void setServices({
    required ProductRepository productRepository,
    required CategoryRepository categoryRepository,
    required CartonRepository cartonRepository,
    required SupplierRepository supplierRepository,
    required AnalyticsRepository analyticsRepository,
    required TransactionRepository transactionRepository,
    required SettingsProvider settingsProvider,
    required FCMService fcmService,
    required DataSyncService dataSyncService,
  }) {
    _productRepository = productRepository;
    _categoryRepository = categoryRepository;
    _cartonRepository = cartonRepository;
    _supplierRepository = supplierRepository;
    _analyticsRepository = analyticsRepository;
    _transactionRepository = transactionRepository;
    _settingsProvider = settingsProvider;
    _fcmService = fcmService;
    _dataSyncService = dataSyncService;
  }

  /// Start server on available port (default 8080)
  Future<void> start({int preferredPort = 8080}) async {
    if (_server != null) return;
    
    final router = _setupRoutes();
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(_corsMiddleware())
        .addMiddleware(_authMiddleware())
        .addHandler(router.call);
    
    try {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, preferredPort, shared: true);
      print('[SERVER] Listening on http://${_server!.address.address}:${_server!.port}');
    } catch (e) {
      _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, 0, shared: true);
      print('[SERVER] Bound to random port: ${_server!.port}');
    }
    
    await _discoverLocalIps();
    _generateSessionKey();
    print('[SERVER] Discovered IPs: $_localIps');
    print('[SERVER] Local Server started at: $_localIp:${_server!.port}');
  }

  Future<void> _discoverLocalIps() async {
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.IPv4,
      );
      
      _localIps.clear();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!_localIps.contains(addr.address)) {
            _localIps.add(addr.address);
          }
        }
      }

      if (_localIps.isNotEmpty) {
        _localIp = _localIps.first;
      } else {
        _localIp = '127.0.0.1';
        _localIps = ['127.0.0.1'];
      }
    } catch (e) {
      _localIp = '127.0.0.1';
      _localIps = ['127.0.0.1'];
    }
  }
  
  void stop() {
    _server?.close();
    _server = null;
    _sessionKey = null;
  }
  
  void _generateSessionKey() {
    _sessionKey = '${DateTime.now().millisecondsSinceEpoch}_${_randomString(16)}';
    _sessionExpiry = DateTime.now().add(Duration(hours: _sessionDurationHours));
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))
    ));
  }
  
  /// QR Code data for pairing
  String getQrData() {
    if (_server == null || _localIp == null) return '';
    return jsonEncode({
      'ip': _localIp,
      'ips': _localIps,
      'port': _server!.port,
      'session_key': _sessionKey,
      'expiry': _sessionExpiry?.toIso8601String(),
      'version': '1.0',
    });
  }
  
  void updateSessionDuration(int hours) {
    _sessionDurationHours = hours;
    if (_sessionKey != null) {
      _sessionExpiry = DateTime.now().add(Duration(hours: hours));
    }
  }
  
  Router _setupRoutes() {
    final router = Router();
    
    router.get('/ping', (Request request) {
      final remoteIp = (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address;
      print('[SERVER] Incoming PING from $remoteIp');
      return Response.ok(jsonEncode({
        'status': 'ok', 
        'timestamp': DateTime.now().toIso8601String(),
        'appName': _settingsProvider?.storeName ?? 'Gravity POS'
      }));
    });
    
    // AUTH ROUTES
    router.post('/auth/login', _login);
    
    // INVENTORY ROUTES
    router.get('/inventory/products', _getProducts);
    router.post('/inventory/products', _createProduct);
    router.post('/inventory/stock-update', _updateStock);
    router.post('/inventory/receive-carton', _receiveCarton);
    router.get('/inventory/categories', _getCategories);
    router.get('/inventory/suppliers', _getSuppliers);
    router.post('/inventory/suppliers', _createSupplier);
    
    // ANALYTICS ROUTES
    router.get('/analytics/summary', _getAnalyticsSummary);
    
    // SYNC/REPORT ROUTES
    router.post('/reports/on-demand', _triggerOnDemandReport);
    
    return router;
  }
  
  Middleware _authMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        final remoteIp = (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address;
        
        if (request.url.path == 'ping' || request.url.path == 'auth/login') {
          return innerHandler(request);
        }
        
        final authHeader = request.headers['Authorization'];
        if (authHeader == null || !authHeader.startsWith('Bearer ')) {
          print('[SERVER] Auth Failed: Missing header from $remoteIp');
          return Response(401, body: jsonEncode({'error': 'Missing auth'}));
        }
        
        final token = authHeader.substring(7);
        if (token != _sessionKey) {
          print('[SERVER] Auth Failed: Invalid Token from $remoteIp. Expected: $_sessionKey, Got: $token');
          return Response(403, body: jsonEncode({'error': 'Invalid session'}));
        }
        
        if (_sessionExpiry != null && DateTime.now().isAfter(_sessionExpiry!)) {
          print('[SERVER] Auth Failed: Session Expired for $remoteIp');
          return Response(403, body: jsonEncode({'error': 'Session expired'}));
        }
        
        return innerHandler(request);
      };
    };
  }
  
  Middleware _corsMiddleware() {
    return createMiddleware(
      requestHandler: (Request request) {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders);
        }
        return null;
      },
      responseHandler: (Response response) {
        return response.change(headers: _corsHeaders);
      },
    );
  }
  
  final _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };

  // HANDLERS
  
  Future<Response> _getProducts(Request request) async {
    if (_productRepository == null) return Response.internalServerError();
    final products = await _productRepository!.getAllProductSummaries();
    // Simplified JSON mapping
    final list = products.map((s) => {
      'id': s.product.id,
      'category_id': s.product.categoryId,
      'name': s.product.name,
      'description': s.product.description,
      'base_sku': s.product.baseSku,
      'main_image_path': s.product.mainImagePath,
      'unit_type': s.product.unitType,
      'is_active': s.product.isActive ? 1 : 0,
      'created_at': s.product.createdAt.toIso8601String(),
      'updated_at': s.product.updatedAt.toIso8601String(),
      'current_stock': s.totalStock,
      'price': s.minPrice,
    }).toList();
    return Response.ok(jsonEncode(list));
  }

  Future<Response> _createProduct(Request request) async {
    if (_productRepository == null) return Response.internalServerError();
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    try {
      // 1. Create Product
      final productId = await _productRepository!.createProductWithDefaultVariant(
        categoryId: data['categoryId'],
        name: data['name'],
        baseSku: data['baseSku'],
        description: data['description'],
        unitType: data['unitType'] ?? 'Pieces',
        supplierId: data['supplierId'],
        barcode: (data['barcode']?.toString().isEmpty ?? true) ? null : data['barcode'],
        costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
        retailPrice: (data['retailPrice'] as num?)?.toDouble() ?? 0.0,
        wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble(),
        mrp: (data['mrp'] as num?)?.toDouble(),
        initialStock: (data['initialStock'] as num?)?.toInt() ?? 0,
        lowStockThreshold: (data['lowStockThreshold'] as num?)?.toInt() ?? 10,
      );
      
      // 3. Notify Sync
      _dataSyncService?.notifyMobileUpdate();
      
      return Response.ok(jsonEncode({'id': productId, 'status': 'success'}));
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return Response(400, body: jsonEncode({
          'error': 'Duplicate Entry',
          'message': 'A product with this SKU or Barcode already exists. Please use a unique SKU and Barcode.'
        }));
      }
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _getCategories(Request request) async {
    if (_categoryRepository == null) return Response.internalServerError();
    final categories = await _categoryRepository!.getAllCategories();
    return Response.ok(jsonEncode(categories));
  }

  Future<Response> _getSuppliers(Request request) async {
    if (_supplierRepository == null) return Response.internalServerError();
    final suppliers = await _supplierRepository!.getAll();
    final list = suppliers.map((s) => {
      'id': s.id,
      'name': s.name,
      'contactPerson': s.contactPerson,
    }).toList();
    return Response.ok(jsonEncode(list));
  }

  Future<Response> _createSupplier(Request request) async {
    if (_supplierRepository == null) return Response.internalServerError();
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    try {
      await _supplierRepository!.insert(Supplier(
        name: data['name'],
        contactPerson: data['contactPerson'],
        phone: data['phone'],
        email: data['email'],
        address: data['address'],
        createdAt: DateTime.now(),
      ));
      
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _login(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final username = data['username'];
    final remoteIp = (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address;

    print('[SERVER] Login attempt for user: $username from IP: $remoteIp');
    // Simple admin check for local POS
    final password = data['password'];
    
    if (username == 'admin' && (password == 'admin' || password == 'admin123')) {
      // Save FCM Token if provided (for Admin Dashboard mode)
      final fcmToken = data['fcmToken'];
      if (fcmToken != null && _settingsProvider != null) {
        _settingsProvider!.setAdminFcmToken(fcmToken);
        print('LocalServer: Registered Admin FCM Token: $fcmToken');
      }

      return Response.ok(jsonEncode({
        'status': 'success',
        'message': 'Logged in successfully',
        'token': _sessionKey, // Return same key for simplicity
      }));
    }
    
    return Response(401, body: jsonEncode({'error': 'Invalid credentials'}));
  }

  Future<Response> _updateStock(Request request) async {
    if (_productRepository == null) return Response.internalServerError();
    
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    try {
      await _productRepository!.updateStock(
        productId: data['product_id'],
        quantityChange: data['quantity_change'],
        reason: data['reason'] ?? 'Companion App Update',
      );
      
      // 3. Notify Sync
      _dataSyncService?.notifyMobileUpdate();
      
      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _receiveCarton(Request request) async {
    if (_cartonRepository == null || _productRepository == null) {
      return Response.internalServerError();
    }

    final body = await request.readAsString();
    final data = jsonDecode(body);

    try {
      final productId = data['product_id'];
      final quantity = data['quantity'] as int;
      final totalCost = (data['total_cost'] as num).toDouble();
      final paidAmount = (data['paid_amount'] as num).toDouble();
      final supplierId = data['supplier_id'] as String?;
      final notes = data['notes'] as String?;
      final dueDateStr = data['due_date'] as String?;
      final dueDate = dueDateStr != null ? DateTime.parse(dueDateStr) : null;

      // 1. Get primary variant
      final variantId = await _productRepository!.getPrimaryVariantId(productId);
      if (variantId == null) {
        return Response.badRequest(body: jsonEncode({'error': 'Product variant not found'}));
      }

      // 2. Receive Carton
      final costPerPiece = quantity > 0 ? (totalCost / quantity) : 0.0;
      final cartonId = await _cartonRepository!.receiveCarton(
        productVariantId: variantId,
        cartonNumber: 'CTN-${DateTime.now().millisecondsSinceEpoch}',
        piecesPerCarton: quantity,
        costPerPiece: costPerPiece,
        receivedQuantity: quantity,
        supplierId: supplierId,
        notes: notes?.isNotEmpty == true ? notes : 'Purchased from Companion App',
      );

      // 3. Update Supplier Ledger if enabled
      if (supplierId != null && _settingsProvider?.isSupplierLedgerEnabled == true && _supplierRepository != null) {
        await _supplierRepository!.addLedgerEntry(SupplierLedger(
          id: 'pur_${DateTime.now().millisecondsSinceEpoch}',
          supplierId: supplierId,
          referenceId: cartonId,
          type: 'PURCHASE',
          amount: totalCost,
          dueDate: dueDate,
          notes: 'Carton $cartonId (Mobile)',
          createdAt: DateTime.now(),
        ));

        if (paidAmount > 0) {
          await _supplierRepository!.addLedgerEntry(SupplierLedger(
            id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
            supplierId: supplierId,
            referenceId: cartonId,
            type: 'PAYMENT',
            amount: paidAmount,
            notes: 'Payment for Carton $cartonId (Mobile)',
            createdAt: DateTime.now(),
          ));
        }
      }

      // 4. Notify Sync
      _dataSyncService?.notifyMobileUpdate();

      return Response.ok(jsonEncode({'status': 'success', 'carton_id': cartonId}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _getAnalyticsSummary(Request request) async {
    if (_analyticsRepository == null || _transactionRepository == null) {
      return Response.internalServerError();
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    try {
      final todaySales = await _analyticsRepository!.getTotalRevenue(todayStart, todayEnd);
      final todayCreditSales = await _analyticsRepository!.getTodayCreditSales();
      final activeCredits = await _analyticsRepository!.getTotalCreditToCollect();
      final supplyStats = await _analyticsRepository!.getTodaySupplyStats();
      
      // Get yesterday's summary for the "Recent Alert"
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final yesterdayEnd = todayStart;
      final yesterdaySales = await _analyticsRepository!.getTotalRevenue(yesterdayStart, yesterdayEnd);
      final yesterdayCost = await _analyticsRepository!.getTotalCost(yesterdayStart, yesterdayEnd);

      return Response.ok(jsonEncode({
        'today_sales': todaySales,
        'today_credit_sales': todayCreditSales,
        'active_credits': activeCredits,
        'supply_stats': supplyStats,
        'yesterday_report': {
          'total_sales': yesterdaySales,
          'profit': yesterdaySales - yesterdayCost,
          'timestamp': yesterdayStart.toIso8601String(),
        }
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _triggerOnDemandReport(Request request) async {
    if (_fcmService == null) return Response.internalServerError();
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final token = data['fcmToken'];
    
    if (token != null) {
      await _fcmService!.sendOnDemandReport(token);
      return Response.ok(jsonEncode({'status': 'sent'}));
    }
    return Response.badRequest(body: 'Missing fcmToken');
  }
}
