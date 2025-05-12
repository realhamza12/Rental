import 'package:flutter/material.dart';
import 'car_model.dart'; // Import the Car model
import 'past_rentals_screen.dart'; // Import the Past Rentals screen
import 'list_car_screen.dart'; // Import the List Car screen
import 'navigation_helper.dart';

class BookingConfirmationScreen extends StatelessWidget {
  final Car car;

  const BookingConfirmationScreen({Key? key, required this.car})
    : super(key: key);

  void _handleNavigation(BuildContext context, int index) {
    NavigationHelper.handleBottomNavigation(context, index);
  }

  @override
  Widget build(BuildContext context) {
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
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
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
                      ),
                    ),
                    Text(
                      car.type,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

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

                    const SizedBox(height: 30),

                    // Checkmark Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Note Text
                    const Text(
                      'note: keep your CNIC ready. The owner will contact you shortly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.white),
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
                          horizontal: 40,
                          vertical: 12,
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
                color: Colors.black,
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
