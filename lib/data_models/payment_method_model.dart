import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodModel {
  final String paymentMethodId;
  final String cardBrand;
  final String last4;

  final bool isDefault;
  final Timestamp addedAt;

  PaymentMethodModel({
    required this.paymentMethodId,
    required this.cardBrand,
    required this.last4,
    this.isDefault = true,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentMethodId': paymentMethodId,
      'cardBrand': cardBrand,
      'last4': last4,
      'isDefault': isDefault,
      'addedAt': addedAt,
    };
  }

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
