import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'listing_page.dart';
import 'list_car_screen.dart';
import 'log-in-page.dart';
import 'profile_bloc.dart';
import 'profile_event.dart';
import 'profile_state.dart';
import 'auth_service.dart';
import 'dart:ui';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isEditing = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _populateControllers(Map<String, dynamic> userData) {
    _firstNameController.text = userData['first_name'] ?? '';
    _lastNameController.text = userData['last_name'] ?? '';
    _phoneController.text = userData['phone'] ?? '';
    _addressController.text = userData['address'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              ProfileBloc(authService: AuthService())..add(LoadProfile()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileSignedOut) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          } else if (state is ProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is ProfileLoaded) {
            _populateControllers(state.userData);
          }
        },
        builder: (context, state) {
          return Scaffold(
            key: _scaffoldKey,

            body: SafeArea(
              child: Column(
                children: [
                  // Header - same as listing page
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
                        const CircleAvatar(
                          radius: 18,
                          backgroundImage: AssetImage(
                            'assets/images/profile.jpg',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile content
                  Expanded(
                    child:
                        state is ProfileLoading
                            ? _buildLoadingIndicator()
                            : state is ProfileLoaded
                            ? _buildProfileContent(state.user, state.userData)
                            : state is ProfileError
                            ? _buildErrorView(state.message)
                            : const Center(child: Text('Unknown state')),
                  ),

                  // Bottom Navigation - same as listing page
                  ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 25,
                        sigmaY: 25,
                      ), // blur effect
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(
                            0.3,
                          ), // frosted glass effect
                          border: Border(
                            top: BorderSide(color: Colors.grey[900]!, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            GestureDetector(
                              onTap: () => _handleNavigation(0, context),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.home,
                                    color: Colors.grey,
                                    size: 24,
                                  ),
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
                              onTap: () => _handleNavigation(1, context),
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
                              onTap: () => _handleNavigation(2, context),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.account_circle_outlined,
                                    color: Color(0xFFCCFF00), // lime-ish color
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
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
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
          opacity: const AlwaysStoppedAnimation(0.5),
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<ProfileBloc>().add(LoadProfile());
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

  Widget _buildProfileContent(User user, Map<String, dynamic> userData) {
    final fullName =
        '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Center(
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/images/profile.jpg'),
                ),
                const SizedBox(height: 16),
                Text(
                  fullName.trim().isNotEmpty ? fullName : 'User',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? 'No email',
                  style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFCCFF00), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      userData['rating']?.toString() ?? '0.0',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Member since ${userData['memberSince']?.split('-')[0] ?? 'N/A'}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stats cards
          Row(
            children: [
              _buildStatCard(
                'Total Rentals',
                userData['totalRentals']?.toString() ?? '0',
                Icons.directions_car,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Favorite Cars',
                userData['favorites']?.toString() ?? '0',
                Icons.favorite,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Profile details section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF201E25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Profile Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!_isEditing)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFFCCFF00)),
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Profile fields
                _isEditing
                    ? _buildEditableProfileFields(context)
                    : _buildProfileFields(userData),

                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<ProfileBloc>().add(
                                UpdateProfile(
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  phone: _phoneController.text,
                                  address: _addressController.text,
                                ),
                              );

                              setState(() {
                                _isEditing = false;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFCCFF00),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                              // Reset controllers to original values
                              _populateControllers(userData);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[800],
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Account actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF201E25),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildActionTile('Payment Methods', Icons.payment, () {
                  // Navigate to payment methods
                }),
                _buildActionTile('Notifications', Icons.notifications, () {
                  // Navigate to notifications
                }),
                _buildActionTile('Privacy & Security', Icons.security, () {
                  // Navigate to privacy settings
                }),
                _buildActionTile('Help & Support', Icons.help, () {
                  // Navigate to help
                }),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFCCFF00),
                    foregroundColor: Colors.black,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: const Text('Log Out'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF201E25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFCCFF00), size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFields(Map<String, dynamic> userData) {
    final fullName =
        '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}';

    return Column(
      children: [
        _buildProfileField(
          'Name',
          fullName.trim().isNotEmpty ? fullName : 'Not set',
          Icons.person,
        ),
        _buildProfileField(
          'Email',
          FirebaseAuth.instance.currentUser?.email ?? 'Not set',
          Icons.email,
        ),
      ],
    );
  }

  Widget _buildEditableProfileFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildEditableField(
                _firstNameController,
                'First Name',
                Icons.person,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildEditableField(
                _lastNameController,
                'Last Name',
                Icons.person,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProfileField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: Colors.grey, size: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFCCFF00)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: isDestructive ? Colors.red : Colors.white,
              ),
            ),
            const Spacer(),
            if (!isDestructive)
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _handleNavigation(int index, BuildContext context) {
    if (index == 0) {
      // Navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ListingPage()),
      );
    } else if (index == 1) {
      // Navigate to List Car screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ListCarScreen()),
      );
    } else if (index == 2) {
      // Already on account page, do nothing
    }
  }
}
