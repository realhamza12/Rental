// Updated detail.dart to display owner ratings

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'car_model.dart';
import 'booking_confirmation_screen.dart';
import 'package:rental_app/pages/date_formatter.dart';
import 'navigation_helper.dart';
import 'car_detail_bloc.dart';
import 'car_detail_event.dart';
import 'car_detail_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CarDetailScreen extends StatefulWidget {
  final String carId;

  const CarDetailScreen({super.key, required this.carId});

  @override
  State<CarDetailScreen> createState() => _CarDetailScreenState();
}

class _CarDetailScreenState extends State<CarDetailScreen> {
  bool _isLoading = false;
  String _loadingMessage = "";
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _showBookingConfirmation(BuildContext context, Car car) {
    print("📱 Showing booking confirmation modal");
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 14, 14, 14),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Confirm Booking',
                  style: TextStyle(
                    fontSize: 28,
                    // fontWeight: FontWeight.bold,
                    fontFamily: "Conthrax",
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 0),
                Text(
                  'Are you sure you want to book the ${car.name} ${car.type}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(150, 255, 255, 255),
                  ),
                ),
                const SizedBox(height: 26),
                Text(
                  'Total: \RS. ${(car.price * car.days).toInt()} for ${car.days} days',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        print("❌ Cancel button pressed");
                        Navigator.pop(context); // Close the modal
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 54,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        print("✅ Confirm button pressed");
                        Navigator.pop(context); // Close the modal

                        // Start the booking process
                        _startBookingProcess(car);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 54,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Start the booking process
  void _startBookingProcess(Car car) {
    if (_disposed) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = "Processing your booking...";
    });

    // Process the booking in the background
    _processBooking(car)
        .then((_) {
          // Navigate to the booking confirmation screen
          if (mounted && !_disposed) {
            setState(() {
              _isLoading = false;
            });

            // Navigate to the booking confirmation screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingConfirmationScreen(car: car),
              ),
            );
          }
        })
        .catchError((error) {
          if (mounted && !_disposed) {
            setState(() {
              _isLoading = false;
            });

            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Booking failed: $error')));
          }
        });
  }

  // Process the booking in the background
  Future<void> _processBooking(Car car) async {
    print("🚀 Processing booking");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to book a car');
    }

    // First check if the car is available without a transaction
    final carRef = FirebaseFirestore.instance.collection('cars').doc(car.id);
    final carDoc = await carRef.get();

    if (!carDoc.exists) {
      throw Exception('Car no longer exists');
    }

    final carData = carDoc.data() as Map<String, dynamic>;
    final isAvailable = carData['isAvailable'] ?? true;

    if (!isAvailable) {
      throw Exception('This car has already been booked');
    }

    // Create booking document
    final bookingRef = FirebaseFirestore.instance.collection('bookings').doc();
    final timestamp = Timestamp.now();

    await bookingRef.set({
      'id': bookingRef.id,
      'carId': car.id,
      'carName': car.name,
      'bookedBy': user.uid,
      'ownerId': car.ownerId,
      'timestamp': timestamp,
      'price': car.price,
      'days': car.days,
      'startDate': carData['availableFrom'],
      'endDate': carData['availableTo'],
    });

    // Mark car as unavailable
    await carRef.update({
      'isAvailable': false,
      'bookedBy': user.uid,
      'bookingId': bookingRef.id,
      'bookingTimestamp': timestamp,
    });

    // Create notification for car owner
    if (car.ownerId.isNotEmpty) {
      final notificationRef =
          FirebaseFirestore.instance
              .collection('users')
              .doc(car.ownerId)
              .collection('notifications')
              .doc();

      await notificationRef.set({
        'type': 'booking',
        'message':
            "Your car '${car.name}' has been booked by '${car.ownerName}' from email '${user.email}.",
        'carId': car.id,
        'seen': false,
        'timestamp': timestamp,
      });
    }

    print("✅ Booking completed successfully");
    return;
  }

  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => CarDetailBloc()..add(LoadCarDetail(carId: widget.carId)),
      child: Stack(
        children: [
          Scaffold(
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
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Icon(Icons.arrow_back, size: 20),
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

                  // Main content
                  Expanded(
                    child: BlocBuilder<CarDetailBloc, CarDetailState>(
                      builder: (context, state) {
                        if (state is CarDetailLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (state is CarDetailError) {
                          return Center(child: Text(state.message));
                        } else if (state is CarDetailLoaded) {
                          final car = state.car;
                          return SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Car Images Carousel
                                  if (car.images.isNotEmpty)
                                    Column(
                                      children: [
                                        CarouselSlider(
                                          options: CarouselOptions(
                                            height: 250,
                                            viewportFraction: 1.0,
                                            enlargeCenterPage: false,
                                            onPageChanged: (index, reason) {
                                              setState(() {
                                                _currentImageIndex = index;
                                              });
                                            },
                                          ),
                                          items:
                                              car.images.map((imageUrl) {
                                                return Builder(
                                                  builder: (
                                                    BuildContext context,
                                                  ) {
                                                    return ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16.0,
                                                          ),
                                                      child: Image.network(
                                                        imageUrl,
                                                        height: 250,
                                                        width: double.infinity,
                                                        fit: BoxFit.cover,
                                                        loadingBuilder: (
                                                          context,
                                                          child,
                                                          loadingProgress,
                                                        ) {
                                                          if (loadingProgress ==
                                                              null) {
                                                            return child;
                                                          }
                                                          return Center(
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
                                                            ),
                                                          );
                                                        },
                                                        errorBuilder: (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Container(
                                                            height: 250,
                                                            width:
                                                                double.infinity,
                                                            color:
                                                                Colors
                                                                    .grey[800],
                                                            child: const Center(
                                                              child: Icon(
                                                                Icons.error,
                                                                size: 50,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                );
                                              }).toList(),
                                        ),
                                        const SizedBox(height: 8),
                                        // Dots indicator for carousel
                                        if (car.images.length > 1)
                                          DotsIndicator(
                                            dotsCount: car.images.length,
                                            position:
                                                _currentImageIndex.toDouble(),
                                            decorator: DotsDecorator(
                                              activeColor:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                              size: const Size.square(8.0),
                                              activeSize: const Size(16.0, 8.0),
                                              activeShape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          5.0,
                                                        ),
                                                  ),
                                            ),
                                          ),
                                      ],
                                    )
                                  else
                                    // Fallback image if no images available
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16.0),
                                      child: Container(
                                        height: 250,
                                        width: double.infinity,
                                        color: Colors.grey[800],
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.directions_car,
                                                size: 64,
                                                color: Colors.grey,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "No images available",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 16),

                                  // Car Name
                                  Text(
                                    car.name,
                                    style: const TextStyle(
                                      fontSize: 36,

                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    car.type,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(131, 255, 255, 255),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Price
                                  Row(
                                    children: [
                                      Text(
                                        '\$${car.price.toInt()}',
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          SizedBox(height: 8.5),
                                          Text(
                                            '/day',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Color.fromARGB(
                                                131,
                                                255,
                                                255,
                                                255,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Rating and Location
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFFCCFF00),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          car.rating.toStringAsFixed(1),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          car.location,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(
                                          Icons.event_seat,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${car.seater} seats',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Icon(
                                          Icons.access_time,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${car.days} days',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          DateFormatter.formatDateRange(
                                            car.availableFrom,
                                            car.availableTo,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Owner Info with Rating
                                  FutureBuilder<DocumentSnapshot>(
                                    future:
                                        FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(car.ownerId)
                                            .get(),
                                    builder: (context, snapshot) {
                                      // Default owner info
                                      Widget ownerInfo = Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: Colors.grey[700],
                                            child: Text(
                                              car.ownerInitials.isNotEmpty
                                                  ? car.ownerInitials
                                                      .toUpperCase()
                                                  : car.ownerName.isNotEmpty
                                                  ? car.ownerName[0]
                                                      .toUpperCase()
                                                  : "?",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                car.ownerName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.star,
                                                    color: Color(0xFFCCFF00),
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    car.rating.toStringAsFixed(
                                                      1,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      );

                                      // If we have owner data from Firestore
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        final ownerData =
                                            snapshot.data!.data()
                                                as Map<String, dynamic>?;

                                        if (ownerData != null) {
                                          final firstName =
                                              ownerData['first_name']
                                                  as String? ??
                                              '';
                                          final lastName =
                                              ownerData['last_name']
                                                  as String? ??
                                              '';
                                          final initials =
                                              (firstName.isNotEmpty
                                                  ? firstName[0]
                                                  : '') +
                                              (lastName.isNotEmpty
                                                  ? lastName[0]
                                                  : '');
                                          final ownerRating =
                                              ownerData['average_rating'] ??
                                              0.0;
                                          final totalRatings =
                                              ownerData['total_ratings'] ?? 0;

                                          // Enhanced owner info with rating from Firestore
                                          ownerInfo = Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 24,
                                                backgroundColor:
                                                    Colors.grey[700],
                                                child: Text(
                                                  initials.toUpperCase(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    "$firstName $lastName",
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Color(
                                                          0xFFCCFF00,
                                                        ),
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        "${(ownerRating as num).toDouble().toStringAsFixed(1)} (${totalRatings} ${totalRatings == 1 ? 'rating' : 'ratings'})",
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                        }
                                      }

                                      return ownerInfo;
                                    },
                                  ),

                                  const SizedBox(height: 20),

                                  // Rules and Regulations
                                  const Text(
                                    'Car Rental Rules and Regulations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  // Dynamic Rules from Firebase
                                  if (car.rules.isNotEmpty)
                                    Column(
                                      children: List.generate(
                                        car.rules.length,
                                        (index) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${index + 1}.',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      car.rules[index]['title'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      car.rules[index]['description'] ??
                                                          '',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    // Fallback static rules if none in Firebase
                                    Column(
                                      children: [
                                        // Rule 1
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '1.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'Valid Driver\'s License:',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Renter must possess a valid driver\'s license. A copy must be submitted before rental begins.',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 8),

                                        // Rule 2
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '2.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'Minimum Age Requirement:',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Renters must be at least 21 years old. Additional fees may apply for drivers under 25.',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '3.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'No Smoking Policy:',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'Smoking inside the rental vehicle is strictly prohibited. Violation of this policy will result in a cleaning fee of up to RS. 2000.',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '4.',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: const [
                                                  Text(
                                                    'Fuel Policy:',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    'The car must be returned with the same fuel level as at the time of pickup. Failure to do so will result in additional refueling charges.',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                  const SizedBox(height: 20),

                                  // Book Now Button
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: 120,
                                        height: 40,
                                        child: FloatingActionButton.extended(
                                          onPressed: () {
                                            _showBookingConfirmation(
                                              context,
                                              car,
                                            );
                                          },
                                          backgroundColor: Colors.white,
                                          foregroundColor: Colors.black,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ), // 👈 Increase for more roundness
                                          ),
                                          label: const Text(
                                            'Book Now',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else {
                          return const Center(child: Text('Unknown state'));
                        }
                      },
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
                          onTap:
                              () => NavigationHelper.handleBottomNavigation(
                                context,
                                0,
                              ),
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
                          onTap:
                              () => NavigationHelper.handleBottomNavigation(
                                context,
                                1,
                              ),
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
                          onTap:
                              () => NavigationHelper.handleBottomNavigation(
                                context,
                                2,
                              ),
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
                                style: TextStyle(
                                  color: Colors.grey,
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
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFCCFF00),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
