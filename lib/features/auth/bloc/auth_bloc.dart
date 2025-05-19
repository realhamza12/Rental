// auth_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // Create user with email and password
        UserCredential userCredential = await _auth
            .createUserWithEmailAndPassword(
              email: event.email,
              password: event.password,
            );

        // Save additional user info in Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'first_name': event.firstName,
          'last_name': event.lastName,
          'email': event.email,
          'created_at': Timestamp.now(),
        });

        emit(Authenticated(user: userCredential.user!));
      } on FirebaseAuthException catch (e) {
        emit(
          AuthError(message: e.message ?? 'An error occurred during sign up'),
        );
      } catch (e) {
        emit(AuthError(message: e.toString()));
      }
    });

    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        emit(Authenticated(user: userCredential.user!));
      } on FirebaseAuthException catch (e) {
        emit(
          AuthError(message: e.message ?? 'An error occurred during sign in'),
        );
      } catch (e) {
        emit(AuthError(message: e.toString()));
      }
    });

    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        await _auth.signOut();
        emit(Unauthenticated());
      } catch (e) {
        emit(AuthError(message: e.toString()));
      }
    });
  }
}
