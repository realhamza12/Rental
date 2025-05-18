// car_listing_success_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'navigation_helper.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarListingSuccessScreen extends StatefulWidget {
  const CarListingSuccessScreen({super.key});

  @override
  State<CarListingSuccessScreen> createState() =>
      _CarListingSuccessScreenState();
}

class _CarListingSuccessScreenState extends State<CarListingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _secondsRemaining = 7;
  late Timer _timer;

  @override
  void initState() {
    super.initState();

    // Set up animation for the success icon
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // Start the animation
    _animationController.forward();

    // Set up timer for auto-navigation
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          _navigateToHome();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _navigateToHome() {
    NavigationHelper.navigateToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(Icons.grid_view, size: 20),
                  ),
                  const Text(
                    'Rental',
                    style: TextStyle(
                      fontFamily: 'Conthrax',
                      color: Color(0xFFCCFF00),
                      fontSize: 21,
                    ),
                  ),
                  FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        );
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>?;
                      if (userData == null) {
                        return const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        );
                      }

                      final firstName = userData['first_name'] as String? ?? '';
                      final lastName = userData['last_name'] as String? ?? '';
                      final initials =
                          (firstName.isNotEmpty ? firstName[0] : '') +
                          (lastName.isNotEmpty ? lastName[0] : '');

                      return CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[700],
                        child: Text(
                          initials.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success animation
                      ScaleTransition(
                        scale: _animation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCCFF00).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Color(0xFFCCFF00),
                            size: 80,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Success message
                      const Text(
                        'Car Listed Successfully!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      const Text(
                        'Your car has been listed and is now available for rental. You will be notified when someone books your car.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Countdown timer
                      Text(
                        'Returning to home in $_secondsRemaining seconds...',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Return to home button
                      ElevatedButton(
                        onPressed: _navigateToHome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCCFF00),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Return to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Colors.grey[900]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap:
                        () =>
                            NavigationHelper.handleBottomNavigation(context, 0),
                    child: Column(children: [Icon(Icons.home), Text('home')]),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.compare_arrows, color: Colors.grey, size: 24),
                      Text(
                        'List Car',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.account_circle_outlined,
                        color: Colors.grey,
                        size: 24,
                      ),
                      Text(
                        'account',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
