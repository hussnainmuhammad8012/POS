import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void setSelectedIndex(int index) {
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }

  // Helper methods to navigate to specific screens
  void navigateToDashboard() => setSelectedIndex(0);
  void navigateToPos() => setSelectedIndex(1);
  void navigateToInventory() => setSelectedIndex(2);
  void navigateToCustomers() => setSelectedIndex(3);
  void navigateToSuppliers() => setSelectedIndex(4);
  void navigateToTransactions() => setSelectedIndex(5);
  void navigateToCredits() => setSelectedIndex(6);
  void navigateToAnalytics() => setSelectedIndex(7);
  void navigateToSettings() => setSelectedIndex(8);
}
