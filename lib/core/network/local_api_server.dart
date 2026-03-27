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
import '../../features/inventory/data/repositories/stock_movement_repository.dart';
import '../../features/analytics/data/analytics_repository.dart';
import '../repositories/transaction_repository.dart';
import '../models/entities.dart';
import '../repositories/customer_repository.dart';
import '../../features/inventory/data/models/product_unit_model.dart';
import '../../features/inventory/data/models/product_model.dart';
import '../../features/settings/application/settings_provider.dart';
import '../repositories/supplier_repository.dart';
import '../services/fcm_service.dart';
import '../services/data_sync_service.dart';
import '../../features/auth/application/auth_service.dart';
import '../../core/models/auth_models.dart';
import '../../features/auth/application/auth_provider.dart' as desktop_auth;

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
  CustomerRepository? _customersRepository;
  StockMovementRepository? _stockMovementRepository;
  SettingsProvider? _settingsProvider;
  String? _activePosCompanionId;
  FCMService? _fcmService;
  DataSyncService? _dataSyncService;
  AuthService? _authService;
  desktop_auth.AuthProvider? _desktopAuthProvider;
  String? _localIp;
  List<String> _localIps = [];
  
  // Callbacks
  Function(Transaction tx, List<TransactionItem> items)? _onRemoteCheckout;
  Function(Map<String, dynamic> printData)? _onRemotePrint;

  // In-memory print job queue
  final List<Map<String, dynamic>> _printQueue = [];
  bool _isPrinting = false;

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
    required CustomerRepository customersRepository,
    required SettingsProvider settingsProvider,
    required FCMService fcmService,
    required DataSyncService dataSyncService,
    StockMovementRepository? stockMovementRepository,
    AuthService? authService,
    desktop_auth.AuthProvider? desktopAuthProvider,
  }) {
    _productRepository = productRepository;
    _categoryRepository = categoryRepository;
    _cartonRepository = cartonRepository;
    _supplierRepository = supplierRepository;
    _analyticsRepository = analyticsRepository;
    _transactionRepository = transactionRepository;
    _customersRepository = customersRepository;
    _stockMovementRepository = stockMovementRepository;
    _settingsProvider = settingsProvider;
    _fcmService = fcmService;
    _dataSyncService = dataSyncService;
    _authService = authService ?? AuthService();
    _desktopAuthProvider = desktopAuthProvider;
  }
  
  void setCallbacks({
    required Function(Transaction tx, List<TransactionItem> items) onRemoteCheckout,
    required Function(Map<String, dynamic> printData) onRemotePrint,
  }) {
    _onRemoteCheckout = onRemoteCheckout;
    _onRemotePrint = onRemotePrint;
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
        'appName': _settingsProvider?.storeName ?? 'Gravity POS',
        'storeLogo': _settingsProvider?.storeLogo ?? '',
        'isUomEnabled': _settingsProvider?.enableUomSystem ?? false,
        'isTaxEnabled': _settingsProvider?.enableTaxSystem ?? false,
        'taxInclusive': _settingsProvider?.taxInclusive ?? false,
        'taxRate': _settingsProvider?.taxRate ?? 0.0,
      }));
    });
    
    // AUTH ROUTES
    router.post('/auth/login', _login);
    
    // ── NEW POS ENDPOINTS ──
    router.post('/pos/logout', (Request request) async {
       _activePosCompanionId = null;
       return Response.ok(jsonEncode({'status': 'ok'}));
    });

    router.get('/pos/product-lookup/<barcode>', (Request request, String barcode) async {
      print('[SERVER] POS Lookup for code: $barcode');
      final isUomEnabled = _settingsProvider?.enableUomSystem ?? false;
      final unit = await _productRepository?.getUnitByBarcode(barcode);
      if (unit != null) {
        if (isUomEnabled || unit.conversionRate == 1) {
          final prodData = await _productRepository?.getProductWithVariants(unit.productId);
          return Response.ok(jsonEncode({
            'type': 'unit',
            'productId': unit.productId,
            'unit': unit.toJson(),
            'productName': prodData?['product']?.name,
            'productSku': prodData?['product']?.baseSku,
            'units': isUomEnabled ? (await _productRepository?.getUnitsByProductId(unit.productId))?.map((u) => u.toJson()).toList() : [],
          }));
        }
      }

      final variant = await _productRepository?.getVariantByBarcode(barcode);
      if (variant != null) {
        final prodData = await _productRepository?.getProductWithVariants(variant.productId);
        return Response.ok(jsonEncode({
          'type': 'variant',
          'productId': variant.productId,
          'variant': variant.toJson(),
          'productName': prodData?['product']?.name,
          'productSku': prodData?['product']?.baseSku,
          'units': isUomEnabled ? (await _productRepository?.getUnitsByProductId(variant.productId))?.map((u) => u.toJson()).toList() : [],
        }));
      }
      // ── Fallback: try looking up directly by variant ID or unit ID ──
      final variantById = await _productRepository?.getVariantById(barcode);
      if (variantById != null) {
        final prodData = await _productRepository?.getProductWithVariants(variantById.productId);
        return Response.ok(jsonEncode({
          'type': 'variant',
          'productId': variantById.productId,
          'variant': variantById.toJson(),
          'productName': prodData?['product']?.name,
          'productSku': prodData?['product']?.baseSku,
          'units': isUomEnabled ? (await _productRepository?.getUnitsByProductId(variantById.productId))?.map((u) => u.toJson()).toList() : [],
        }));
      }

      final unitById = await _productRepository?.getUnitById(barcode);
      if (unitById != null && (isUomEnabled || unitById.conversionRate == 1)) {
        final prodData = await _productRepository?.getProductWithVariants(unitById.productId);
        return Response.ok(jsonEncode({
          'type': 'unit',
          'productId': unitById.productId,
          'unit': unitById.toJson(),
          'productName': prodData?['product']?.name,
          'productSku': prodData?['product']?.baseSku,
          'units': isUomEnabled ? (await _productRepository?.getUnitsByProductId(unitById.productId))?.map((u) => u.toJson()).toList() : [],
        }));
      }

      return Response.notFound(jsonEncode({'error': 'Product not found'}));
    });

    router.get('/inventory/products/search', (Request request) async {
      final q = request.url.queryParameters['q'] ?? '';
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
      if (q.isEmpty) return Response.ok(jsonEncode([]));

      final products = await _productRepository?.searchProductsByName(q, limit: limit) ?? [];
      return Response.ok(jsonEncode(products));
    });

    router.post('/pos/cart/reserve', (Request request) async {
      final data = jsonDecode(await request.readAsString());
      await _productRepository?.reserveStock(
        variantId: data['variantId'],
        quantity: data['quantity'],
        deviceId: data['deviceId'],
      );
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'status': 'ok'}));
    });

    router.post('/pos/cart/release', (Request request) async {
      final data = jsonDecode(await request.readAsString());
      await _productRepository?.releaseStock(
        deviceId: data['deviceId'],
        variantId: data['variantId'],
        quantity: data['quantity'],
      );
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'status': 'ok'}));
    });

    router.get('/settings/payment-methods', (Request request) async {
      final methods = _settingsProvider?.paymentMethods ?? ['CASH', 'JAZZCASH', 'BANK'];
      return Response.ok(jsonEncode(methods));
    });

    router.get('/settings/pos-config', (Request request) async {
      return Response.ok(jsonEncode({
        'enableUomSystem': _settingsProvider?.enableUomSystem ?? true,
        'allowDiscounts': _settingsProvider?.allowDiscounts ?? true,
        'calculatePercentageDiscount': _settingsProvider?.calculatePercentageDiscount ?? false,
        'treatUomPriceGapAsDiscount': _settingsProvider?.treatUomPriceGapAsDiscount ?? false,
        'prorateUomRemainders': _settingsProvider?.prorateUomRemainders ?? false,
        'enableTax': _settingsProvider?.enableTaxSystem ?? false,
        'taxInclusive': _settingsProvider?.taxInclusive ?? false,
        'taxRate': _settingsProvider?.taxRate ?? 0.0,
        'storeName': _settingsProvider?.storeName ?? 'Utility Store',
        'storeLogo': _settingsProvider?.storeLogo ?? '',
        'storeAddress': _settingsProvider?.storeAddress ?? '',
        'storePhone': _settingsProvider?.storePhone ?? '',
        'receiptCustomMessage': _settingsProvider?.receiptCustomMessage ?? 'Thank you for shopping!',
      }));
    });

    router.post('/pos/cart/clear', (Request request) async {
      final data = jsonDecode(await request.readAsString());
      await _productRepository?.releaseStock(deviceId: data['deviceId']);
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'status': 'ok'}));
    });

    router.post('/pos/checkout', (Request request) async {
      final data = jsonDecode(await request.readAsString());
      final List<dynamic> itemsData = data['items'];
      final deviceId = data['deviceId'];

      try {
        final String invoiceNumber = data['invoice'] ?? 'INV-MOB-${DateTime.now().millisecondsSinceEpoch}';
        final String txId = 'txn_${DateTime.now().millisecondsSinceEpoch}';

        final List<TransactionItem> items = [];
        for (final item in itemsData) {
          String variantId = item['variantId'].toString();
          final productId = item['productId']?.toString();
          print('SERVER: Processing item variantId=$variantId, productId=$productId');
          
          if (productId != null && productId.isNotEmpty) {
             final resolvedBaseId = await _productRepository?.getPrimaryVariantId(productId);
             if (resolvedBaseId != null) {
               print('SERVER: Resolved productId $productId to primary variant $resolvedBaseId');
               variantId = resolvedBaseId;
             }
          } else if (variantId.contains('__')) {
             final pId = variantId.split('__').first;
             final resolvedBaseId = await _productRepository?.getPrimaryVariantId(pId);
             if (resolvedBaseId != null) {
               print('SERVER: Resolved composite variantId $variantId (pId $pId) to primary variant $resolvedBaseId');
               variantId = resolvedBaseId;
             }
          }

          final variant = await _productRepository?.getVariantById(variantId);
          if (variant == null) {
            print('SERVER WARNING: Variant $variantId NOT FOUND in database!');
          }

          items.add(TransactionItem(
            transactionId: txId,
            variantId: variantId,
            quantity: (item['quantity'] as num).toInt(),
            priceAtTime: (item['unitPrice'] as num).toDouble(),
            costAtTime: variant?.costPrice ?? 0,
            subtotal: (item['total'] as num).toDouble(),
            discount: (item['discount'] as num?)?.toDouble() ?? 0,
            discountPercent: 0,
            taxRate: 0,
            taxAmount: 0,
            unitId: item['unitId'],
            unitName: item['unitName'],
          ));
        }
        
        final tx = Transaction(
          id: txId,
          invoiceNumber: invoiceNumber,
          customerId: data['customerId'],
          totalAmount: (data['subtotal'] as num).toDouble(),
          discount: (data['discount'] as num).toDouble(),
          tax: 0,
          isTaxInclusive: true,
          finalAmount: (data['total'] as num).toDouble(),
          cashPaid: (data['cashPaid'] as num).toDouble(),
          creditAmount: (data['creditAmount'] as num).toDouble(),
          paymentMethod: data['paymentMethod'] ?? 'CASH',
          paymentStatus: (data['creditAmount'] as num) > 0 ? 'PARTIAL' : 'COMPLETED',
          createdAt: DateTime.now(),
        );

        final result = await _transactionRepository?.insertTransaction(
          transaction: tx,
          items: items,
          dueDate: data['dueDate'] != null ? DateTime.parse(data['dueDate']) : null,
        );

        // ALWAYS release reservations after checkout
        if (deviceId != null) {
          await _productRepository?.releaseStock(deviceId: deviceId);
        }

        _dataSyncService?.notifyMobileUpdate();
        
        // Trigger remote print on desktop with enriched product names
        if (_onRemoteCheckout != null) {
          final enrichedItems = List<TransactionItem>.from(items);
          for (int i = 0; i < enrichedItems.length; i++) {
             final v = await _productRepository?.getVariantById(enrichedItems[i].variantId);
             if (v != null) {
                // We use unitName field or similar to carry the product name temporarily for the print callback
                // But better to just pass a list of name/item pairs if needed.
                // For now, let's assume the callback can handle just the IDs or we enrich them here.
             }
          }
          _onRemoteCheckout!(tx, items);
        }
        
        return Response.ok(jsonEncode({
          'status': 'ok', 
          'invoice': invoiceNumber,
          'id': result?.id,
        }));
      } catch (e) {
        print('[SERVER] Checkout Error: $e');
        return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
      }
    });
    router.get('/inventory/customers', (Request request) async {
      final customers = await _customersRepository?.getAll() ?? [];
      return Response.ok(jsonEncode(customers.map((c) => c.toMap()).toList()));
    });

    // INVENTORY ROUTES
    router.get('/inventory/products', _getProducts);
    router.post('/inventory/products', _createProduct);
    router.post('/inventory/stock-update', _updateStock);
    router.post('/inventory/receive-carton', _receiveCarton);
    router.get('/inventory/categories', _getCategories);
    router.get('/inventory/suppliers', _getSuppliers);
    router.post('/inventory/suppliers', _createSupplier);
    
    // PRINTING ROUTES
    router.post('/pos/print', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);
        if (_onRemotePrint != null) {
          _onRemotePrint!(data);
          return Response.ok(jsonEncode({'status': 'ok', 'message': 'Print job queued on desktop'}));
        }
        return Response.ok(jsonEncode({'status': 'error', 'message': 'Print service not available on desktop'}));
      } catch (e) {
        return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
      }
    });

    // ANALYTICS ROUTES
    router.get('/analytics/summary', _getAnalyticsSummary);
    
    // SYNC/REPORT ROUTES
    // UPDATE INFO (Caches from Desktop)
    router.get('/update-info', (Request request) async {
       return Response.ok(jsonEncode({
         'updateInfo': _desktopAuthProvider?.androidUpdateInfo, // Give Android info to phone
         'desktopVersion': desktop_auth.AuthProvider.SUPPORTED_VERSION,
       }));
    });

    // ── SYNC VERSION ──
    router.get('/sync/version', (Request request) {
      return Response.ok(jsonEncode({
        'version': _dataSyncService?.dbVersion ?? 0,
        'ts': DateTime.now().toIso8601String(),
      }));
    });

    // ── PRODUCT EDIT / DELETE ──
    router.put('/inventory/products/<id>', (Request request, String id) async {
      return _updateProduct(request, id);
    });
    router.delete('/inventory/products/<id>', (Request request, String id) async {
      return _deleteProduct(request, id);
    });

    // ── CATEGORY CRUD ──
    router.post('/inventory/categories', _createCategory);
    router.put('/inventory/categories/<id>', (Request request, String id) async {
      return _updateCategory(request, id);
    });
    router.delete('/inventory/categories/<id>', (Request request, String id) async {
      return _deleteCategory(request, id);
    });

    // ── STOCK MOVEMENTS ──
    router.get('/inventory/stock-movements', _getStockMovements);

    // ── PRINT LABEL QUEUE ──
    router.post('/inventory/print-label', _enqueuePrintLabel);
    router.get('/inventory/print-queue', _getPrintQueue);

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
      'base_variant_id': s.primaryVariantId,
      'barcode': s.barcode ?? s.product.baseSku,
      'qr_code': s.qrCode ?? s.barcode ?? s.product.baseSku,
      'units': s.units.map((u) => u.toJson()).toList(),
    }).toList();
    return Response.ok(jsonEncode(list));
  }

  Future<Response> _createProduct(Request request) async {
    if (_productRepository == null) return Response.internalServerError();
    final body = await request.readAsString();
    final data = jsonDecode(body);
    
    try {
      final productId = (data['units'] != null && (data['units'] as List).isNotEmpty)
          ? await _productRepository!.createProductWithUoms(
              categoryId: data['categoryId'],
              name: data['name'],
              baseSku: data['baseSku'],
              description: data['description'],
              supplierId: data['supplierId'],
              baseUnit: ProductUnit.fromJson((data['units'] as List).firstWhere((u) => u['is_base_unit'] == 1 || u['is_base_unit'] == true)),
              multiplierUnits: (data['units'] as List)
                  .where((u) => u['is_base_unit'] == 0 || u['is_base_unit'] == false)
                  .map<ProductUnit>((u) => ProductUnit.fromJson(u))
                  .toList(),
              initialBaseStock: (data['initialStock'] as num?)?.toInt() ?? 0,
              lowStockThreshold: (data['lowStockThreshold'] as num?)?.toInt() ?? 10,
            )
          : await _productRepository!.createProductWithDefaultVariant(
              categoryId: data['categoryId'],
              name: data['name'],
              baseSku: data['baseSku'],
              description: data['description'],
              unitType: data['unitType'] ?? 'Pieces',
              supplierId: data['supplierId'],
              barcode: (data['barcode']?.toString().isEmpty ?? true) ? null : data['barcode'],
              qrCode: (data['qrCode']?.toString().isEmpty ?? true) ? null : data['qrCode'],
              costPrice: (data['costPrice'] as num?)?.toDouble() ?? 0.0,
              retailPrice: (data['retailPrice'] as num?)?.toDouble() ?? 0.0,
              wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble(),
              mrp: (data['mrp'] as num?)?.toDouble(),
              taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.0,
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
    final password = data['password'];
    final String? deviceId = data['deviceId']; // Optional, only for POS mode
    final bool isPosAttempt = data['requestPos'] == true;
    final remoteIp = (request.context['shelf.io.connection_info'] as HttpConnectionInfo?)?.remoteAddress.address;

    print('[SERVER] Login attempt for user: $username from IP: $remoteIp');
    
    if (_authService == null) return Response.internalServerError();

    final user = await _authService!.login(username, password);
    
    if (user != null) {
      if (isPosAttempt) {
         if (_activePosCompanionId != null && _activePosCompanionId != deviceId) {
           return Response.forbidden(jsonEncode({'error': 'Another mobile POS is already active'}));
         }
         _activePosCompanionId = deviceId;
      }

      // Save FCM Token if provided
      final fcmToken = data['fcmToken'];
      if (fcmToken != null && _settingsProvider != null) {
        _settingsProvider!.setAdminFcmToken(fcmToken);
        print('LocalServer: Registered FCM Token for $username: $fcmToken');
      }

      // For admin role, always send full permissions regardless of DB values
      final effectivePermissions = user.role == UserRole.admin
          ? UserPermissions.fromRole(UserRole.admin)
          : user.permissions;

      return Response.ok(jsonEncode({
        'status': 'success',
        'message': 'Logged in successfully',
        'token': _sessionKey,
        'role': user.role.toString().split('.').last,
        'permissions': effectivePermissions.toMap(),
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
        
      // 3. Notify Sync with a small delay to ensure DB commit is visible to other providers
      Future.delayed(const Duration(milliseconds: 100), () {
        _dataSyncService?.notifyMobileUpdate();
      });
      
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
      final variantId = await _productRepository!.getPrimaryVariantId(productId.trim());
      if (variantId == null) {
        print('Mobile Update Error: Variant not found for Product ID: $productId');
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

  // ── NEW HANDLERS ──

  Future<Response> _updateProduct(Request request, String productId) async {
    if (_productRepository == null) return Response.internalServerError();
    try {
      final data = jsonDecode(await request.readAsString());
      await _productRepository!.updateProduct(productId,
        categoryId: data['categoryId'],
        name: data['name'],
        baseSku: data['baseSku'],
        description: data['description'],
        unitType: data['unitType'],
        supplierId: data['supplierId'],
        costPrice: (data['costPrice'] as num?)?.toDouble(),
        retailPrice: (data['retailPrice'] as num?)?.toDouble(),
        wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble(),
        mrp: (data['mrp'] as num?)?.toDouble(),
        barcode: data['barcode'],
        qrCode: data['qrCode'],
        taxRate: (data['taxRate'] as num?)?.toDouble(),
        lowStockThreshold: (data['lowStockThreshold'] as num?)?.toInt(),
      );
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _deleteProduct(Request request, String productId) async {
    if (_productRepository == null) return Response.internalServerError();
    try {
      await _productRepository!.deleteProduct(productId);
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _createCategory(Request request) async {
    if (_categoryRepository == null) return Response.internalServerError();
    try {
      final data = jsonDecode(await request.readAsString());
      final id = await _categoryRepository!.createCategory(
        name: data['name'],
        parentId: data['parentId'],
        description: data['description'],
        iconName: data['iconName'],
      );
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'id': id, 'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _updateCategory(Request request, String categoryId) async {
    if (_categoryRepository == null) return Response.internalServerError();
    try {
      final data = jsonDecode(await request.readAsString());
      await _categoryRepository!.updateCategory(
        categoryId: categoryId,
        name: data['name'],
        description: data['description'],
        iconName: data['iconName'],
      );
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _deleteCategory(Request request, String categoryId) async {
    if (_categoryRepository == null) return Response.internalServerError();
    try {
      await _categoryRepository!.deleteCategory(categoryId);
      _dataSyncService?.notifyMobileUpdate();
      return Response.ok(jsonEncode({'status': 'success'}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _getStockMovements(Request request) async {
    if (_stockMovementRepository == null) return Response.internalServerError();
    try {
      final params = request.url.queryParameters;
      final productId = params['productId'];
      final movementType = params['type'];
      final limit = int.tryParse(params['limit'] ?? '100') ?? 100;

      // If productId supplied, find its primary variant first
      String? variantId;
      if (productId != null && _productRepository != null) {
        variantId = await _productRepository!.getPrimaryVariantId(productId);
      }

      final movements = await _stockMovementRepository!.getAllMovements(
        productVariantId: variantId,
        movementType: movementType,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        endDate: DateTime.now(),
      );

      final limited = movements.take(limit).toList();
      final json = limited.map((m) => {
        'id': m.id,
        'product_name': m.productName,
        'product_id': m.productId,
        'category_name': m.categoryName,
        'movement_type': m.movementType,
        'quantity_change': m.quantityChange,
        'quantity_before': m.quantityBefore,
        'quantity_after': m.quantityAfter,
        'reason': m.reason,
        'notes': m.notes,
        'unit_id': m.unitId,
        'unit_name': m.unitName,
        'reference_id': m.referenceId,
        'created_at': m.createdAt.toIso8601String(),
      }).toList();

      return Response.ok(jsonEncode(json));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _enqueuePrintLabel(Request request) async {
    try {
      final data = jsonDecode(await request.readAsString());
      final jobId = 'pj_${DateTime.now().millisecondsSinceEpoch}';
      final job = {
        'id': jobId,
        'productId': data['productId'],
        'unitId': data['unitId'],
        'unitName': data['unitName'],
        'productName': data['productName'],
        'barcode': data['barcode'],
        'qrData': data['qrData'],
        'copies': data['copies'] ?? 1,
        'status': 'queued',
        'createdAt': DateTime.now().toIso8601String(),
      };
      _printQueue.add(job);
      _processPrintQueue();
      
      // Also trigger the main thread UI callback for immediate printing
      if (_onRemotePrint != null) {
        _onRemotePrint!({
          'type': 'label',
          ...job,
        });
      }
      return Response.ok(jsonEncode({'jobId': jobId, 'status': 'queued', 'position': _printQueue.length}));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({'error': e.toString()}));
    }
  }

  Future<Response> _getPrintQueue(Request request) async {
    return Response.ok(jsonEncode({
      'queue': _printQueue,
      'isPrinting': _isPrinting,
      'pending': _printQueue.where((j) => j['status'] == 'queued').length,
    }));
  }

  void _processPrintQueue() async {
    if (_isPrinting) return;
    final pending = _printQueue.where((j) => j['status'] == 'queued').toList();
    if (pending.isEmpty) return;

    _isPrinting = true;
    final job = pending.first;
    job['status'] = 'printing';

    try {
      // Import is handled at Desktop level via Printing package
      // Signal the main isolate to print by using the DataSyncService
      // For desktop Windows, Printing.layoutPdf can only run on the main UI thread
      // We record the job as "done" here; actual Printing.layoutPdf is triggered
      // by a StreamBuilder on the desktop UI listening to print queue events.
      // This is the lightweight queue implementation—desktop POS app can
      // display print toast + trigger printing when it sees a new queued job.
      await Future.delayed(const Duration(milliseconds: 500));
      job['status'] = 'done';
    } catch (e) {
      job['status'] = 'error';
      job['error'] = e.toString();
    } finally {
      _isPrinting = false;
      _processPrintQueue(); // Process next
    }
  }
}
