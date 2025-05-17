import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'car_model.dart';
import 'listing_event.dart';
import 'listing_state.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListingBloc extends Bloc<ListingEvent, ListingState> {
  ListingBloc() : super(ListingInitial()) {
    on<LoadListings>((event, emit) async {
      emit(ListingLoading());

      try {
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;

        // Start with a basic query without complex filters to avoid index issues
        Query query = FirebaseFirestore.instance.collection('cars');

        // Apply filters one by one
        if (event.location != null && event.location!.isNotEmpty) {
          query = query.where('location', isEqualTo: event.location);
        }

        // Get all cars first, then filter client-side
        final snapshot = await query.get();
        print('📱 Found ${snapshot.docs.length} total cars');

        // Convert to list of Car objects
        final allCars =
            snapshot.docs.map((doc) => Car.fromFirestore(doc)).toList();

        // Filter client-side for available cars and exclude current user's cars
        final cars =
            allCars.where((car) {
              // Check if car is available (either field doesn't exist or is true)
              final isAvailable = car.isAvailable;

              // Exclude current user's cars
              final notOwnCar = car.ownerId != currentUserId;

              // Apply date range filter if provided
              bool matchesDateRange = true;
              if (event.dateRange != null &&
                  car.availableFrom != null &&
                  car.availableTo != null) {
                matchesDateRange =
                    !(car.availableTo!.isBefore(event.dateRange!.start) ||
                        car.availableFrom!.isAfter(event.dateRange!.end));
              }

              return isAvailable && notOwnCar && matchesDateRange;
            }).toList();

        // Sort by creation date (newest first)
        cars.sort((a, b) {
          // You might need to add a createdAt field to your Car model
          // For now, we'll just keep the original order
          return 0;
        });

        print('📱 Found ${cars.length} available cars after filtering');
        emit(ListingLoaded(cars: cars));
      } catch (e) {
        print('📱 Error loading listings: $e');
        emit(ListingError(message: 'Failed to load cars: ${e.toString()}'));
      }
    });
  }
}
