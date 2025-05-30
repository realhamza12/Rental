// Updated listing_page.dart to display owner ratings

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rental_app/pages/profile_page.dart';
import 'list_car_screen.dart';
import 'past_rentals_screen.dart';
import 'car_model.dart';
import 'detail.dart';
import 'sidebar.dart';
import 'listing_bloc.dart';
import 'listing_event.dart';
import 'listing_state.dart';
import 'package:rental_app/pages/date_formatter.dart';
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

const List<String> karachiAreas = [
  'DHA',
  'Clifton',
  'Gulshan-e-Iqbal',
  'Nazimabad',
  'PECHS',
];

String? selectedLocation;
DateTimeRange? selectedDateRange;

class ListingPage extends StatelessWidget {
  const ListingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,

        primaryColor: const Color(0xFFCCFF00),
        fontFamily: 'Roboto',
      ),
      home: BlocProvider(
        create: (context) => ListingBloc()..add(LoadListings()),
        child: const ExplorePage(),
      ),
    );
  }
}

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SideBar(onClose: () => _scaffoldKey.currentState?.closeDrawer()),
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
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Color(0xFF201E25),
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8,
              ),
              child: Row(
                children: [
                  // 📍 Location Filter
                  Expanded(
                    child: Container(
                      height: 49,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: const Color(0xFF201E25),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              3,
                              3,
                              3,
                            ).withOpacity(0.2), // Shadow color
                            spreadRadius: 0.5,
                            blurRadius: 12,
                            offset: Offset(0, 4), // changes position of shadow
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedLocation,
                          hint: const Text(
                            'Select Location',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color.fromARGB(255, 189, 188, 188),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          items:
                              karachiAreas.map((area) {
                                return DropdownMenuItem(
                                  value: area,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        area,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedLocation = value;
                            });

                            // 🟢 Fetch filtered listings by selected location only
                            context.read<ListingBloc>().add(
                              LoadListings(location: selectedLocation),
                            );
                          },
                          dropdownColor: Colors.black,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 📅 Date Range Filter
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFE7FE54),
                                  onPrimary: Colors.black,
                                  surface: Color(0xFF282931),
                                  onSurface: Colors.white,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDateRange = picked;
                          });

                          // ✅ Trigger filter with BLoC
                          context.read<ListingBloc>().add(
                            LoadListings(
                              location:
                                  selectedLocation, // Send current location too
                              dateRange: selectedDateRange,
                            ),
                          );
                        }
                      },
                      child: SizedBox(
                        height: 49,
                        width: 200,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            color: Color(0xFF201E25),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(
                                  255,
                                  3,
                                  3,
                                  3,
                                ).withOpacity(0.2), // Shadow color
                                spreadRadius: 0.5,
                                blurRadius: 12,
                                offset: Offset(
                                  0,
                                  4,
                                ), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                color: Color.fromARGB(255, 255, 255, 255),
                                size: 18,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  selectedDateRange == null
                                      ? 'Select Dates'
                                      : '${selectedDateRange!.start.toLocal().toString().split(' ')[0]} → ${selectedDateRange!.end.toLocal().toString().split(' ')[0]}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color.fromARGB(255, 189, 188, 188),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedLocation = null;
                        selectedDateRange = null;
                      });

                      // Reset filter in BLoC
                      context.read<ListingBloc>().add(LoadListings());
                    },
                    child: const Text(
                      'Reset Filters',
                      style: TextStyle(
                        color: Color.fromARGB(69, 255, 255, 255),
                        fontWeight: FontWeight.w200,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Car list
            Expanded(
              child: BlocBuilder<ListingBloc, ListingState>(
                builder: (context, state) {
                  if (state is ListingLoading) {
                    return Center(
                      child: TweenAnimationBuilder(
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
                    );
                  } else if (state is ListingError) {
                    return Center(
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
                            state.message,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              final bloc = BlocProvider.of<ListingBloc>(
                                context,
                              );
                              bloc.add(
                                LoadListings(
                                  location: selectedLocation,
                                  dateRange: selectedDateRange,
                                ),
                              );
                            },

                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCCFF00),
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is ListingLoaded) {
                    final cars = state.cars;
                    if (cars.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_off,
                              color: Colors.grey,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No cars found based on your location at the moment.',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                BlocProvider.of<ListingBloc>(
                                  context,
                                ).add(LoadListings());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        BlocProvider.of<ListingBloc>(
                          context,
                        ).add(LoadListings());
                      },
                      color: const Color(0xFFCCFF00),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cars.length,
                        itemBuilder: (context, index) {
                          final car = cars[index];
                          return CarCard(car: car);
                        },
                      ),
                    );
                  } else {
                    return const Center(child: Text('Unknown state'));
                  }
                },
              ),
            ),

            // Bottom Navigation
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(
                      0.3,
                    ), // Semi-transparent for frosted effect
                    
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
              ),
            ),
          ],
        ),
      ),
    );
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
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    }
  }
}

class CarCard extends StatelessWidget {
  final Car car;

  const CarCard({super.key, required this.car});

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
          color: Color(0xFF201E25),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(
                255,
                0,
                0,
                0,
              ).withOpacity(0.2), // Shadow color
              spreadRadius: 0.7,
              blurRadius: 14,
              offset: Offset(0, 4), // changes position of shadow
            ),
          ],
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
                  car.images.isNotEmpty &&
                          car.images[0].toString().startsWith('http')
                      ? Image.network(
                        car.images[0],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        car.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(children: [
                          
                        ],
                      ),
                    ],
                  ),
                  Text(
                    car.type,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(132, 255, 255, 255),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Price
                  Row(
                    children: [
                      Text(
                        '\Rs. ${car.price.toInt()}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(height: 4.5),
                          Text(
                            '/day',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Rating and Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        car.location,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.event_seat,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${car.seater} seats',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.access_time,
                        color: Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${car.days} days',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Seater and Days
                  const SizedBox(height: 12),

                  // Owner Info with Rating
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[700],
                        child: Text(
                          car.ownerInitials.isNotEmpty
                              ? car.ownerInitials.toUpperCase()
                              : car.ownerName.isNotEmpty
                              ? car.ownerName[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(car.ownerId)
                                  .get(),
                          builder: (context, snapshot) {
                            // Default owner info
                            Widget ownerInfo = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  car.ownerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );

                            // If we have owner data from Firestore
                            if (snapshot.hasData && snapshot.data != null) {
                              final ownerData =
                                  snapshot.data!.data()
                                      as Map<String, dynamic>?;

                              if (ownerData != null) {
                                final ownerRating =
                                    ownerData['average_rating'] ?? 0.0;
                                final totalRatings =
                                    ownerData['total_ratings'] ?? 0;

                                // Enhanced owner info with rating from Firestore
                                ownerInfo = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      car.ownerName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Color(0xFFCCFF00),
                                          size: 14,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          "${(ownerRating as num).toDouble().toStringAsFixed(1)} (${totalRatings})",
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
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
