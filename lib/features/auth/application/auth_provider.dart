import 'package:flutter/material.dart';
import '../../../core/models/auth_models.dart';
import 'auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;
  
  bool _isBlocked = false;
  bool get isBlocked => _isBlocked;
  
  bool _isTrialExpired = false;
  bool get isTrialExpired => _isTrialExpired;
  
  bool _needsActivation = false;
  bool get needsActivation => _needsActivation;

  bool _hasAcceptedTerms = true; // Default to true until checked
  bool get hasAcceptedTerms => _hasAcceptedTerms;
  
  String _statusMessage = '';
  String get statusMessage => _statusMessage;

  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String username, String password) async {
    try {
      final user = await _authService.login(username, password);
      if (user != null) {
        _currentUser = user;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _statusMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Future<void> checkLicense() async {
    final status = await _authService.checkLicenseStatus();
    _isBlocked = status['isBlocked'] ?? false;
    _needsActivation = status['needsActivation'] ?? false;
    _hasAcceptedTerms = await _authService.hasAcceptedTerms();
    
    // Trial logic
    final isTrial = status['isTrial'] ?? false;
    final daysRemaining = status['daysRemaining'] ?? 0;
    
    if (isTrial && daysRemaining <= 0) {
      _isTrialExpired = true;
    } else {
      _isTrialExpired = false;
    }
    
    _statusMessage = status['message'] ?? '';
    notifyListeners();
  }

  Future<void> acceptTerms() async {
    await _authService.acceptTerms();
    _hasAcceptedTerms = true;
    notifyListeners();
  }

  Future<bool> activateLicense(String key) async {
    try {
      final status = await _authService.activateLicense(key);
      if (status['valid'] == true) {
        _needsActivation = false;
        _isBlocked = status['isBlocked'] ?? false;
        _statusMessage = 'License Activated Successfully';
        notifyListeners();
        return true;
      }
      _statusMessage = status['message'] ?? 'Invalid License Key';
      notifyListeners();
      return false;
    } catch (e) {
      _statusMessage = 'Activation failed: $e';
      notifyListeners();
      return false;
    }
  }
  
  bool hasPermission(bool Function(UserPermissions) selector) {
    if (_currentUser == null) return false;
    if (_currentUser!.role == UserRole.admin) return true;
    return selector(_currentUser!.permissions);
  }
}
