import 'package:cloud_firestore/cloud_firestore.dart';

class Car {
  factory Car.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Car.fromMap(data, doc);
  }
  final String id;
  final String name;
  final String type;
  final double price;
  final double rating;
  final String location;
  final int days;
  final int seater; // Added seater field
  final String ownerInitials;
  final String ownerName;
  final List<String> images;
  final List<Map<String, dynamic>> rules;
  final String transmission;
  final DateTime? availableFrom;
  final DateTime? availableTo;
  final String ownerId;
  final bool isAvailable;
  final String? bookedBy;
  final String? bookingId;
  final int kms;

  Car({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.rating,
    required this.location,
    required this.days,
    required this.seater, // Added seater parameter
    required this.ownerInitials,
    required this.ownerName,
    required this.images,
    required this.rules,
    required this.transmission,
    required this.availableFrom,
    required this.availableTo,
    required this.ownerId,
    this.isAvailable = true,
    this.bookedBy,
    this.bookingId,
    required this.kms,
  });

  factory Car.fromMap(Map<String, dynamic> data, DocumentSnapshot doc) {
    return Car(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? 'Unknown Car',
      type: data['type'] ?? 'Unknown Type',
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
      seater: data['seater'] ?? 5, // Default to 4 seats if not specified
      ownerInitials: data['ownerInitials'] ?? '',
      ownerName: data['ownerName'] ?? 'Unknown Owner',
      images: List<String>.from(data['images'] ?? []),
      rules: List<Map<String, dynamic>>.from(data['rules'] ?? []),
      transmission: data['transmission'] ?? 'Automatic',
      availableFrom:
          data['availableFrom'] != null
              ? (data['availableFrom'] as Timestamp).toDate()
              : null,
      availableTo:
          data['availableTo'] != null
              ? (data['availableTo'] as Timestamp).toDate()
              : null,
      ownerId: data['ownerId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      bookedBy: data['bookedBy'],
      bookingId: data['bookingId'],
      kms: data['kms'] ?? 0,
    );
  }
}
