import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'navigation_helper.dart';
import 'sidebar.dart';

GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class PastRentalsScreen extends StatefulWidget {
  const PastRentalsScreen({super.key});

  @override
  State<PastRentalsScreen> createState() => _PastRentalsScreenState();
}

class _PastRentalsScreenState extends State<PastRentalsScreen> {
  bool _isLoading = true;
  bool _isRatingLoading = false;
  List<Map<String, dynamic>> _pastRentals = [];
  String? _errorMessage;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _fetchPastRentals();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Navigation handling
  void _handleNavigation(int index) {
    NavigationHelper.handleBottomNavigation(context, index);
  }

  Future<void> _fetchPastRentals() async {
    if (_disposed) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('📱 Fetching past rentals from Firestore...');

      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final String userId = user.uid;
      print('📱 Current user ID: $userId');

      // Get bookings collection from Firestore - simplified query to avoid index issues
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('bookings')
              .where('bookedBy', isEqualTo: userId)
              .get();

      print('📱 Found ${snapshot.docs.length} bookings');

      if (_disposed) return;

      if (snapshot.docs.isEmpty) {
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

          // Skip if this isn't a completed booking
          if (data['carId'] == null) {
            continue;
          }

          // Get car details for this booking
          DocumentSnapshot? carDoc;
          try {
            carDoc =
                await FirebaseFirestore.instance
                    .collection('cars')
                    .doc(data['carId'])
                    .get();

            if (!carDoc.exists) {
              print('📱 Car document not found for ID: ${data['carId']}');
              continue; // Skip this booking if car doesn't exist
            }
          } catch (e) {
            print('📱 Error fetching car document: $e');
            continue; // Skip this booking if there's an error fetching the car
          }

          if (_disposed) return;

          // Get car data
          final carData = carDoc.data() as Map<String, dynamic>;
          final carImages = carData['images'] as List<dynamic>? ?? [];

          // Get owner data if available
          String ownerId = carData['ownerId'] ?? data['ownerId'] ?? '';
          String ownerName = carData['ownerName'] ?? 'Unknown Owner';

          // Get dates from car document's availableFrom and availableTo fields
          DateTime startDate = DateTime.now();
          DateTime endDate = DateTime.now().add(Duration(days: 3));

          try {
            if (carData['availableFrom'] != null &&
                carData['availableFrom'] is Timestamp) {
              startDate = (carData['availableFrom'] as Timestamp).toDate();
              print('📱 Found availableFrom date: $startDate');
            }

            if (carData['availableTo'] != null &&
                carData['availableTo'] is Timestamp) {
              endDate = (carData['availableTo'] as Timestamp).toDate();
              print('📱 Found availableTo date: $endDate');
            }
          } catch (e) {
            print('📱 Error parsing dates: $e');
            // Use default dates if there's an error
          }

          // Create rental object with combined booking and car data
          final Map<String, dynamic> rental = {
            'id': doc.id,
            'carId': data['carId'],
            'carName': data['carName'] ?? carData['name'] ?? 'Unknown Car',
            'location':
                carData['location'] ?? data['location'] ?? 'Unknown Location',
            'startDate': startDate,
            'endDate': endDate,
            'rating': data['rating'] ?? 0,
            'totalAmount':
                (data['price'] ?? carData['price'] ?? 0) *
                (data['days'] ?? carData['days'] ?? 1),
            'imageUrl':
                carImages.isNotEmpty
                    ? carImages[0]
                    : 'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d',
            'isRated': data['isRated'] ?? false,
            'ownerId': ownerId,
            'ownerName': ownerName,
          };

          rentals.add(rental);
          print(
            '📱 Added rental: ${rental['carName']} from ${DateFormat('dd MMM').format(rental['startDate'])} to ${DateFormat('dd MMM').format(rental['endDate'])}',
          );
        } catch (e) {
          print('📱 Error parsing rental document: $e');
        }
      }

      if (_disposed) return;

      setState(() {
        _pastRentals = rentals;
        _isLoading = false;
      });

      print('📱 Updated state with ${rentals.length} rentals');
    } catch (e) {
      print('📱 Error fetching rentals: $e');
      if (!_disposed) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading past rentals: $e';
        });
      }
    }
  }

  // Update rating in Firestore for both booking and owner
  Future<void> _updateRating(
    String rentalId,
    String ownerId,
    int newRating,
  ) async {
    if (_disposed) return;

    try {
      setState(() {
        _isRatingLoading = true;
      });

      print(
        '📱 Updating rating to $newRating for booking $rentalId and owner $ownerId',
      );

      // Start a batch write to ensure all operations succeed or fail together
      final batch = FirebaseFirestore.instance.batch();

      // 1. Update the rating in the booking document
      final bookingRef = FirebaseFirestore.instance
          .collection('bookings')
          .doc(rentalId);
      batch.update(bookingRef, {
        'rating': newRating,
        'isRated': true,
        'ratedAt': FieldValue.serverTimestamp(),
      });

      // 2. Get the current user for the rating
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // 3. Add the rating to the owner's ratings subcollection
      final ratingRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .collection('ratings')
              .doc();

      batch.set(ratingRef, {
        'rating': newRating, // Make sure this is the actual rating value
        'fromUserId': user.uid,
        'bookingId': rentalId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Commit the batch operations
      await batch.commit();

      // Now update the user's average rating in a separate operation
      // First get all ratings for this owner
      final ratingsSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(ownerId)
              .collection('ratings')
              .get();

      // Calculate the new average
      int totalRatings = ratingsSnapshot.docs.length;
      double sumRatings = 0;

      for (var doc in ratingsSnapshot.docs) {
        final ratingValue = doc.data()['rating'];
        if (ratingValue is num) {
          sumRatings += ratingValue.toDouble();
        }
      }

      double averageRating = totalRatings > 0 ? sumRatings / totalRatings : 0;

      print(
        '📱 Calculated new average rating: $averageRating from $totalRatings ratings',
      );

      // Update the owner's document with the new average rating
      await FirebaseFirestore.instance.collection('users').doc(ownerId).update({
        'average_rating': averageRating,
        'total_ratings': totalRatings,
      });

      // 6. Update local state
      if (!_disposed) {
        setState(() {
          for (int i = 0; i < _pastRentals.length; i++) {
            if (_pastRentals[i]['id'] == rentalId) {
              _pastRentals[i]['rating'] = newRating;
              _pastRentals[i]['isRated'] = true;
              break;
            }
          }
          _isRatingLoading = false;
        });
      }

      // 7. Show a success message
      if (!_disposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Thank you! You rated the owner $newRating stars'),
            backgroundColor: Theme.of(context).primaryColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('📱 Error updating rating: $e');
      // Show an error message
      if (!_disposed) {
        setState(() {
          _isRatingLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating rating: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          key: _scaffoldKey,
          drawer: SideBar(
            onClose: () => _scaffoldKey.currentState?.closeDrawer(),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => _scaffoldKey.currentState?.openDrawer(),
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: const Icon(Icons.menu, size: 20),
                        ),
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

                          final firstName =
                              userData['first_name'] as String? ?? '';
                          final lastName =
                              userData['last_name'] as String? ?? '';
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
                      fontSize: 16,
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                                'assets/images/wheel.png',
                                width: 80,
                                height: 80,
                                opacity: AlwaysStoppedAnimation(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                          ],
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
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
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
                                    color: const Color.fromARGB(
                                      255,
                                      37,
                                      37,
                                      37,
                                    ),
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
                                                color: Color.fromARGB(
                                                  255,
                                                  219,
                                                  219,
                                                  219,
                                                ),
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
                                                  color: Color.fromARGB(
                                                    255,
                                                    219,
                                                    219,
                                                    219,
                                                  ),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    rental['location'],
                                                    style: const TextStyle(
                                                      color: Color.fromARGB(
                                                        255,
                                                        219,
                                                        219,
                                                        219,
                                                      ),
                                                      fontSize: 14,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
                                                  color: Color.fromARGB(
                                                    255,
                                                    219,
                                                    219,
                                                    219,
                                                  ),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '$startDate - $endDate',
                                                  style: const TextStyle(
                                                    color: Color.fromARGB(
                                                      255,
                                                      219,
                                                      219,
                                                      219,
                                                    ),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),

                                            // Owner info
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.person,
                                                  color: Color.fromARGB(
                                                    255,
                                                    219,
                                                    219,
                                                    219,
                                                  ),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Owner: ${rental['ownerName']}',
                                                  style: const TextStyle(
                                                    color: Color.fromARGB(
                                                      255,
                                                      219,
                                                      219,
                                                      219,
                                                    ),
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Rating Stars with label
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Rate the owner:',
                                                  style: TextStyle(
                                                    color: Color.fromARGB(
                                                      255,
                                                      219,
                                                      219,
                                                      219,
                                                    ),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: List.generate(
                                                    5,
                                                    (
                                                      starIndex,
                                                    ) => GestureDetector(
                                                      onTap: () {
                                                        // Update rating when star is tapped
                                                        _updateRating(
                                                          rental['id'],
                                                          rental['ownerId'],
                                                          starIndex + 1,
                                                        );
                                                      },
                                                      child: Icon(
                                                        starIndex <
                                                                (rental['rating'] ??
                                                                    0)
                                                            ? Icons.star
                                                            : Icons.star_border,
                                                        color: const Color(
                                                          0xFFCCFF00,
                                                        ),
                                                        size: 24,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),

                                            // Total Amount
                                            Text(
                                              'Total: \$${rental['totalAmount']}',
                                              style: const TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  219,
                                                  219,
                                                  219,
                                                ),
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
                                            width: 170,
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
                                              print(
                                                'Error loading image: $error',
                                              );
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
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.3,
                    ), // semi-transparent background
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
                              style: TextStyle(
                                color: Colors.grey,
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
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
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
              ),
            ),
          ],
        ),
         ),
        
    ];
  }
}
