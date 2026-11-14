/// Form validators. Each returns an error message, or null when valid.
abstract final class Validators {
  static final _email = RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? required(String? value, String field) {
    if ((value ?? '').trim().isEmpty) return 'Enter $field';
    return null;
  }

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter the full name';
    if (v.split(RegExp(r'\s+')).length < 2) return 'Enter first and last name';
    if (!RegExp(r"^[\p{L} .'-]+$", unicode: true).hasMatch(v)) return 'Use letters only, as on the passport';
    return null;
  }

  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 'Enter a mobile number';
    if (digits.length < 8 || digits.length > 15) return 'Enter a valid mobile number';
    return null;
  }

  static String? passport(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return 'Enter the passport number';
    if (!RegExp(r'^[A-Z0-9]{6,9}$').hasMatch(v)) return 'Use 6 to 9 letters and digits';
    return null;
  }

  /// True for the ways people write the nationality of Türkiye.
  static bool isTurkish(String nationality) {
    final v = nationality.trim().toLowerCase();
    return const {'türkiye', 'turkiye', 'turkey', 'tr', 'türk', 'turk', 'turkish', 'türkei', 'turquie', 'turquía', 'турция'}.contains(v);
  }

  /// Turkish national ID (T.C. kimlik numarası): 11 digits, not starting with
  /// 0, with the two check digits of the official algorithm.
  static String? turkishId(String? value) {
    final v = (value ?? '').trim();
    if (!RegExp(r'^[1-9]\d{10}$').hasMatch(v)) return 'Enter a valid T.C. identity number';
    final d = v.codeUnits.map((c) => c - 48).toList();
    final odd = d[0] + d[2] + d[4] + d[6] + d[8];
    final even = d[1] + d[3] + d[5] + d[7];
    if (((odd * 7 - even) % 10 + 10) % 10 != d[9]) return 'Enter a valid T.C. identity number';
    if (d.take(10).reduce((a, b) => a + b) % 10 != d[10]) return 'Enter a valid T.C. identity number';
    return null;
  }

  /// Optional Miles&Smiles membership number: TK followed by nine digits.
  static String? milesSmiles(String? value) {
    final v = (value ?? '').trim().toUpperCase().replaceAll(' ', '');
    if (v.isEmpty) return null;
    if (!RegExp(r'^TK\d{9}$').hasMatch(v)) return 'Use TK followed by 9 digits';
    return null;
  }

  /// Luhn check on a 13 to 19 digit card number.
  static String? cardNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\s'), '');
    if (digits.isEmpty) return 'Enter the card number';
    if (!RegExp(r'^\d{13,19}$').hasMatch(digits)) return 'Enter a valid card number';
    var sum = 0;
    var alternate = false;
    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }
    if (sum % 10 != 0) return 'This card number is not valid';
    return null;
  }

  /// MM/YY that has not passed at [now].
  static String? cardExpiry(String? value, DateTime now) {
    final m = RegExp(r'^(\d{2})/(\d{2})$').firstMatch((value ?? '').trim());
    if (m == null) return 'Use MM/YY';
    final month = int.parse(m.group(1)!);
    final year = 2000 + int.parse(m.group(2)!);
    if (month < 1 || month > 12) return 'Enter a valid month';
    final end = DateTime(year, month + 1, 1);
    if (!end.isAfter(now)) return 'This card has expired';
    return null;
  }

  static String? cvc(String? value) {
    if (!RegExp(r'^\d{3,4}$').hasMatch((value ?? '').trim())) return 'Enter the 3 or 4 digit code';
    return null;
  }
}
