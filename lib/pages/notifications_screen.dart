import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF181818),
        body: Center(
          child: Text(
            'You must be logged in to view notifications.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Notifications'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading notifications.',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No notifications yet.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          // ✅ Mark all as seen
          for (var doc in notifications) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['seen'] == false) {
              doc.reference.update({'seen': true});
            }
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final data = notifications[index].data() as Map<String, dynamic>;

              return ListTile(
                leading: const Icon(Icons.notifications, color: Colors.white),
                title: Text(
                  data['message'] ?? '',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  data['timestamp'] != null
                      ? (data['timestamp'] as Timestamp).toDate().toString()
                      : 'No timestamp',
                  style: const TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
