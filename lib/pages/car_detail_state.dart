// car_detail_state.dart

import 'package:equatable/equatable.dart';
import 'car_model.dart';

abstract class CarDetailState extends Equatable {
  const CarDetailState();

  @override
  List<Object?> get props => [];
}

class CarDetailInitial extends CarDetailState {}

class CarDetailLoading extends CarDetailState {}

class CarDetailLoaded extends CarDetailState {
  final Car car;

  const CarDetailLoaded({required this.car});

  @override
  List<Object?> get props => [car];
}

class CarDetailError extends CarDetailState {
  final String message;

  const CarDetailError({required this.message});

  @override
  List<Object?> get props => [message];
}
