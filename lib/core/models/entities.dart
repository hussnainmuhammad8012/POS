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
  final int? id;
  final String name;
  final String? phone;
  final String? email;
  final int loyaltyPoints;
  final double totalSpent;
  final DateTime? lastPurchaseDate;
  final DateTime createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    this.email,
    this.loyaltyPoints = 0,
    this.totalSpent = 0,
    this.lastPurchaseDate,
    required this.createdAt,
  });

  Customer copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    int? loyaltyPoints,
    double? totalSpent,
    DateTime? lastPurchaseDate,
    DateTime? createdAt,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      totalSpent: totalSpent ?? this.totalSpent,
      lastPurchaseDate: lastPurchaseDate ?? this.lastPurchaseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

@immutable
class Transaction {
  final int? id;
  final String invoiceNumber;
  final int? customerId;
  final double totalAmount;
  final double discount;
  final double tax;
  final double finalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime createdAt;

  const Transaction({
    this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.totalAmount,
    this.discount = 0,
    this.tax = 0,
    required this.finalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });
}

@immutable
class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final int quantity;
  final double priceAtTime;
  final double? costAtTime;
  final double subtotal;

  const TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.priceAtTime,
    this.costAtTime,
    required this.subtotal,
  });
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

