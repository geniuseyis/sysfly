import '../../shared/models/models.dart';

/// Static reference data for the demo: airports, airlines, extras, cards.
abstract final class DemoCatalog {
  static const airports = <Airport>[
    Airport(code: 'SIN', name: 'Changi', city: 'Singapore', country: 'Singapore', countryCode: 'SG', region: 'Asia', latitude: 1.3644, longitude: 103.9915, utcOffsetHours: 8),
    Airport(code: 'KUL', name: 'Kuala Lumpur Intl', city: 'Kuala Lumpur', country: 'Malaysia', countryCode: 'MY', region: 'Asia', latitude: 2.7456, longitude: 101.7099, utcOffsetHours: 8),
    Airport(code: 'BKK', name: 'Suvarnabhumi', city: 'Bangkok', country: 'Thailand', countryCode: 'TH', region: 'Asia', latitude: 13.69, longitude: 100.7501, utcOffsetHours: 7),
    Airport(code: 'HAN', name: 'Noi Bai', city: 'Hanoi', country: 'Vietnam', countryCode: 'VN', region: 'Asia', latitude: 21.2212, longitude: 105.8072, utcOffsetHours: 7),
    Airport(code: 'MNL', name: 'Ninoy Aquino', city: 'Manila', country: 'Philippines', countryCode: 'PH', region: 'Asia', latitude: 14.5086, longitude: 121.0194, utcOffsetHours: 8),
    Airport(code: 'HKG', name: 'Hong Kong Intl', city: 'Hong Kong', country: 'China', countryCode: 'CN', region: 'Asia', latitude: 22.308, longitude: 113.9185, utcOffsetHours: 8),
    Airport(code: 'ICN', name: 'Incheon', city: 'Seoul', country: 'South Korea', countryCode: 'KR', region: 'Asia', latitude: 37.4602, longitude: 126.4407, utcOffsetHours: 9),
    Airport(code: 'NRT', name: 'Narita', city: 'Tokyo', country: 'Japan', countryCode: 'JP', region: 'Asia', latitude: 35.772, longitude: 140.3929, utcOffsetHours: 9),
    Airport(code: 'TPE', name: 'Taoyuan', city: 'Taipei', country: 'Taiwan', countryCode: 'TW', region: 'Asia', latitude: 25.0797, longitude: 121.2342, utcOffsetHours: 8),
    Airport(code: 'CGK', name: 'Soekarno-Hatta', city: 'Jakarta', country: 'Indonesia', countryCode: 'ID', region: 'Indonesia', latitude: -6.1256, longitude: 106.6559, utcOffsetHours: 7),
    Airport(code: 'DPS', name: 'Ngurah Rai', city: 'Denpasar', country: 'Indonesia', countryCode: 'ID', region: 'Indonesia', latitude: -8.7482, longitude: 115.1672, utcOffsetHours: 8),
    Airport(code: 'SUB', name: 'Juanda', city: 'Surabaya', country: 'Indonesia', countryCode: 'ID', region: 'Indonesia', latitude: -7.3798, longitude: 112.7868, utcOffsetHours: 7),
    Airport(code: 'HLP', name: 'Halim Perdanakusuma', city: 'Jakarta', country: 'Indonesia', countryCode: 'ID', region: 'Indonesia', latitude: -6.2666, longitude: 106.891, utcOffsetHours: 7),
    Airport(code: 'BTH', name: 'Hang Nadim', city: 'Batam', country: 'Indonesia', countryCode: 'ID', region: 'Indonesia', latitude: 1.121, longitude: 104.119, utcOffsetHours: 7),
    Airport(code: 'MEL', name: 'Tullamarine', city: 'Melbourne', country: 'Australia', countryCode: 'AU', region: 'Oceania', latitude: -37.669, longitude: 144.841, utcOffsetHours: 10),
    Airport(code: 'SYD', name: 'Kingsford Smith', city: 'Sydney', country: 'Australia', countryCode: 'AU', region: 'Oceania', latitude: -33.9399, longitude: 151.1753, utcOffsetHours: 10),
    Airport(code: 'IST', name: 'Istanbul Airport', city: 'Istanbul', country: 'Türkiye', countryCode: 'TR', region: 'Türkiye', latitude: 41.2753, longitude: 28.7519, utcOffsetHours: 3),
    Airport(code: 'SAW', name: 'Sabiha Gökçen', city: 'Istanbul', country: 'Türkiye', countryCode: 'TR', region: 'Türkiye', latitude: 40.8986, longitude: 29.3092, utcOffsetHours: 3),
    Airport(code: 'ESB', name: 'Esenboğa', city: 'Ankara', country: 'Türkiye', countryCode: 'TR', region: 'Türkiye', latitude: 40.1281, longitude: 32.9951, utcOffsetHours: 3),
    Airport(code: 'AYT', name: 'Antalya Airport', city: 'Antalya', country: 'Türkiye', countryCode: 'TR', region: 'Türkiye', latitude: 36.8987, longitude: 30.8005, utcOffsetHours: 3),
    Airport(code: 'ADB', name: 'Adnan Menderes', city: 'İzmir', country: 'Türkiye', countryCode: 'TR', region: 'Türkiye', latitude: 38.2924, longitude: 27.157, utcOffsetHours: 3),
    // Summer time offsets: the demo is set in September.
    Airport(code: 'LHR', name: 'Heathrow', city: 'London', country: 'United Kingdom', countryCode: 'GB', region: 'Europe', latitude: 51.47, longitude: -0.4543, utcOffsetHours: 1),
    Airport(code: 'JFK', name: 'John F. Kennedy', city: 'New York', country: 'United States', countryCode: 'US', region: 'North America', latitude: 40.6413, longitude: -73.7781, utcOffsetHours: -4),
  ];

  static Airport airport(String code) => airports.firstWhere((a) => a.code == code);

  static const airlines = <String, Airline>{
    'GA': Airline(code: 'GA', name: 'Garuda Indonesia'),
    'QG': Airline(code: 'QG', name: 'Citilink'),
    'QZ': Airline(code: 'QZ', name: 'Indonesia AirAsia'),
    'IU': Airline(code: 'IU', name: 'Super Air Jet'),
    'ID': Airline(code: 'ID', name: 'Batik Air'),
    'JT': Airline(code: 'JT', name: 'Lion Air'),
    'AK': Airline(code: 'AK', name: 'AirAsia'),
    'MH': Airline(code: 'MH', name: 'Malaysia Airlines'),
    'SQ': Airline(code: 'SQ', name: 'Singapore Airlines'),
    'TR': Airline(code: 'TR', name: 'Scoot'),
    'JQ': Airline(code: 'JQ', name: 'Jetstar'),
    'QF': Airline(code: 'QF', name: 'Qantas'),
    'CX': Airline(code: 'CX', name: 'Cathay Pacific'),
    'TG': Airline(code: 'TG', name: 'Thai Airways'),
    'VN': Airline(code: 'VN', name: 'Vietnam Airlines'),
    'PR': Airline(code: 'PR', name: 'Philippine Airlines'),
    'KE': Airline(code: 'KE', name: 'Korean Air'),
    'NH': Airline(code: 'NH', name: 'ANA'),
    'CI': Airline(code: 'CI', name: 'China Airlines'),
    'TK': Airline(code: 'TK', name: 'Turkish Airlines'),
    'VF': Airline(code: 'VF', name: 'AJet'),
    'PC': Airline(code: 'PC', name: 'Pegasus'),
  };

  static Airline airline(String code) => airlines[code]!;

  /// Carriers that operate from each country in the demo.
  static const carriersByCountry = <String, List<String>>{
    'ID': ['GA', 'QG', 'QZ', 'IU', 'ID', 'JT'],
    'SG': ['SQ', 'TR'],
    'MY': ['AK', 'MH'],
    'TH': ['TG'],
    'VN': ['VN'],
    'PH': ['PR'],
    'CN': ['CX'],
    'KR': ['KE'],
    'JP': ['NH'],
    'TW': ['CI'],
    'AU': ['QF', 'JQ'],
    'TR': ['TK', 'VF', 'PC'],
    'GB': ['TK'],
    'US': ['TK'],
  };

  static const extras = <TripExtra>[
    TripExtra(id: 'baggage', title: 'Extra Baggage', subtitle: '+1 checked bag (23kg max)', price: 18),
    TripExtra(id: 'flex', title: 'Flexible Ticket', subtitle: 'Free change up to 3h before', price: 12),
    TripExtra(id: 'insurance', title: 'Travel Insurance', subtitle: 'Medical, delays and lost bags', price: 9),
  ];

  static const cards = <PaymentMethod>[
    PaymentMethod(id: 'visa-4242', brand: PaymentBrand.visa, last4: '4242', expiry: '08/29', isDefault: true),
    PaymentMethod(id: 'mc-8812', brand: PaymentBrand.mastercard, last4: '8812', expiry: '02/28'),
  ];

  static const applePay = PaymentMethod(id: 'apple-pay', brand: PaymentBrand.applePay);
  static const googlePay = PaymentMethod(id: 'google-pay', brand: PaymentBrand.googlePay);

  static const promoCodes = <PromoCode>[
    PromoCode(code: 'SYSFLY10', percentOff: 10, description: '10% off the fare'),
  ];

  static final traveller = Passenger(
    id: 'p-arya',
    fullName: 'Arya Pratama Wijaya',
    dateOfBirth: DateTime(1994, 3, 18),
    nationality: 'Indonesia',
    passportNumber: 'X4821937',
    passportExpiry: DateTime(2031, 5, 2),
    frequentFlyer: 'TK204815963',
    isAccountHolder: true,
  );

  static final savedTravellers = <Passenger>[
    traveller,
    Passenger(
      id: 'p-sari',
      fullName: 'Sari Dewi Lestari',
      dateOfBirth: DateTime(1995, 11, 6),
      nationality: 'Indonesia',
      passportNumber: 'B7730415',
      passportExpiry: DateTime(2029, 9, 14),
      title: PassengerTitle.ms,
    ),
    Passenger(
      id: 'p-bima',
      fullName: 'Bima Putra Wijaya',
      dateOfBirth: DateTime(2016, 7, 23),
      nationality: 'Indonesia',
      passportNumber: 'C1094682',
      passportExpiry: DateTime(2028, 1, 30),
    ),
    // 10000000146 is the published test number for Turkish national IDs; it
    // belongs to no one but passes the check-digit algorithm.
    Passenger(
      id: 'p-elif',
      fullName: 'Elif Yılmaz',
      dateOfBirth: DateTime(1992, 4, 9),
      nationality: 'Türkiye',
      passportNumber: 'U23849176',
      passportExpiry: DateTime(2033, 2, 11),
      title: PassengerTitle.ms,
      nationalId: '10000000146',
      frequentFlyer: 'TK731904226',
    ),
  ];

  static final user = UserProfile(
    displayName: 'Arya Pratama',
    email: 'arya.pratama@mail.com',
    homeCity: 'Denpasar',
    homeAirportCode: 'DPS',
    traveller: traveller,
    phone: '+62 812 3456 7890',
  );

  /// Credentials of the seeded account. Any other valid email is provisioned
  /// as a demo traveller on first sign-in.
  static const demoPassword = 'sysfly123';
}
