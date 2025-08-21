import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a saved payment method for a customer.
class PaymentMethodModel {
  // --- Core Fields ---
  final String paymentMethodId; // This is the reusable token from Paymob
  final String cardBrand; // e.g., "VISA", "MasterCard"
  final String last4; // The last four digits of the card

  // --- Metadata ---
  final bool isDefault;
  final Timestamp addedAt;

  PaymentMethodModel({
    required this.paymentMethodId,
    required this.cardBrand,
    required this.last4,
    this.isDefault = true,
    required this.addedAt,
  });

  /// Converts this PaymentMethodModel instance into a Map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'paymentMethodId': paymentMethodId,
      'cardBrand': cardBrand,
      'last4': last4,
      'isDefault': isDefault,
      'addedAt': addedAt,
    };
  }

  /// Creates a PaymentMethodModel instance from a Firestore map.
  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      paymentMethodId: map['paymentMethodId'] ?? '',
      cardBrand: map['cardBrand'] ?? 'Card',
      last4: map['last4'] ?? '••••',
      isDefault: map['isDefault'] ?? true,
      addedAt: map['addedAt'] ?? Timestamp.now(),
    );
  }
}
