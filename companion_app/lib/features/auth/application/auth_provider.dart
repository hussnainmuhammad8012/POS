import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

enum AppMode { selection, inventory, admin }

class AuthProvider extends ChangeNotifier {
  String? _serverIp;
  String? _accessToken;
  bool _isPaired = false;
  bool _isLoggedIn = false;
  AppMode _currentMode = AppMode.selection;
  String? _shopName;

  String? get serverIp => _serverIp;
  String? get accessToken => _accessToken;
  bool get isPaired => _isPaired;
  bool get isLoggedIn => _isLoggedIn;
  AppMode get currentMode => _currentMode;
  String? get shopName => _shopName;

  AuthProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverIp = prefs.getString('server_ip');
    _accessToken = prefs.getString('access_token');
    _shopName = prefs.getString('shop_name');
    _isPaired = _serverIp != null && _accessToken != null;
    notifyListeners();
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
            final String name = jsonDecode(response.body)['appName'] ?? 'Gravity POS';
            debugPrint('[AUTH] SUCCESS on $targetIp');
            await _savePairing('$targetIp:$serverPort', sessionToken, name);
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
        return true;
      }
      
      onProgress?.call('No PC found. Please check Firewall or Hotspot.');
    } catch (e) {
      debugPrint('Pairing error: $e');
      onProgress?.call('Error: ${e.toString()}');
    }
    return false;
  }

  Future<void> _savePairing(String address, String token, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', address);
    await prefs.setString('access_token', token);
    await prefs.setString('shop_name', name);
    _serverIp = address;
    _accessToken = token;
    _shopName = name;
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
        _isLoggedIn = true;
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
    _serverIp = null;
    _accessToken = null;
    _shopName = null;
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
