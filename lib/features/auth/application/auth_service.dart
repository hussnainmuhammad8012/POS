import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/auth_models.dart';

class AuthService {
  static AuthService get instance => AuthService();
  final Database _db = AppDatabase.instance.db;

  // Points to our RaiRoyals Management Website API
  static const String _baseUrl = 'https://rairoyalscodebackend-production.up.railway.app/api';
  
  Future<String> getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
  
  Future<UserAccount?> login(String username, String password) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );

    if (maps.isEmpty) return null;

    final user = UserAccount.fromMap(maps.first);
    
    // Remote verification (placeholder logic)
    // In a real scenario, we would verify with the website here
    // and potentially check if this account is already in use elsewhere
    // await _verifySessionRemotely(user);

    return user;
  }

  Future<String> _getDeviceId() async {
    // Check if we already have a generated device ID in DB
    final List<Map<String, dynamic>> maps = await _db.query('settings', where: 'key = ?', whereArgs: ['device_unique_id']);
    
    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }

    // Generate a new one if not exists
    final String newId = 'DV-${DateTime.now().millisecondsSinceEpoch}-${_randomString(8)}';
    
    // Check if settings table exists, if not, it will be handled by the database initialize (usually)
    // Here we assume it exists from previous steps or we insert it.
    await _db.insert('settings', {'key': 'device_unique_id', 'value': newId});
    return newId;
  }

  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(Iterable.generate(
      length, (_) => chars.codeUnitAt(DateTime.now().microsecond % chars.length)
    ));
  }

  Future<String?> getLicenseKey() async {
    final List<Map<String, dynamic>> maps = await _db.query('settings', where: 'key = ?', whereArgs: ['license_key']);
    if (maps.isEmpty) return null;
    return maps.first['value'] as String;
  }

  Future<bool> hasAcceptedTerms() async {
    final List<Map<String, dynamic>> maps = await _db.query('settings', where: 'key = ?', whereArgs: ['terms_accepted']);
    if (maps.isEmpty) return false;
    return maps.first['value'] == 'true';
  }

  Future<void> acceptTerms() async {
    await _db.insert(
      'settings', 
      {'key': 'terms_accepted', 'value': 'true'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>> activateLicense(String key) async {
    try {
      final String deviceId = await _getDeviceId();
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-license'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'licenseKey': key,
          'deviceId': deviceId,
          'currentVersion': await getAppVersion(),
          'platform': 'windows',
          'checkUpdate': true // Activation always checks for initial update
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          // Save valid license key
          await _db.insert(
            'settings',
            {'key': 'license_key', 'value': key},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        return data;
      }
      return {
        'valid': false,
        'message': 'Server returned error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'valid': false,
        'message': 'Connection error: $e',
      };
    }
  }

  Future<void> _verifySessionRemotely(UserAccount user) async {
    final deviceId = await _getDeviceId();
    await http.post(
      Uri.parse('$_baseUrl/auth/verify-session'), // Placeholder endpoint
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': user.username,
        'deviceId': deviceId,
      }),
    );
  }

  Future<Map<String, dynamic>> checkLicenseStatus({bool checkUpdate = false, String? platform}) async {
    try {
      // Check for a staged 'next_license_key' from a prior update
      final List<Map<String, dynamic>> nextKeyMaps = await _db.query('settings', where: 'key = ?', whereArgs: ['next_license_key']);
      final String? nextKey = nextKeyMaps.isNotEmpty ? nextKeyMaps.first['value'] as String : null;

      final String? currentKey = await getLicenseKey();
      final String? licenseKey = nextKey ?? currentKey;

      if (licenseKey == null && platform == null) {
        return {
          'valid': false,
          'needsActivation': true,
          'message': 'License Key Required',
        };
      }

      final String deviceId = await _getDeviceId();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/verify-license'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'licenseKey': licenseKey ?? 'GUEST',
          'deviceId': deviceId,
          'currentVersion': await getAppVersion(),
          'platform': platform ?? 'windows',
          'checkUpdate': checkUpdate
        }),
      ).timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // If we used a 'nextKey' and it's valid, perform key rotation locally
        if (data['valid'] == true && nextKey != null) {
          await _db.insert(
            'settings',
            {'key': 'license_key', 'value': nextKey},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _db.delete('settings', where: 'key = ?', whereArgs: ['next_license_key']);
        }

        // If a nextLicenseKey is provided for a future update, store it
        if (data['updateInfo'] != null && data['updateInfo']['nextLicenseKey'] != null) {
          await _db.insert(
            'settings',
            {'key': 'next_license_key', 'value': data['updateInfo']['nextLicenseKey']},
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        return data;
      }
      return {
        'valid': true, // Fail open if offline but previously activated
        'isBlocked': false,
        'status': 'offline',
      };
    } catch (e) {
      final key = await getLicenseKey();
      return {
        'valid': key != null,
        'isBlocked': false,
        'status': 'offline',
      };
    }
  }

  Future<List<UserAccount>> getAllUsers() async {
    final List<Map<String, dynamic>> maps = await _db.query('users');
    return maps.map((m) => UserAccount.fromMap(m)).toList();
  }

  Future<void> updateUserPermissions(String username, UserPermissions permissions) async {
    await _db.update(
      'users',
      permissions.toMap(),
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<void> updateUserPassword(String username, String newPassword) async {
    await _db.update(
      'users',
      {'password': newPassword},
      where: 'username = ?',
      whereArgs: [username],
    );
  }
}
