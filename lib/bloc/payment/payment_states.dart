import 'package:equatable/equatable.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentMethodAdded extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final String paymentIntentId;
  const PaymentSuccess(this.paymentIntentId);
  @override
  List<Object> get props => [paymentIntentId];
}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError({required this.message});
  @override
  List<Object> get props => [message];
}
