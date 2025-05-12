// Updated listing_page.dart with improved Firestore fetching

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'list_car_screen.dart';
import 'past_rentals_screen.dart';
import 'car_model.dart'; // Import the shared Car model
import 'detail.dart'; // Import the detail screen
import 'package:rental_app/pages/detail.dart' as detail;
import 'package:rental_app/pages/past_rentals_screen.dart';

class ListingPage extends StatelessWidget {
  const ListingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: const Color(0xFFCCFF00), // Neon green color
        fontFamily: 'Roboto',
      ),
      home: const ExplorePage(),
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  bool _isLoading = true;
  List<Car> _cars = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCarsFromFirebase();
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      // Already on home, do nothing
    } else if (index == 1) {
      // Navigate to List Car screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ListCarScreen()),
      );
    } else if (index == 2) {
      // Navigate to Past Rentals screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PastRentalsScreen()),
      );
    }
  }

  // Fetch cars from Firebase
  Future<void> _fetchCarsFromFirebase() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('📱 Fetching cars from Firestore...');

      // Get cars collection from Firestore
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('cars')
              .orderBy('createdAt', descending: true)
              .get();

      print('📱 Fetched ${snapshot.docs.length} cars from Firestore');

      if (snapshot.docs.isEmpty) {
        print('📱 No cars found in Firestore');
      }

      // Convert documents to Car objects
      final List<Car> cars = [];

      for (var doc in snapshot.docs) {
        try {
          final car = Car.fromFirestore(doc);
          cars.add(car);
          print('📱 Added car: ${car.name}');
        } catch (e) {
          print('📱 Error parsing car document: $e');
        }
      }

      setState(() {
        _cars = cars;
        _isLoading = false;
      });

      print('📱 Updated state with ${cars.length} cars');
    } catch (e) {
      print('📱 Error fetching cars: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading cars: $e';
      });
    }
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
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                ],
              ),
            ),

            // Car list
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFCCFF00),
                          ),
                        ),
                      )
                      : _errorMessage != null
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchCarsFromFirebase,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                      : _cars.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.car_rental,
                              color: Colors.grey,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No cars available',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ListCarScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('List Your Car'),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchCarsFromFirebase,
                        color: const Color(0xFFCCFF00),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cars.length,
                          itemBuilder: (context, index) {
                            final car = _cars[index];
                            return CarCard(car: car);
                          },
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
                    onTap: () => _handleNavigation(0),
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
                    onTap: () => _handleNavigation(1),
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
                    onTap: () => _handleNavigation(2),
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

class CarCard extends StatelessWidget {
  final Car car;

  const CarCard({Key? key, required this.car}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to car detail page with the car ID
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarDetailScreen(carId: car.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Car Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child:
                  car.images.isNotEmpty
                      ? Image.network(
                        car.images[0],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[800],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFCCFF00),
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading image: $error');
                          return Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(
                                Icons.error_outline,
                                size: 50,
                                color: Colors.red,
                              ),
                            ),
                          );
                        },
                      )
                      : Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[800],
                        child: const Center(
                          child: Icon(
                            Icons.directions_car,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Name
                  Text(
                    car.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    car.type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Price
                  Text(
                    '\$${car.price.toInt()}/day',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Rating and Location
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Color(0xFFCCFF00),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        car.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          car.location,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Owner Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[700],
                        child: Text(
                          car.ownerInitials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          car.ownerName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to car detail page with the car ID
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => CarDetailScreen(carId: car.id),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
