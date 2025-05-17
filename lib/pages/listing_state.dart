import 'package:equatable/equatable.dart';
import 'car_model.dart';

abstract class ListingState extends Equatable {
  const ListingState();

  @override
  List<Object> get props => [];
}

class ListingInitial extends ListingState {}

class ListingLoading extends ListingState {}

class ListingLoaded extends ListingState {
  final List<Car> cars;

  const ListingLoaded({required this.cars});

  @override
  List<Object> get props => [cars];
}

class ListingError extends ListingState {
  final String message;

  const ListingError({required this.message});

  @override
  List<Object> get props => [message];
}
