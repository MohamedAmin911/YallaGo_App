import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/driver/payout_history/payout_history_states.dart';
import 'package:taxi_app/data_models/payout_request.dart';

class PayoutHistoryCubit extends Cubit<PayoutHistoryState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  PayoutHistoryCubit() : super(PayoutHistoryLoading());

  Future<void> fetchHistory(String driverUid) async {
    emit(PayoutHistoryLoading());
    try {
      final snap = await _db
          .collection('payouts')
          .where('driverUid', isEqualTo: driverUid)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      final list = snap.docs
          .map((d) => PayoutRequest.fromDoc(
              d as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      emit(PayoutHistoryLoaded(list));
    } catch (e) {
      emit(PayoutHistoryError(e.toString()));
    }
  }
}
