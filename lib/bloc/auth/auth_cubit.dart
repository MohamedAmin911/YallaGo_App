import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxi_app/bloc/auth/auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthCubit() : super(AuthInitial());

  String? _verificationId;

  void sendOtp(String phoneNumber) async {
    emit(AuthLoading());
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          emit(AuthError(message: "Verification failed: ${e.message}"));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          emit(AuthCodeSent(verificationId: verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  void verifyOtp(String otp) async {
    if (_verificationId == null) {
      emit(AuthError(message: "Verification ID is not available."));
      return;
    }

    emit(AuthLoading());
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } catch (e) {
      emit(AuthError(message: "Invalid OTP or error: ${e.toString()}"));
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      if (userCredential.user != null) {
        emit(AuthLoggedIn(user: userCredential.user!));
      } else {
        emit(AuthError(message: "Login failed, please try again."));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(message: "Firebase Auth Error: ${e.message}"));
    } catch (e) {
      emit(AuthError(message: "An unknown error occurred: ${e.toString()}"));
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      emit(AuthLoggedOut());
    } catch (e) {
      emit(AuthError(message: "Failed to sign out: ${e.toString()}"));
    }
  }
}
