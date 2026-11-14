import 'package:flutter/foundation.dart';

@immutable
class TripExtra {
  const TripExtra({required this.id, required this.title, required this.subtitle, required this.price});
  final String id;
  final String title;
  final String subtitle;

  /// Whole US dollars, charged once per traveller.
  final int price;

  @override
  bool operator ==(Object other) => other is TripExtra && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum PaymentBrand {
  visa('Visa'),
  mastercard('Mastercard'),
  amex('Amex'),
  jcb('JCB'),
  applePay('Apple Pay'),
  googlePay('Google Pay');

  const PaymentBrand(this.label);
  final String label;

  bool get isWallet => this == PaymentBrand.applePay || this == PaymentBrand.googlePay;
}

/// A saved way to pay. Only the brand, last four digits and expiry are ever
/// kept; full card numbers and security codes are never stored.
@immutable
class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.brand,
    this.last4 = '',
    this.expiry = '',
    this.isDefault = false,
  });

  final String id;
  final PaymentBrand brand;
  final String last4;

  /// MM/YY.
  final String expiry;
  final bool isDefault;

  String get title => brand.isWallet ? brand.label : '${brand.label} •••• $last4';

  String get subtitle => switch (brand) {
        PaymentBrand.applePay => 'Confirm with Face ID',
        PaymentBrand.googlePay => 'Pay with your Google account',
        _ => 'Expires $expiry${isDefault ? ' · Default' : ''}',
      };

  @override
  bool operator ==(Object other) => other is PaymentMethod && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

@immutable
class PromoCode {
  const PromoCode({required this.code, required this.percentOff, required this.description});
  final String code;
  final int percentOff;
  final String description;
}

@immutable
class PriceLine {
  const PriceLine(this.label, this.amount, {this.note});
  final String label;

  /// Whole US dollars; negative for discounts. Ignored when [note] is set.
  final int amount;

  /// Text shown instead of an amount, e.g. "Included".
  final String? note;
}

/// The single source of truth for what a booking costs.
@immutable
class PriceBreakdown {
  const PriceBreakdown({required this.lines, required this.total, required this.travellers, required this.taxes});

  final List<PriceLine> lines;
  final int total;
  final int travellers;
  final int taxes;

  static const empty = PriceBreakdown(lines: [], total: 0, travellers: 1, taxes: 0);
}
