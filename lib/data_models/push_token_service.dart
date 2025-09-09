import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushTokenService {
  final _db = FirebaseFirestore.instance;

  Future<void> register(String driverUid) async {
    final messaging = FirebaseMessaging.instance;

// Ask permission (iOS, Android 13+ dialog is system-level)
    await messaging.requestPermission();

    final token = await messaging.getToken();
    if (token != null) {
      await _db
          .collection('drivers')
          .doc(driverUid)
          .collection('fcmTokens')
          .doc(token)
          .set({
        'token': token,
        'platform': 'flutter',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _db
          .collection('drivers')
          .doc(driverUid)
          .collection('fcmTokens')
          .doc(newToken)
          .set({
        'token': newToken,
        'platform': 'flutter',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }
}
