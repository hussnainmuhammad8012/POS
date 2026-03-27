import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/models/auth_models.dart';
import '../../../../main.dart' show navigatorKey;
import '../../../../core/widgets/update_dialog.dart';

enum AppMode { selection, inventory, admin, pos }

class AuthProvider extends ChangeNotifier {
  String? _serverIp;
  String? _accessToken;
  bool _isPaired = false;
  bool _isLoggedIn = false;
  AppMode _currentMode = AppMode.selection;
  String? _shopName;
  String? _storeLogo;
  String? _role;
  UserPermissions? _permissions;

  static const String _globalBaseUrl = 'https://rairoyalscodebackend-production.up.railway.app/api';
  
  static Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  String _appVersion = '1.0.0';
  String get appVersion => _appVersion;

  Map<String, dynamic>? _updateInfo;
  bool _updateDialogShown = false;

  String? get serverIp => _serverIp;
  String? get accessToken => _accessToken;
  bool get isPaired => _isPaired;
  bool get isLoggedIn => _isLoggedIn;
  AppMode get currentMode => _currentMode;
  String? get shopName => _shopName;
  String? get storeLogo => _storeLogo;
  String? get role => _role;
  UserPermissions? get permissions => _permissions;
  Map<String, dynamic>? get updateInfo => _updateInfo;
  bool get updateDialogShown => _updateDialogShown;

  void markUpdateDialogShown() {
    _updateDialogShown = true;
    notifyListeners();
  }

  // Specific Permission Getters
  bool get canAccessInventory => _role == 'admin' || (_permissions?.canAccessInventory ?? false);
  bool get canAccessAnalytics => _role == 'admin' || (_permissions?.canAccessAnalytics ?? false);
  bool get canAccessSuppliers => _role == 'admin' || (_permissions?.canAccessSuppliers ?? false);
  bool get canAccessPos => _role == 'admin' || _role == 'pos_user' || (_permissions?.canAccessInventory ?? false); // Assuming POS users usually have inventory access or similar

  AuthProvider() {
    _initVersion();
    _loadSettings();
  }

  Future<void> _initVersion() async {
    _appVersion = await getAppVersion();
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString('server_ip');
    _accessToken = prefs.getString('access_token');
    _shopName = prefs.getString('shop_name');
    _storeLogo = prefs.getString('store_logo');
    _isPaired = _serverIp != null && _accessToken != null;
    notifyListeners();
    
    // Auto-check on startup REMOVED per user request to save server resources
    // checkRemoteUpdate(); 
  }

  Future<void> checkRemoteUpdate({bool isManual = false}) async {
    try {
      // 1. Try LOCAL PC first if paired (Proxy/Cache mode)
      if (_serverIp != null) {
        try {
          debugPrint('[UPDATE] Checking local PC at $_serverIp...');
          final localResponse = await http.get(
            Uri.parse('http://$_serverIp/update-info'),
            headers: {'Authorization': 'Bearer $_accessToken'},
          ).timeout(const Duration(seconds: 5));

          if (localResponse.statusCode == 200) {
            final localData = jsonDecode(localResponse.body);
            if (localData['updateInfo'] != null) {
              _updateInfo = localData['updateInfo'];
              debugPrint('[UPDATE] Got cached update from PC: $_updateInfo');
              if (_updateInfo!['available'] == true && !_updateDialogShown) {
                _showGlobalUpdateDialog();
              }
              notifyListeners();
              return; // Success via Proxy
            }
          }
        } catch (e) {
          debugPrint('[UPDATE] Local PC update check failed (offline?): $e');
        }
      }

      // 2. Only hit global backend if manual or if local check failed/skipped
      if (!isManual && _updateInfo != null) return; 

      final prefs = await SharedPreferences.getInstance();
      final licenseKey = prefs.getString('license_key');
      
      debugPrint('[UPDATE] Hitting global backend (Railway)...');
      final response = await http.post(
        Uri.parse('$_globalBaseUrl/verify-license'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'licenseKey': licenseKey ?? 'COMPANION-GUEST',
          'deviceId': 'COMPANION-DEVICE',
          'currentVersion': _appVersion,
          'platform': 'android'
        }),
      ).timeout(const Duration(seconds: 120)); // Robust 2-min timeout

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _updateInfo = data['updateInfo'];
        debugPrint('[UPDATE CHECK] Success: $_updateInfo');
        
        if (_updateInfo != null && _updateInfo!['available'] == true && !_updateDialogShown) {
          _showGlobalUpdateDialog();
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Remote update check failed: $e');
    }
  }

  void _showGlobalUpdateDialog() {
    if (_updateDialogShown || _updateInfo == null) return;
    
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[UPDATE] Navigator context not ready. Will retry...');
      return;
    }

    _updateDialogShown = true;
    showDialog(
      context: context,
      barrierDismissible: !(_updateInfo!['isCritical'] ?? false),
      builder: (context) => MobileUpdateDialog(
        version: _updateInfo!['version'],
        url: _updateInfo!['url'],
        releaseNotes: _updateInfo!['releaseNotes'],
        isCritical: _updateInfo!['isCritical'] ?? false,
      ),
    );
  }

  Future<bool> pairWithServer(String qrData, {Function(String status)? onProgress}) async {
    try {
      final trimmedData = qrData.trim();
      debugPrint('Scanned QR Content: "$trimmedData"');
      
      List<String> ips = [];
      int port;
      String token;

      onProgress?.call('Parsing QR data...');
      debugPrint('[AUTH] Raw QR Data: $trimmedData');

      if (trimmedData.startsWith('{')) {
        final Map<String, dynamic> data = jsonDecode(trimmedData);
        debugPrint('[AUTH] Decoded JSON: $data');
        if (data.containsKey('ips')) {
          ips = List<String>.from(data['ips']);
        } else if (data.containsKey('ip')) {
          ips = [data['ip']];
        }
        port = data['port'];
        token = data['session_key'];
      } else if (trimmedData.contains('|')) {
        final parts = trimmedData.split('|');
        if (parts.length != 3) return false;
        ips = [parts[1].split(':')[0]];
        port = int.parse(parts[1].split(':')[1]);
        token = parts[2];
      } else {
        onProgress?.call('Invalid QR format');
        return false;
      }
      
      final int serverPort = port;
      final String sessionToken = token;

      onProgress?.call('Scanning all network paths...');
      
      // Ensure 127.0.0.1 is always tried for USB
      if (!ips.contains('127.0.0.1')) {
        ips.insert(0, '127.0.0.1');
      }

      // Create parallel connection tasks
      final List<Future<bool>> tasks = ips.map((targetIp) async {
        final isLocalhost = targetIp == '127.0.0.1';
        try {
          final uri = Uri.parse('http://$targetIp:$serverPort/ping');
          debugPrint('[AUTH] Testing $targetIp...');
          final response = await http.get(
            uri,
            headers: {'Authorization': 'Bearer $sessionToken'},
          ).timeout(Duration(seconds: isLocalhost ? 2 : 5));
          
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final String name = data['appName'] ?? 'Gravity POS';
            final String? logo = data['storeLogo'];
            debugPrint('[AUTH] SUCCESS on $targetIp');
            await _savePairing('$targetIp:$serverPort', sessionToken, name, logo);
            return true;
          }
        } catch (_) {}
        return false;
      }).toList();

      // Wait for the first success or all failures
      bool found = false;
      await Future.wait(tasks.map((task) async {
        if (await task) found = true;
      }));

      if (found) {
        onProgress?.call('Connected successfully!');
        checkRemoteUpdate(); // Trigger check after pairing
        return true;
      }
      
      onProgress?.call('No PC found. Please check Firewall or Hotspot.');
    } catch (e) {
      debugPrint('Pairing error: $e');
      onProgress?.call('Error: ${e.toString()}');
    }
    return false;
  }

  Future<void> _savePairing(String address, String token, String name, String? logo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', address);
    await prefs.setString('access_token', token);
    await prefs.setString('shop_name', name);
    if (logo != null) {
      await prefs.setString('store_logo', logo);
    } else {
      await prefs.remove('store_logo');
    }
    _serverIp = address;
    _accessToken = token;
    _shopName = name;
    _storeLogo = logo;
    _isPaired = true;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    if (!_isPaired) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final fcmToken = prefs.getString('fcm_token');

      final response = await http.post(
        Uri.parse('http://$_serverIp/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
        body: jsonEncode({
          'username': username, 
          'password': password,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        _isLoggedIn = true;
        _role = responseData['role'];
        if (responseData['permissions'] != null) {
          _permissions = UserPermissions.fromMap(responseData['permissions']);
        }
        checkRemoteUpdate(); // Trigger check after login
        notifyListeners();
        return true;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Session invalid (Server probably restarted)
        await unpair(); 
      }
    } catch (e) {
      debugPrint('Login error: $e');
    }
    return false;
  }

  Future<void> unpair() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('server_ip');
    await prefs.remove('access_token');
    await prefs.remove('shop_name');
    await prefs.remove('store_logo');
    _serverIp = null;
    _accessToken = null;
    _shopName = null;
    _storeLogo = null;
    _isPaired = false;
    _isLoggedIn = false;
    _currentMode = AppMode.selection;
    notifyListeners();
  }

  void setAppMode(AppMode mode) {
    _currentMode = mode;
    notifyListeners();
  }

  void resetMode() {
    _currentMode = AppMode.selection;
    _isLoggedIn = false;
    // We don't necessarily unpair here, just go back to selection
    notifyListeners();
  }
}
