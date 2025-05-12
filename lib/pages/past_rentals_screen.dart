import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'list_car_screen.dart';
import 'car_model.dart';
import 'navigation_helper.dart';

class PastRentalsScreen extends StatefulWidget {
  const PastRentalsScreen({Key? key}) : super(key: key);

  @override
  State<PastRentalsScreen> createState() => _PastRentalsScreenState();
}

class _PastRentalsScreenState extends State<PastRentalsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _pastRentals = [];
  String? _errorMessage;

  // In a real app, you would get this from authentication
  // For now, we'll use a hardcoded user ID
  final String _userId = 'current_user_id';

  @override
  void initState() {
    super.initState();
    _fetchPastRentals();
  }

  // Navigation handling
  void _handleNavigation(int index) {
    NavigationHelper.handleBottomNavigation(context, index);
  }

  Future<void> _fetchPastRentals() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('📱 Fetching past rentals from Firestore...');

      // Get bookings collection from Firestore
      // Assuming you have a 'bookings' collection where each document represents a booking
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              // Filter by user ID in a real app
              // .where('userId', isEqualTo: _userId)
              // Order by booking date, most recent first
              .orderBy('bookingDate', descending: true)
              .get();

      print('📱 Fetched ${snapshot.docs.length} bookings from Firestore');

      if (snapshot.docs.isEmpty) {
        print('📱 No bookings found in Firestore');
        setState(() {
          _pastRentals = [];
          _isLoading = false;
        });
        return;
      }

      // Convert documents to rental objects
      final List<Map<String, dynamic>> rentals = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Get car details for this booking
          DocumentSnapshot? carDoc;
          if (data['carId'] != null) {
            carDoc =
                await FirebaseFirestore.instance
                    .collection('cars')
                    .doc(data['carId'])
                    .get();
          }

          // Create rental object with combined booking and car data
          final Map<String, dynamic> rental = {
            'id': doc.id,
            'carId': data['carId'] ?? '',
            'carName':
                carDoc != null && carDoc.exists
                    ? (carDoc.data() as Map<String, dynamic>)['name'] ??
                        'Unknown Car'
                    : data['carName'] ?? 'Unknown Car',
            'location':
                carDoc != null && carDoc.exists
                    ? (carDoc.data() as Map<String, dynamic>)['location'] ??
                        'Unknown Location'
                    : data['location'] ?? 'Unknown Location',
            'startDate':
                data['startDate'] != null
                    ? (data['startDate'] as Timestamp).toDate()
                    : DateTime.now(),
            'endDate':
                data['endDate'] != null
                    ? (data['endDate'] as Timestamp).toDate()
                    : DateTime.now().add(const Duration(days: 1)),
            'rating': data['rating'] ?? 0,
            'totalAmount': data['totalAmount'] ?? 0,
            'imageUrl':
                carDoc != null &&
                        carDoc.exists &&
                        (carDoc.data() as Map<String, dynamic>)['images'] !=
                            null &&
                        ((carDoc.data() as Map<String, dynamic>)['images']
                                as List)
                            .isNotEmpty
                    ? (carDoc.data() as Map<String, dynamic>)['images'][0]
                    : 'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d',
            'isRated': data['isRated'] ?? false,
          };

          rentals.add(rental);
          print('📱 Added rental: ${rental['carName']}');
        } catch (e) {
          print('📱 Error parsing rental document: $e');
        }
      }

      setState(() {
        _pastRentals = rentals;
        _isLoading = false;
      });

      print('📱 Updated state with ${rentals.length} rentals');
    } catch (e) {
      print('📱 Error fetching rentals: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading past rentals: $e';
      });
    }
  }

  // Update rating in Firestore
  Future<void> _updateRating(String rentalId, int newRating) async {
    try {
      // Update the rating in Firestore
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(rentalId)
          .update({'rating': newRating, 'isRated': true});

      // Update local state
      setState(() {
        for (int i = 0; i < _pastRentals.length; i++) {
          if (_pastRentals[i]['id'] == rentalId) {
            _pastRentals[i]['rating'] = newRating;
            _pastRentals[i]['isRated'] = true;
            break;
          }
        }
      });

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rating updated to $newRating stars'),
          backgroundColor: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('📱 Error updating rating: $e');
      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating rating: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
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

            // Past Rentals Title
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: const Text(
                'Past Rentals',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFCCFF00),
                  fontFamily: 'BeVietnamPro',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Main content
            Expanded(
              child:
                  _isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
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
                              onPressed: _fetchPastRentals,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                      : _pastRentals.isEmpty
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
                              'No past rentals found',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to home to book a car
                                _handleNavigation(0);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Book a Car'),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchPastRentals,
                        color: const Color(0xFFCCFF00),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _pastRentals.length,
                          itemBuilder: (context, index) {
                            final rental = _pastRentals[index];
                            final dateFormat = DateFormat('dd MMM');
                            final startDate = dateFormat.format(
                              rental['startDate'],
                            );
                            final endDate = dateFormat.format(
                              rental['endDate'],
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE7FE54),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Car Name
                                        Text(
                                          rental['carName'],
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Location
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                rental['location'],
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),

                                        // Dates
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              color: Colors.black,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$startDate - $endDate',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),

                                        // Rating Stars
                                        Row(
                                          children: List.generate(
                                            5,
                                            (starIndex) => GestureDetector(
                                              onTap: () {
                                                // Update rating when star is tapped
                                                _updateRating(
                                                  rental['id'],
                                                  starIndex + 1,
                                                );
                                              },
                                              child: Icon(
                                                starIndex <
                                                        (rental['rating'] ?? 0)
                                                    ? Icons.star
                                                    : Icons.star_border,
                                                color: Colors.black,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),

                                        // Total Amount
                                        Text(
                                          'Total: \$${rental['totalAmount']}',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Car Image (positioned to the right)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    bottom: 0,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16.0),
                                        bottomRight: Radius.circular(16.0),
                                      ),
                                      child: Image.network(
                                        rental['imageUrl'],
                                        width: 150,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (
                                          context,
                                          child,
                                          loadingProgress,
                                        ) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Container(
                                            width: 150,
                                            color: Colors.grey[300],
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          print('Error loading image: $error');
                                          return Container(
                                            width: 150,
                                            color: Colors.grey[300],
                                            child: const Center(
                                              child: Icon(
                                                Icons.error_outline,
                                                size: 30,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
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
                      children: const [
                        Icon(Icons.home, color: Colors.grey, size: 24),
                        Text(
                          'home',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
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
                      children: [
                        Icon(
                          Icons.account_circle_outlined,
                          color: Color(0xFFCCFF00),
                          size: 24,
                        ),
                        Text(
                          'account',
                          style: TextStyle(
                            color: Color(0xFFCCFF00),
                            fontSize: 12,
                          ),
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
