// list_car_bloc.dart
// ─────────────────────────────────────────────────────────────────
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rental_app/services/cloudinary_service.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 👈 NEW
import 'list_car_event.dart';
import 'list_car_state.dart';

// (You don’t need auth_service.dart or auth_bloc.dart inside the bloc itself,
// so feel free to remove those two imports if they’re now unused.)

class ListCarBloc extends Bloc<ListCarEvent, ListCarState> {
  ListCarBloc() : super(ListCarInitial()) {
    on<SubmitCarListing>((event, emit) async {
      // ── 1️⃣  Guard-clause: user must be logged in ────────────────────────────
      if (FirebaseAuth.instance.currentUser == null) {
        emit(ListCarError(message: 'You must be logged in to list a car.'));
        return;
      }

      emit(ListCarLoading());
      try {
        // ── 2️⃣  Upload each picked image to Cloudinary ───────────────────────
        final List<String> imageUrls = [];
        for (var image in event.selectedImages) {
          final url = await uploadImageToCloudinary(image);
          if (url != null) imageUrls.add(url);
        }

        // ── 3️⃣  Build Firestore payload ─────────────────────────────────────
        final String ownerInitials =
            event.ownerName
                .split(' ')
                .map((n) => n.isNotEmpty ? n[0] : '')
                .join();

        final String carId = const Uuid().v4();
        final String ownerId = FirebaseAuth.instance.currentUser!.uid; // 👈 NEW

        final Map<String, dynamic> carData = {
          'id': carId,
          'ownerId': ownerId, // 👈 NEW (for filtering)
          'name': event.carName,
          'type': event.transmission,
          'price': event.rentalPrice,
          'rating': 4.5, // default
          'location': event.location,
          'ownerInitials': ownerInitials,
          'ownerName': event.ownerName,
          'images': imageUrls,
          'rules': event.rules,
          'createdAt': FieldValue.serverTimestamp(),
          'transmission': event.transmission,
          'days': event.days, // placeholder
          'seater': event.seater,
          'kms': event.kms,
          'availableFrom': Timestamp.fromDate(event.availableFrom),
          'availableTo': Timestamp.fromDate(event.availableTo),
        };

        // ── 4️⃣  Save to Firestore ───────────────────────────────────────────
        await FirebaseFirestore.instance
            .collection('cars')
            .doc(carId)
            .set(carData);
        // ✅ Notify the user that their car has been listed
        final notificationRef =
            FirebaseFirestore.instance
                .collection('users')
                .doc(ownerId) // 👈 Use the existing variable
                .collection('notifications')
                .doc();

        await notificationRef.set({
          'type': 'listing',
          'message':
              "Your car '${event.carName}' has been listed successfully! check my cars page for more info",
          'carId': carId,
          'seen': false,
          'timestamp': FieldValue.serverTimestamp(),
        });

        emit(ListCarSuccess(carId: carId));
      } catch (e) {
        emit(ListCarError(message: 'Failed to list car: $e'));
      }
    });
  }
}
