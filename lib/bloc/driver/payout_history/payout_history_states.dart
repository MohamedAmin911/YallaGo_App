import 'package:equatable/equatable.dart';
import 'package:taxi_app/data_models/payout_request.dart';

abstract class PayoutHistoryState extends Equatable {
  const PayoutHistoryState();

  @override
  List<Object?> get props => [];
}

class PayoutHistoryLoading extends PayoutHistoryState {}

class PayoutHistoryLoaded extends PayoutHistoryState {
  final List<PayoutRequest> payouts;
  const PayoutHistoryLoaded(this.payouts);

  @override
  List<Object?> get props => [payouts];
}

class PayoutHistoryError extends PayoutHistoryState {
  final String message;
  const PayoutHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}
