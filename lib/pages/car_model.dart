// car_model.dart - Update this file to match your Firestore structure

import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  final String id;
  final String name;
  final String type;
  final double price;
  final double rating;
  final String location;
  final int days;
  final String ownerInitials;
  final String ownerName;
  final List<String> images;
  final List<Map<String, dynamic>> rules;
  final String transmission;

  Car({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.rating,
    required this.location,
    required this.days,
    required this.ownerInitials,
    required this.ownerName,
    required this.images,
    required this.rules,
    required this.transmission,
  });

  factory Car.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Print the document data for debugging
    print('Document data: $data');

    return Car(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? 'Unknown Car',
      type: data['type'] ?? data['transmission'] ?? 'Unknown Type',
      price:
          (data['price'] is int)
              ? (data['price'] as int).toDouble()
              : (data['price'] ?? 0.0),
      rating:
          (data['rating'] is int)
              ? (data['rating'] as int).toDouble()
              : (data['rating'] ?? 0.0),
      location: data['location'] ?? 'Unknown Location',
      days: data['days'] ?? 1,
      ownerInitials: data['ownerInitials'] ?? '',
      ownerName: data['ownerName'] ?? 'Unknown Owner',
      images: List<String>.from(data['images'] ?? []),
      rules: List<Map<String, dynamic>>.from(data['rules'] ?? []),
      transmission: data['transmission'] ?? 'Automatic',
    );
  }
}
