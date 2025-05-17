// listing_event.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ListingEvent extends Equatable {
  const ListingEvent();

  @override
  List<Object> get props => [];
}

class LoadListings extends ListingEvent {
  final String? location;
  final DateTimeRange? dateRange;

  const LoadListings({this.location, this.dateRange});
}
