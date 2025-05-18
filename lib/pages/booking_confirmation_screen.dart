import 'package:flutter/material.dart';
import 'car_model.dart'; // Import the Car model

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation_helper.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Car car;

  const BookingConfirmationScreen({super.key, required this.car});

  void _handleNavigation(BuildContext context, int index) {
    NavigationHelper.handleBottomNavigation(context, index);
  }

  @override
  Widget build(BuildContext context) {
    print("🏗️ Building BookingConfirmationScreen for car: ${car.name}");

    return Scaffold(
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
                      color: Color(0xFFCCFF00),
                      fontFamily: 'BeVietnamPro',
                      fontSize: 24,
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
                          radius: 24,
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
                          radius: 24,
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
                        radius: 24,
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
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Car Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child:
                          car.images.isNotEmpty
                              ? Image.network(
                                car.images[0],
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print("❌ Error loading image: $error");
                                  return Container(
                                    height: 250,
                                    width: double.infinity,
                                    color: Colors.grey[800],
                                    child: const Center(
                                      child: Icon(Icons.error, size: 50),
                                    ),
                                  );
                                },
                              )
                              : Image.asset(
                                'assets/images/car_placeholder.jpg',
                                height: 250,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                    ),

                    const SizedBox(height: 16),

                    // Car Name and Type
                    Text(
                      car.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,

                        color: Colors.white
                        
                      ),
                    ),
                    Text(
                      car.type,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(125, 255, 255, 255)
                      ),
                    ),

                    SizedBox(
                      height: 34,
                    ),



                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: const Color(0xFFCCFF00),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),

                    SizedBox(height: 20,),

                    // Booking Text
                    Text(
                      'BOOKING',
                      style: TextStyle(
                        fontSize: 36,
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      'CONFIRMED!',
                      style: TextStyle(
                        fontSize: 36,
                        fontFamily: 'BeVietnamPro',
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Checkmark Icon
                    

                    

                    // Note Text
                    SizedBox(
                      width: 380,
                      child: const Text(
                        'note: keep your CNIC ready. The owner will contact you shortly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Color.fromARGB(157, 255, 255, 255)),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // View Past Rentals Button
                    ElevatedButton(
                      onPressed: () {
                        NavigationHelper.navigateToPastRentals(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCCFF00),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 75,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'View Past Rentals',
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

            // Bottom Navigation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                
                border: Border(
                  top: BorderSide(color: Colors.grey[900]!, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => _handleNavigation(context, 0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.home,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        Text(
                          'home',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _handleNavigation(context, 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.compare_arrows,
                          color: Colors.grey,
                          size: 24,
                        ),
                        Text(
                          'List Car',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _handleNavigation(context, 2),
                    child: Column(
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
