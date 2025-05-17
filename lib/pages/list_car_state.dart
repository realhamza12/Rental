// list_car_state.dart

import 'package:equatable/equatable.dart';

abstract class ListCarState extends Equatable {
  const ListCarState();

  @override
  List<Object?> get props => [];
}

class ListCarInitial extends ListCarState {}

class ListCarLoading extends ListCarState {}

class ListCarSuccess extends ListCarState {
  final String carId;

  const ListCarSuccess({required this.carId});

  @override
  List<Object?> get props => [carId];
}

class ListCarError extends ListCarState {
  final String message;

  const ListCarError({required this.message});

  @override
  List<Object?> get props => [message];
}
