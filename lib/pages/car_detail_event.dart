// car_detail_event.dart

import 'package:equatable/equatable.dart';

abstract class CarDetailEvent extends Equatable {
  const CarDetailEvent();

  @override
  List<Object> get props => [];
}

class LoadCarDetail extends CarDetailEvent {
  final String carId;

  const LoadCarDetail({required this.carId});

  @override
  List<Object> get props => [carId];
}
