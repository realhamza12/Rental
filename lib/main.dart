import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rental_app/pages/booking_confirmation_screen.dart';
import 'package:rental_app/pages/profile_page.dart';

import 'firebase_options.dart';
import 'pages/onboarding.dart';
import 'pages/listing_page.dart';
import 'pages/auth_service.dart';
import 'pages/notifications_screen.dart';
import 'package:rental_app/pages/car_model.dart';
// if needed for type casting

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rental App',
      debugShowCheckedModeBanner: false,
      routes: {
        '/notifications': (context) => const NotificationsScreen(),
        '/bookingConfirmation':
            (context) => BookingConfirmationScreen(
              car: ModalRoute.of(context)!.settings.arguments as Car,
            ),
        // add more routes here if needed
      },
      theme: ThemeData(
        fontFamily: 'BeVietnamPro',
        scaffoldBackgroundColor: const Color(0xFF282931),
        textTheme: ThemeData.dark().textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF000000),
          primary: Color(0xFFE7FE54),
        ),
      ),
      home: ProfilePage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/bookingConfirmation') {
          final car = settings.arguments as Car;
          return MaterialPageRoute(
            builder: (context) => BookingConfirmationScreen(car: car),
          );
        }

        // Add other dynamic routes here if needed

        return null; // Let Flutter show unknown route error if route not found
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthService _authService = AuthService();

  AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const ListingPage();
        }

        return const OnboardingScreen();
      },
    );
  }
}
