import 'package:equatable/equatable.dart';

import 'package:image_picker/image_picker.dart';

abstract class ListCarEvent extends Equatable {
  const ListCarEvent();

  @override
  List<Object?> get props => [];
}

class SubmitCarListing extends ListCarEvent {
  final String carName;
  final double rentalPrice;
  final String location;
  final String transmission;
  final String ownerName;
  final List<XFile> selectedImages;
  final List<Map<String, dynamic>> rules;
  final DateTime availableFrom;
  final DateTime availableTo;
  final bool isAvailable;
  final int seater; // Added seater field
  final int kms;
  final int days; // Added days field

  const SubmitCarListing({
    required this.carName,
    required this.rentalPrice,
    required this.location,
    required this.transmission,
    required this.ownerName,
    required this.selectedImages,
    required this.rules,
    required this.availableFrom,
    required this.availableTo,
    this.isAvailable = true,
    required this.kms,
    required this.seater, // Added seater parameter
    required this.days, // Added days parameter
  });

  @override
  List<Object?> get props => [
    carName,
    rentalPrice,
    location,
    transmission,
    ownerName,
    selectedImages,
    rules,
    availableFrom,
    availableTo,
    isAvailable,
    seater, // Added to props
    kms,
    days, // Added to props
  ];
}

class SelectCarImages extends ListCarEvent {
  final List<XFile>? images;

  const SelectCarImages({this.images});

  @override
  List<Object?> get props => [images];
}
