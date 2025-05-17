// Create a new file called welcome_confirmation.dart

import 'package:flutter/material.dart';
import 'listing_page.dart';

class WelcomeConfirmationPage extends StatelessWidget {
  final String firstName;

  const WelcomeConfirmationPage({super.key, required this.firstName});

  @override
  Widget build(BuildContext context) {
    // Auto-navigate to listing page after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ListingPage()),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Checkmark icon in a circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFCCFF00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.black, size: 80),
            ),

            const SizedBox(height: 40),

            // Welcome text
            Text(
              "Woohoo!",
              style: TextStyle(
                color: const Color(0xFFCCFF00),
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Welcome to Rental, $firstName!",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Your account has been created successfully. You'll be redirected to the home page in a moment.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),
            // Spinning wheel animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 1),
              curve: Curves.linear,
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 6.28, // 2 * pi
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/wheel.jpg',
                height: 60,
                width: 60,
              ),
            ),

            // Loading indicator
          ],
        ),
      ),
    );
  }
}
