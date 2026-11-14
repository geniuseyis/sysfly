import 'package:flutter/foundation.dart';

/// Form of address printed on the ticket, as airlines such as Turkish
/// Airlines ask for it at booking.
enum PassengerTitle {
  mr('Mr'),
  ms('Ms');

  const PassengerTitle(this.label);
  final String label;
}

@immutable
class Passenger {
  const Passenger({
    required this.id,
    required this.fullName,
    required this.dateOfBirth,
    required this.nationality,
    required this.passportNumber,
    required this.passportExpiry,
    this.title = PassengerTitle.mr,
    this.nationalId,
    this.frequentFlyer,
    this.isAccountHolder = false,
  });

  final String id;

  /// Name exactly as printed on the passport or ID card.
  final String fullName;
  final DateTime dateOfBirth;
  final String nationality;
  final PassengerTitle title;

  /// Empty when the traveller flies on a national ID only (domestic flights
  /// within Türkiye).
  final String passportNumber;
  final DateTime? passportExpiry;

  /// Turkish national ID (T.C. kimlik numarası), for citizens of Türkiye.
  final String? nationalId;

  /// Miles&Smiles membership number, e.g. TK123456789.
  final String? frequentFlyer;
  final bool isAccountHolder;

  bool get hasPassport => passportNumber.isNotEmpty;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  /// First and last name, as printed on a boarding pass stub.
  String get shortName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length <= 2) return fullName.trim();
    return '${parts.first} ${parts.last}';
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  /// Passport number with everything but the last four characters hidden.
  String get maskedPassport => _mask(passportNumber);

  /// National ID with everything but the last four digits hidden.
  String get maskedNationalId => _mask(nationalId ?? '');

  static String _mask(String value) {
    if (value.length <= 4) return value;
    return '•• ${value.substring(value.length - 4)}';
  }

  Passenger copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? nationality,
    String? passportNumber,
    DateTime? passportExpiry,
    PassengerTitle? title,
    String? nationalId,
    String? frequentFlyer,
  }) =>
      Passenger(
        id: id,
        fullName: fullName ?? this.fullName,
        dateOfBirth: dateOfBirth ?? this.dateOfBirth,
        nationality: nationality ?? this.nationality,
        passportNumber: passportNumber ?? this.passportNumber,
        passportExpiry: passportExpiry ?? this.passportExpiry,
        title: title ?? this.title,
        nationalId: nationalId ?? this.nationalId,
        frequentFlyer: frequentFlyer ?? this.frequentFlyer,
        isAccountHolder: isAccountHolder,
      );
}

@immutable
class ContactDetails {
  const ContactDetails({required this.email, required this.phone});
  final String email;
  final String phone;

  ContactDetails copyWith({String? email, String? phone}) =>
      ContactDetails(email: email ?? this.email, phone: phone ?? this.phone);
}

@immutable
class UserProfile {
  const UserProfile({
    required this.displayName,
    required this.email,
    required this.homeCity,
    required this.homeAirportCode,
    required this.traveller,
    required this.phone,
  });

  /// Name shown on the profile, e.g. "Arya Pratama".
  final String displayName;
  final String email;
  final String homeCity;
  final String homeAirportCode;
  final Passenger traveller;
  final String phone;

  String get firstName => displayName.trim().split(RegExp(r'\s+')).first;

  UserProfile copyWith({
    String? displayName,
    String? email,
    String? homeCity,
    String? homeAirportCode,
    Passenger? traveller,
    String? phone,
  }) =>
      UserProfile(
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        homeCity: homeCity ?? this.homeCity,
        homeAirportCode: homeAirportCode ?? this.homeAirportCode,
        traveller: traveller ?? this.traveller,
        phone: phone ?? this.phone,
      );
}
