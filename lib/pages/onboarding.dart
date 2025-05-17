import 'package:flutter/material.dart';
import 'log-in-page.dart';
import 'sign-in-page.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      body: Column(
        children: [
          // Car Image Placeholder
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFE7FE54),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Stack(
              clipBehavior: Clip.none, // Allows overflow
              children: [
                Positioned(
                  top: -450, // Adjust as needed
                  left: -470,
                  child: SizedBox(
                    height: 1350,
                    width: 1350,
                    child: Image.asset('assets/images/Mask-group.png'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 96),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Find The best car for your best ride!",
              textAlign: TextAlign.left,

              style: TextStyle(
                fontSize: 46,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                height: 1,
                letterSpacing: 2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Subtitle
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              "Luxury cars, own drivers and instant delivery of cars anywhere in the world.",
              textAlign: TextAlign.left,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ),

          const Spacer(),

          // Get Started Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                child: const Text(
                  "Get Started",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Already have an account text
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            child: const Text(
              "already have an account",
              style: TextStyle(color: Colors.grey),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
