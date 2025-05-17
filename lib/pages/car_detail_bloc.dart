// car_detail_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'car_model.dart';
import 'car_detail_event.dart';
import 'car_detail_state.dart';

class CarDetailBloc extends Bloc<CarDetailEvent, CarDetailState> {
  CarDetailBloc() : super(CarDetailInitial()) {
    on<LoadCarDetail>((event, emit) async {
      emit(CarDetailLoading());
      try {
        final carDoc =
            await FirebaseFirestore.instance
                .collection('cars')
                .doc(event.carId)
                .get();

        if (!carDoc.exists) {
          emit(const CarDetailError(message: 'Car not found'));
          return;
        }

        final car = Car.fromFirestore(carDoc);
        emit(CarDetailLoaded(car: car));
      } catch (e) {
        emit(CarDetailError(message: 'Error loading car details: $e'));
      }
    });
  }
}
