// Create a new file called navigation_helper.dart

import 'package:flutter/material.dart';
import 'detail.dart'; // Contains CarDetailScreen
import 'list_car_screen.dart';
import 'past_rentals_screen.dart';
import 'listing_page.dart'; // Add this import at the top
import 'package:rental_app/pages/past_rentals_screen.dart';

class NavigationHelper {
  // Navigate to home (Car Detail Screen)
  static void navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const ExplorePage(), //
      ),
      (route) => false,
    );
  }

  // Navigate to List Car Screen
  static void navigateToListCar(BuildContext context) {
    // Check if we're already on the ListCarScreen
    bool isCurrentRouteListCar = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == 'ListCarScreen') {
        isCurrentRouteListCar = true;
        return true;
      }
      return false;
    });

    // If we're already on ListCarScreen, refresh it
    if (isCurrentRouteListCar) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ListCarScreen(),
          settings: const RouteSettings(name: 'ListCarScreen'),
        ),
      );
    } else {
      // Otherwise navigate to ListCarScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ListCarScreen(),
          settings: const RouteSettings(name: 'ListCarScreen'),
        ),
      );
    }
  }

  // Navigate to Past Rentals Screen
  static void navigateToPastRentals(BuildContext context) {
    // Check if we're already on the PastRentalsScreen
    bool isCurrentRoutePastRentals = false;
    Navigator.popUntil(context, (route) {
      if (route.settings.name == 'PastRentalsScreen') {
        isCurrentRoutePastRentals = true;
        return true;
      }
      return false;
    });

    // If we're already on PastRentalsScreen, do nothing
    if (isCurrentRoutePastRentals) {
      return;
    }

    // Otherwise navigate to PastRentalsScreen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PastRentalsScreen(),
      ), // ✅ correct
    );
  }

  // Handle bottom navigation bar navigation
  static void handleBottomNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Home tab
        navigateToHome(context);
        break;
      case 1:
        // List Car tab
        navigateToListCar(context);
        break;
      case 2:
        // Account/Past Rentals tab
        navigateToPastRentals(context);
        break;
    }
  }
}
