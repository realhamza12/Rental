import 'package:flutter/material.dart';
import 'car_model.dart';
import 'booking_confirmation_screen.dart';

class DirectNavigationHelper {
  // Static method to navigate to booking confirmation
  static void navigateToBookingConfirmation(BuildContext context, Car car) {
    print("🚀 Direct navigation helper: Navigating to booking confirmation");

    // Use a delay to ensure any pending operations are completed
    Future.delayed(Duration.zero, () {
      try {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(car: car),
          ),
        );
        print("✅ Direct navigation completed successfully");
      } catch (e, stackTrace) {
        print("❌ Direct navigation error: $e");
        print("🔍 Stack trace: $stackTrace");

        // Show error message
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Navigation failed: $e')));
      }
    });
  }
}
