import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'date_formatter.dart';
import 'navigation_helper.dart';
import 'sidebar.dart';
import 'list_car_screen.dart';

class MyCarsScreen extends StatefulWidget {
  const MyCarsScreen({super.key});

  @override
  State<MyCarsScreen> createState() => _MyCarsScreenState();
}

class _MyCarsScreenState extends State<MyCarsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  List<Map<String, dynamic>> _myCars = [];
  String? _errorMessage;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _fetchMyCars();
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

  Future<void> _fetchMyCars() async {
    if (_disposed) return;

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('📱 Fetching my cars from Firestore...');

      // Get current user ID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final String userId = user.uid;
      print('📱 Current user ID: $userId');

      // Get cars collection from Firestore where ownerId matches current user
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance
              .collection('cars')
              .where('ownerId', isEqualTo: userId)
              .get();

      print('📱 Found ${snapshot.docs.length} cars');

      if (_disposed) return;

      if (snapshot.docs.isEmpty) {
        setState(() {
          _myCars = [];
          _isLoading = false;
        });
        return;
      }

      // Convert documents to car objects
      final List<Map<String, dynamic>> cars = [];

      for (var doc in snapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;

          // Create car object
          final Map<String, dynamic> car = {
            'id': doc.id,
            'name': data['name'] ?? 'Unknown Car',
            'type': data['type'] ?? '',
            'price': data['price'] ?? 0,
            'location': data['location'] ?? 'Unknown Location',
            'rating': data['rating'] ?? 0.0,
            'seater': data['seater'] ?? 4,
            'days': data['days'] ?? 1,
            'kms': data['kms'] ?? 0,
            'isAvailable': data['isAvailable'] ?? true,
            'images': List<String>.from(data['images'] ?? []),
            'availableFrom':
                data['availableFrom'] != null
                    ? (data['availableFrom'] as Timestamp).toDate()
                    : DateTime.now(),
            'availableTo':
                data['availableTo'] != null
                    ? (data['availableTo'] as Timestamp).toDate()
                    : DateTime.now().add(const Duration(days: 7)),
          };

          cars.add(car);
          print('📱 Added car: ${car['name']}');
        } catch (e) {
          print('📱 Error parsing car document: $e');
        }
      }

      if (_disposed) return;

      setState(() {
        _myCars = cars;
        _isLoading = false;
      });

      print('📱 Updated state with ${cars.length} cars');
    } catch (e) {
      print('📱 Error fetching cars: $e');
      if (!_disposed) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading your cars: $e';
        });
      }
    }
  }

  Future<void> _removeCar(String carId) async {
    try {
      // Show confirmation dialog
      final bool confirm =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text('Remove Car'),
                  content: const Text(
                    'Are you sure you want to remove this car? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirm) return;

      // Show loading indicator
      setState(() {
        _isLoading = true;
      });

      // Delete the car from Firestore
      await FirebaseFirestore.instance.collection('cars').doc(carId).delete();

      // Update the local state
      setState(() {
        _myCars.removeWhere((car) => car['id'] == carId);
        _isLoading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Car removed successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error removing car: $e');
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing car: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // My Cars Title
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
                'My Listed Cars',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFFCCFF00),
                  fontFamily: 'BeVietnamPro',
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Add Car Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListCarScreen(),
                    ),
                  ).then((_) => _fetchMyCars()); // Refresh after returning
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add New Car',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

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
                                opacity: const AlwaysStoppedAnimation(0.5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Fetching your Cars',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
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
                              onPressed: _fetchMyCars,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                      : _myCars.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.directions_car,
                              color: Colors.grey,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'You haven\'t listed any cars yet',
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
                                ).then((_) => _fetchMyCars());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFCCFF00),
                                foregroundColor: Colors.black,
                              ),
                              child: const Text('List a Car'),
                            ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _fetchMyCars,
                        color: const Color(0xFFCCFF00),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _myCars.length,
                          itemBuilder: (context, index) {
                            final car = _myCars[index];
                            return MyCarCard(
                              car: car,
                              onRemove: () => _removeCar(car['id']),
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

class MyCarCard extends StatelessWidget {
  final Map<String, dynamic> car;
  final VoidCallback onRemove;

  const MyCarCard({super.key, required this.car, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final bool isAvailable = car['isAvailable'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: isAvailable ? 0 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Car Image with Status Badge
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child:
                    car['images'] != null &&
                            car['images'].isNotEmpty &&
                            car['images'][0].toString().startsWith('http')
                        ? Image.network(
                          car['images'][0],
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey[800],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Color(0xFFCCFF00),
                                      ),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return Container(
                              height: 180,
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
                          height: 180,
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

              // Status Badge
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isAvailable ? const Color(0xFFCCFF00) : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAvailable ? 'Available' : 'Booked',
                    style: TextStyle(
                      color: isAvailable ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Car Name and Type
                Text(
                  car['name'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  car['type'] ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 12),

                // Price
                Text(
                  '\Rs. ${car['price'].toInt()}/day',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCCFF00),
                  ),
                ),

                const SizedBox(height: 12),

                // Location and Date Range
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        car['location'] ?? 'Unknown Location',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.date_range, color: Colors.grey, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatDateRange(
                        car['availableFrom'],
                        car['availableTo'],
                      ),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Edit Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Implement edit functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Edit functionality coming soon'),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Edit'),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Remove Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isAvailable ? onRemove : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        child: const Text('Remove'),
                      ),
                    ),
                  ],
                ),

                // Show message if car is booked
                if (!isAvailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'This car is currently booked and cannot be removed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[300],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
