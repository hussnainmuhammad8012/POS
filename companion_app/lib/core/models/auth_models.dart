class UserPermissions {
  final bool canAccessPos;
  final bool canAccessInventory;
  final bool canAccessCustomers;
  final bool canAccessSuppliers;
  final bool canAccessTransactions;
  final bool canAccessCredits;
  final bool canAccessDues;
  final bool canAccessAnalytics;

  UserPermissions({
    this.canAccessPos = false,
    this.canAccessInventory = false,
    this.canAccessCustomers = false,
    this.canAccessSuppliers = false,
    this.canAccessTransactions = false,
    this.canAccessCredits = false,
    this.canAccessDues = false,
    this.canAccessAnalytics = false,
  });

  factory UserPermissions.fromMap(Map<String, dynamic> map) {
    return UserPermissions(
      canAccessPos: (map['canAccessPos'] ?? 0) == 1,
      canAccessInventory: (map['canAccessInventory'] ?? 0) == 1,
      canAccessCustomers: (map['canAccessCustomers'] ?? 0) == 1,
      canAccessSuppliers: (map['canAccessSuppliers'] ?? 0) == 1,
      canAccessTransactions: (map['canAccessTransactions'] ?? 0) == 1,
      canAccessCredits: (map['canAccessCredits'] ?? 0) == 1,
      canAccessDues: (map['canAccessDues'] ?? 0) == 1,
      canAccessAnalytics: (map['canAccessAnalytics'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'canAccessPos': canAccessPos ? 1 : 0,
      'canAccessInventory': canAccessInventory ? 1 : 0,
      'canAccessCustomers': canAccessCustomers ? 1 : 0,
      'canAccessSuppliers': canAccessSuppliers ? 1 : 0,
      'canAccessTransactions': canAccessTransactions ? 1 : 0,
      'canAccessCredits': canAccessCredits ? 1 : 0,
      'canAccessDues': canAccessDues ? 1 : 0,
      'canAccessAnalytics': canAccessAnalytics ? 1 : 0,
    };
  }
}
