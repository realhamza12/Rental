

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import 'auth_service.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  ProfileBloc({required AuthService authService})
      : _authService = authService,
        super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<UpdateProfile>(_onUpdateProfile);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final User? user = _auth.currentUser;
      
      if (user == null) {
        emit(const ProfileError(message: 'User not authenticated'));
        return;
      }
      
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        emit(const ProfileError(message: 'User profile not found'));
        return;
      }
      
      // Get rental statistics - count bookings for this user
      final bookingsQuery = await _firestore
          .collection('bookings')
          .where('bookedBy', isEqualTo: user.uid)
          .get();
      
      // Get favorites count
      final favoritesQuery = await _firestore
          .collection('favorites')
          .where('user_id', isEqualTo: user.uid)
          .get();
      
      // Combine user data with statistics
      final userData = {
        ...userDoc.data() ?? {},
        'totalRentals': bookingsQuery.docs.length,
        'favorites': favoritesQuery.docs.length,
        'memberSince': userDoc.data()?['created_at'] != null
            ? (userDoc.data()?['created_at'] as Timestamp).toDate().toString().split(' ')[0]
            : DateTime.now().toString().split(' ')[0],
        'rating': 4.7, // Default rating or calculate from reviews
      };
      
      emit(ProfileLoaded(user: user, userData: userData));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileUpdating());
    try {
      final User? user = _auth.currentUser;
      
      if (user == null) {
        emit(const ProfileError(message: 'User not authenticated'));
        return;
      }
      
      // Update user data in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'first_name': event.firstName,
        'last_name': event.lastName,
        'phone': event.phone,
        'address': event.address,
        'updated_at': Timestamp.now(),
      });
      
      // Reload profile to get updated data
      add(LoadProfile());
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      await _auth.signOut();
      emit(ProfileSignedOut());
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }
}