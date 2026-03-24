import 'package:flutter/foundation.dart';

@immutable
class Category {
  final int? id;
  final String name;
  final String? description;
  final String? iconName;
  final DateTime createdAt;

  const Category({
    this.id,
    required this.name,
    this.description,
    this.iconName,
    required this.createdAt,
  });

  Category copyWith({
    int? id,
    String? name,
    String? description,
    String? iconName,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@immutable
class Product {
  final int? id;
  final String? barcode;
  final String name;
  final int? categoryId;
  final double sellingPrice;
  final double? costPrice;
  final int currentStock;
  final int lowStockThreshold;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Product({
    this.id,
    this.barcode,
    required this.name,
    this.categoryId,
    required this.sellingPrice,
    this.costPrice,
    required this.currentStock,
    this.lowStockThreshold = 5,
    this.imagePath,
    required this.createdAt,
    this.updatedAt,
  });

  Product copyWith({
    int? id,
    String? barcode,
    String? name,
    int? categoryId,
    double? sellingPrice,
    double? costPrice,
    int? currentStock,
    int? lowStockThreshold,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      currentStock: currentStock ?? this.currentStock,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@immutable
class Customer {
  final String? id;
  final String name;
  final String? phone;
  final String? whatsappNumber;
  final String? address;
  final String? email;
  final int loyaltyPoints;
  final double totalSpent;
  final double currentCredit;
  final double creditLimit;
  final DateTime? lastPurchaseDate;
  final DateTime createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.whatsappNumber,
    this.address,
    this.email,
    this.loyaltyPoints = 0,
    this.totalSpent = 0,
    this.currentCredit = 0.0,
    this.creditLimit = 0.0,
    this.lastPurchaseDate,
    required this.createdAt,
  });

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? whatsappNumber,
    String? address,
    String? email,
    int? loyaltyPoints,
    double? totalSpent,
    double? currentCredit,
    double? creditLimit,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      address: address ?? this.address,
      email: email ?? this.email,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
      currentCredit: currentCredit ?? this.currentCredit,
      creditLimit: creditLimit ?? this.creditLimit,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'whatsapp_number': whatsappNumber,
    'address': address,
    'email': email,
    'loyalty_points': loyaltyPoints,
    'total_spent': totalSpent,
    'current_credit': currentCredit,
    'credit_limit': creditLimit,
    'last_purchase_date': lastPurchaseDate?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };
}

@immutable
class Transaction {
  final String? id;
  final String invoiceNumber;
  final String? customerId;
  final String? customerName;
  final double totalAmount;
  final double discount;
  final double discountPercent; // Percentage discount for the whole bill
  final double tax;
  final bool isTaxInclusive;
  final double finalAmount;
  final double cashPaid;
  final double creditAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.totalAmount,
    this.discount = 0.0,
    this.discountPercent = 0.0,
    this.tax = 0.0,
    this.isTaxInclusive = false,
    required this.finalAmount,
    this.cashPaid = 0.0,
    this.creditAmount = 0.0,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  Transaction copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    double? totalAmount,
    double? discount,
    double? discountPercent,
    double? tax,
    bool? isTaxInclusive,
    double? finalAmount,
    double? cashPaid,
    double? creditAmount,
    String? paymentMethod,
    String? paymentStatus,
    DateTime? createdAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      discount: discount ?? this.discount,
      discountPercent: discountPercent ?? this.discountPercent,
      tax: tax ?? this.tax,
      isTaxInclusive: isTaxInclusive ?? this.isTaxInclusive,
      finalAmount: finalAmount ?? this.finalAmount,
      cashPaid: cashPaid ?? this.cashPaid,
      creditAmount: creditAmount ?? this.creditAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@immutable
class CreditLedger {
  final String id;
  final String customerId;
  final String? transactionId;
  final String type; // 'CREDIT' or 'PAYMENT'
  final double amount;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;

  const CreditLedger({
    required this.id,
    required this.customerId,
    this.transactionId,
    required this.type,
    required this.amount,
    this.dueDate,
    this.notes,
    required this.createdAt,
  });
}

@immutable
class TransactionItem {
  final String? id;
  final String transactionId;
  final String variantId;
  final int quantity;
  final double priceAtTime;
  final double? costAtTime;
  final double subtotal;
  final double discount;   // Per-item discount
  final double discountPercent; 
  final double taxRate;    // Per-item tax rate
  final double taxAmount;  // Calculated tax amount
  final String? unitId;     // UOM: which unit was sold
  final String? unitName;   // UOM: human-readable unit name for receipt

  const TransactionItem({
    this.id,
    required this.transactionId,
    required this.variantId,
    required this.quantity,
    required this.priceAtTime,
    this.costAtTime,
    required this.subtotal,
    this.discount = 0.0,
    this.discountPercent = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.unitId,
    this.unitName,
  });

  TransactionItem copyWith({
    String? id,
    String? transactionId,
    String? variantId,
    int? quantity,
    double? priceAtTime,
    double? costAtTime,
    double? subtotal,
    double? discount,
    double? discountPercent,
    double? taxRate,
    double? taxAmount,
    String? unitId,
    String? unitName,
  }) {
    return TransactionItem(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      priceAtTime: priceAtTime ?? this.priceAtTime,
      costAtTime: costAtTime ?? this.costAtTime,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      discountPercent: discountPercent ?? this.discountPercent,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      unitId: unitId ?? this.unitId,
      unitName: unitName ?? this.unitName,
    );
  }
}

@immutable
class StockMovement {
  final int? id;
  final int productId;
  final int quantityChange;
  final String reason;
  final int? referenceId;
  final DateTime createdAt;

  const StockMovement({
    this.id,
    required this.productId,
    required this.quantityChange,
    required this.reason,
    this.referenceId,
    required this.createdAt,
  });
}

@immutable
class Supplier {
  final String? id;
  final String name;
  final String? contactPerson;
  final String? phone;
  final String? email;
  final String? address;
  final double totalPurchased;
  final double currentDue;
  final DateTime createdAt;

  const Supplier({
    this.id,
    required this.name,
    this.contactPerson,
    this.phone,
    this.email,
    this.address,
    this.totalPurchased = 0.0,
    this.currentDue = 0.0,
    required this.createdAt,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    double? totalPurchased,
    double? currentDue,
    DateTime? createdAt,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPerson: contactPerson ?? this.contactPerson,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      totalPurchased: totalPurchased ?? this.totalPurchased,
      currentDue: currentDue ?? this.currentDue,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@immutable
class SupplierLedger {
  final String id;
  final String supplierId;
  final String? referenceId; // carton_id or payment_id
  final String type; // 'PURCHASE', 'PAYMENT', or 'SYSTEM_NOTE'
  final double amount;
  final DateTime? dueDate;
  final String? notes;
  final DateTime createdAt;

  const SupplierLedger({
    required this.id,
    required this.supplierId,
    this.referenceId,
    required this.type,
    required this.amount,
    this.dueDate,
    this.notes,
    required this.createdAt,
  });
}
