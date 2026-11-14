import 'package:flutter/foundation.dart';

@immutable
class Airport {
  const Airport({
    required this.code,
    required this.name,
    required this.city,
    required this.country,
    required this.countryCode,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.utcOffsetHours,
  });

  /// IATA code, e.g. "SIN".
  final String code;

  /// Airport name, e.g. "Changi".
  final String name;
  final String city;
  final String country;

  /// ISO 3166-1 alpha-2, used to pick the flag.
  final String countryCode;

  /// Group shown in the airport picker.
  final String region;
  final double latitude;
  final double longitude;
  final double utcOffsetHours;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return code.toLowerCase().contains(q) ||
        name.toLowerCase().contains(q) ||
        city.toLowerCase().contains(q) ||
        country.toLowerCase().contains(q);
  }

  @override
  bool operator ==(Object other) => other is Airport && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'Airport($code)';
}

@immutable
class Airline {
  const Airline({required this.code, required this.name});

  /// IATA designator, e.g. "AK".
  final String code;
  final String name;

  @override
  bool operator ==(Object other) => other is Airline && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
