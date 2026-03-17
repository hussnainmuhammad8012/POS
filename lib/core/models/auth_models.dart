enum UserRole {
  admin,
  pos,
  inventoryManager,
}

class UserPermissions {
  final bool canAccessPos;
  final bool canAccessInventory;
  final bool canAccessCustomers;
  final bool canAccessSuppliers;
  final bool canAccessTransactions;
  final bool canAccessCredits;
  final bool canAccessDues;
  final bool canAccessAnalytics;
  final bool canAccessSettings;

  UserPermissions({
    required this.canAccessPos,
    required this.canAccessInventory,
    required this.canAccessCustomers,
    required this.canAccessSuppliers,
    required this.canAccessTransactions,
    required this.canAccessCredits,
    required this.canAccessDues,
    required this.canAccessAnalytics,
    required this.canAccessSettings,
  });

  factory UserPermissions.fromRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return UserPermissions(
          canAccessPos: true,
          canAccessInventory: true,
          canAccessCustomers: true,
          canAccessSuppliers: true,
          canAccessTransactions: true,
          canAccessCredits: true,
          canAccessDues: true,
          canAccessAnalytics: true,
          canAccessSettings: true,
        );
      case UserRole.pos:
        return UserPermissions(
          canAccessPos: true,
          canAccessInventory: false,
          canAccessCustomers: true, // Needed for customer search in POS
          canAccessSuppliers: false,
          canAccessTransactions: false,
          canAccessCredits: false,
          canAccessDues: false,
          canAccessAnalytics: false,
          canAccessSettings: false,
        );
      case UserRole.inventoryManager:
        return UserPermissions(
          canAccessPos: false,
          canAccessInventory: true,
          canAccessCustomers: false,
          canAccessSuppliers: true,
          canAccessTransactions: false,
          canAccessCredits: false,
          canAccessDues: true,
          canAccessAnalytics: false,
          canAccessSettings: false,
        );
    }
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
      'canAccessSettings': canAccessSettings ? 1 : 0,
    };
  }

  factory UserPermissions.fromMap(Map<String, dynamic> map) {
    return UserPermissions(
      canAccessPos: map['canAccessPos'] == 1,
      canAccessInventory: map['canAccessInventory'] == 1,
      canAccessCustomers: map['canAccessCustomers'] == 1,
      canAccessSuppliers: map['canAccessSuppliers'] == 1,
      canAccessTransactions: map['canAccessTransactions'] == 1,
      canAccessCredits: map['canAccessCredits'] == 1,
      canAccessDues: map['canAccessDues'] == 1,
      canAccessAnalytics: map['canAccessAnalytics'] == 1,
      canAccessSettings: map['canAccessSettings'] == 1,
    );
  }

  UserPermissions copyWith({
    bool? canAccessPos,
    bool? canAccessInventory,
    bool? canAccessCustomers,
    bool? canAccessSuppliers,
    bool? canAccessTransactions,
    bool? canAccessCredits,
    bool? canAccessDues,
    bool? canAccessAnalytics,
    bool? canAccessSettings,
  }) {
    return UserPermissions(
      canAccessPos: canAccessPos ?? this.canAccessPos,
      canAccessInventory: canAccessInventory ?? this.canAccessInventory,
      canAccessCustomers: canAccessCustomers ?? this.canAccessCustomers,
      canAccessSuppliers: canAccessSuppliers ?? this.canAccessSuppliers,
      canAccessTransactions: canAccessTransactions ?? this.canAccessTransactions,
      canAccessCredits: canAccessCredits ?? this.canAccessCredits,
      canAccessDues: canAccessDues ?? this.canAccessDues,
      canAccessAnalytics: canAccessAnalytics ?? this.canAccessAnalytics,
      canAccessSettings: canAccessSettings ?? this.canAccessSettings,
    );
  }
}

class UserAccount {
  final int? id;
  final String username;
  final String password; // In a real app, this should be hashed
  final UserRole role;
  final UserPermissions permissions;

  UserAccount({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.permissions,
  });

  Map<String, dynamic> toMap() {
    final map = permissions.toMap();
    map['id'] = id;
    map['username'] = username;
    map['password'] = password;
    map['role'] = role.name;
    return map;
  }

  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
      permissions: UserPermissions.fromMap(map),
    );
  }
}
