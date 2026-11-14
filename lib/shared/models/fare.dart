import 'package:flutter/foundation.dart';

import 'flight.dart';

enum FareType { lite, classic, flex }

@immutable
class FareFeature {
  const FareFeature({required this.label, required this.value, this.included = true});
  final String label;
  final String value;
  final bool included;
}

/// A fare family priced for one specific flight.
@immutable
class Fare {
  const Fare({
    required this.type,
    required this.name,
    required this.price,
    required this.tagline,
    required this.summary,
    required this.features,
    required this.includesStandardSeat,
    this.mostPopular = false,
  });

  final FareType type;
  final String name;

  /// Per traveller, whole US dollars, before taxes.
  final int price;

  /// Short line under the price on the selector card.
  final String tagline;

  /// One line description shown above the feature list.
  final String summary;
  final List<FareFeature> features;
  final bool includesStandardSeat;
  final bool mostPopular;

  static List<Fare> forFlight(Flight flight) =>
      flight.airline.code == 'TK' ? _turkishAirlines(flight.basePrice) : _standard(flight.basePrice);

  /// EcoFly, ExtraFly and PrimeFly, simplified from the economy fare
  /// families Turkish Airlines publishes. The real allowances vary by route.
  static List<Fare> _turkishAirlines(int base) => [
        Fare(
          type: FareType.lite,
          name: 'EcoFly',
          price: base,
          tagline: '+ 20 kg bag',
          summary: 'Essentials with a checked bag',
          includesStandardSeat: false,
          features: const [
            FareFeature(label: 'Cabin bag', value: '8 kg'),
            FareFeature(label: 'Checked bag', value: '20 kg'),
            FareFeature(label: 'Seat choice', value: 'From \$8', included: false),
            FareFeature(label: 'Changes', value: '\$50 per change'),
            FareFeature(label: 'Cancellation', value: 'Non-refundable', included: false),
          ],
        ),
        Fare(
          type: FareType.classic,
          name: 'ExtraFly',
          price: base + 18,
          tagline: '+ 25 kg bag',
          summary: 'More baggage and a standard seat',
          includesStandardSeat: true,
          mostPopular: true,
          features: const [
            FareFeature(label: 'Cabin bag', value: '8 kg'),
            FareFeature(label: 'Checked bag', value: '25 kg'),
            FareFeature(label: 'Seat choice', value: 'Standard seats'),
            FareFeature(label: 'Changes', value: '\$25 per change'),
            FareFeature(label: 'Cancellation', value: 'Refund less \$50'),
          ],
        ),
        Fare(
          type: FareType.flex,
          name: 'PrimeFly',
          price: base + 45,
          tagline: '+ Free changes',
          summary: 'Full flexibility with extra baggage',
          includesStandardSeat: true,
          features: const [
            FareFeature(label: 'Cabin bag', value: '8 kg'),
            FareFeature(label: 'Checked bag', value: '30 kg'),
            FareFeature(label: 'Seat choice', value: 'Any seat'),
            FareFeature(label: 'Changes', value: 'Free, fare difference applies'),
            FareFeature(label: 'Cancellation', value: 'Full refund'),
          ],
        ),
      ];

  static List<Fare> _standard(int base) {
    return [
      Fare(
        type: FareType.lite,
        name: 'Lite',
        price: base,
        tagline: 'Cabin bag only',
        summary: 'Travel light with a cabin bag',
        includesStandardSeat: false,
        features: const [
          FareFeature(label: 'Cabin bag', value: '7 kg'),
          FareFeature(label: 'Checked bag', value: 'Not included', included: false),
          FareFeature(label: 'Seat choice', value: 'From \$6', included: false),
          FareFeature(label: 'Changes', value: '\$75 per change'),
          FareFeature(label: 'Cancellation', value: 'Non-refundable', included: false),
        ],
      ),
      Fare(
        type: FareType.classic,
        name: 'Classic',
        price: base + 14,
        tagline: '+ 20 kg bag',
        summary: 'A checked bag and your pick of seat',
        includesStandardSeat: true,
        mostPopular: true,
        features: const [
          FareFeature(label: 'Cabin bag', value: '7 kg'),
          FareFeature(label: 'Checked bag', value: '20 kg'),
          FareFeature(label: 'Seat choice', value: 'Standard seats'),
          FareFeature(label: 'Changes', value: '\$45 per change'),
          FareFeature(label: 'Cancellation', value: 'Refund less \$35'),
        ],
      ),
      Fare(
        type: FareType.flex,
        name: 'Flex',
        price: base + 33,
        tagline: '+ Free changes',
        summary: 'Change or cancel without the worry',
        includesStandardSeat: true,
        features: const [
          FareFeature(label: 'Cabin bag', value: '7 kg'),
          FareFeature(label: 'Checked bag', value: '30 kg'),
          FareFeature(label: 'Seat choice', value: 'Any seat'),
          FareFeature(label: 'Changes', value: 'Free'),
          FareFeature(label: 'Cancellation', value: 'Full refund'),
        ],
      ),
    ];
  }
}
