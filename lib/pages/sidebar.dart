// sidebar.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'log-in-page.dart';
import 'past_rentals_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rental_app/pages/notifications_screen.dart';

final userId = FirebaseAuth.instance.currentUser?.uid;

class SideBar extends StatelessWidget {
  final Function onClose;

  const SideBar({super.key, required this.onClose});

  Future<void> _logout(BuildContext context) async {
    try {
      // Sign out from Firebase Auth
      await FirebaseAuth.instance.signOut();

      // Navigate to login screen and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error logging out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color.fromARGB(255, 14, 14, 14),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 24,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(FirebaseAuth.instance.currentUser?.uid)
                                  .get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Text(
                                'Loading...',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 183, 183, 183),
                                ),
                              );
                            }

                            final userData =
                                snapshot.data!.data() as Map<String, dynamic>?;

                            if (userData == null) {
                              return const Text(
                                'No data',
                                style: TextStyle(color: Colors.white),
                              );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userData['first_name'] ?? 'No Name',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  userData['email'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Color.fromARGB(206, 255, 255, 255),
                    ),
                    onPressed: () => onClose(),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.home,
                        title: 'Home',
                        textColor: Color.fromARGB(206, 255, 255, 255),
                        iconColor: Color.fromARGB(206, 255, 255, 255),
                        onTap: () {
                          onClose();
                          // Already on home page
                        },
                      ),
                      SizedBox(height: 10),

                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .collection('notifications')
                                .where('seen', isEqualTo: false)
                                .snapshots(),
                        builder: (context, snapshot) {
                          final hasUnseen =
                              snapshot.hasData &&
                              snapshot.data!.docs.isNotEmpty;

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop(); // Close sidebar
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const NotificationsScreen(),
                                    ),
                                  );
                                });
                              },

                              child: ListTile(
                                leading: Stack(
                                  children: [
                                    const Icon(
                                      Icons.notifications,
                                      color: Color.fromARGB(206, 255, 255, 255),
                                    ),
                                    if (hasUnseen)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFFCCFF00),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: const Text(
                                  'Notifications',
                                  style: TextStyle(
                                    color: Color.fromARGB(206, 255, 255, 255),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 10),
                      _buildMenuItem(
                        context,
                        icon: Icons.directions_car,
                        title: 'My Cars',
                        textColor: Color.fromARGB(206, 255, 255, 255),
                        iconColor: Color.fromARGB(206, 255, 255, 255),
                        onTap: () {
                          onClose();
                          // Navigate to My Cars page
                        },
                      ),
                      SizedBox(height: 10),
                      _buildMenuItem(
                        context,
                        icon: Icons.history,
                        title: 'Rental History',
                        textColor: Color.fromARGB(206, 255, 255, 255),
                        iconColor: Color.fromARGB(206, 255, 255, 255),
                        onTap: () {
                          onClose();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PastRentalsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // const Divider(color: Colors.grey),
                  Column(
                    children: [
                      const Divider(color: Color.fromARGB(68, 158, 158, 158)),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => _logout(context),
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w700, // increase text size
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFCCFF00,
                          ), // button background color
                          minimumSize: Size(230, 54), // width: 230, height: 54
                          padding: EdgeInsets.symmetric(
                            horizontal: 20,
                          ), // optional: padding inside button
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(
                  top: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    Color iconColor = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(title, style: TextStyle(color: textColor)),
      onTap: onTap,
    );
  }
}
