

import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfile extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String firstName;
  final String lastName;
  final String phone;
  final String address;

  const UpdateProfile({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
  });

  @override
  List<Object?> get props => [firstName, lastName, phone, address];
}

class SignOutRequested extends ProfileEvent {}