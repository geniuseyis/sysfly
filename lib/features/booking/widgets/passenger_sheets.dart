import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';

/// Inserts the slashes of a DD/MM/YYYY date as the digits are typed.
class DateInputFormatter extends TextInputFormatter {
  const DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 8 ? digits.substring(0, 8) : digits;
    final out = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i == 2 || i == 4) out.write('/');
      out.write(clipped[i]);
    }
    final text = out.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Parses DD/MM/YYYY, returning null for anything that is not a real date.
DateTime? parseDmy(String input) {
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(input.trim());
  if (m == null) return null;
  final day = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final year = int.parse(m.group(3)!);
  final date = DateTime(year, month, day);
  if (date.day != day || date.month != month || date.year != year) return null;
  return date;
}

String formatDmy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Collects or edits one traveller's passport details. Returns the
/// traveller, or null when dismissed.
Future<Passenger?> showTravellerSheet(
  BuildContext context, {
  required String title,
  required String id,
  required DateTime travelDate,
  required DateTime today,
  Passenger? initial,
  List<Passenger> suggestions = const [],
  bool domestic = false,
}) {
  return showSysflySheet<Passenger>(
    context,
    builder: (_) => _PassengerForm(
      title: title,
      id: id,
      travelDate: travelDate,
      today: today,
      initial: initial,
      suggestions: suggestions,
      domestic: domestic,
    ),
  );
}

class _PassengerForm extends StatefulWidget {
  const _PassengerForm({
    required this.title,
    required this.id,
    required this.travelDate,
    required this.today,
    required this.initial,
    required this.suggestions,
    required this.domestic,
  });

  final String title;
  final String id;
  final DateTime travelDate;
  final DateTime today;
  final Passenger? initial;
  final List<Passenger> suggestions;

  /// Every flight is within Türkiye, so citizens may travel on their
  /// national ID instead of a passport.
  final bool domestic;

  @override
  State<_PassengerForm> createState() => _PassengerFormState();
}

class _PassengerFormState extends State<_PassengerForm> {
  final _name = TextEditingController();
  final _birth = TextEditingController();
  final _nationality = TextEditingController();
  final _passport = TextEditingController();
  final _expiry = TextEditingController();
  final _nationalId = TextEditingController();
  final _miles = TextEditingController();
  final _errors = <String, String?>{};
  PassengerTitle _title = PassengerTitle.mr;

  bool get _turkish => Validators.isTurkish(_nationality.text);
  bool get _passportRequired => !(widget.domestic && _turkish);

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _fill(widget.initial!);
  }

  void _fill(Passenger p) {
    _name.text = p.fullName;
    _birth.text = formatDmy(p.dateOfBirth);
    _nationality.text = p.nationality;
    _passport.text = p.passportNumber;
    _expiry.text = p.passportExpiry == null ? '' : formatDmy(p.passportExpiry!);
    _nationalId.text = p.nationalId ?? '';
    _miles.text = p.frequentFlyer ?? '';
    setState(() {
      _title = p.title;
      _errors.clear();
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _birth, _nationality, _passport, _expiry, _nationalId, _miles]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final birth = parseDmy(_birth.text);
    final expiry = parseDmy(_expiry.text);
    setState(() {
      _errors['name'] = Validators.fullName(_name.text);
      _errors['birth'] = birth == null
          ? 'Use DD/MM/YYYY'
          : birth.isAfter(widget.today)
              ? 'Date of birth cannot be in the future'
              : null;
      _errors['nationality'] = Validators.required(_nationality.text, 'the nationality');
      _errors['nationalId'] = _turkish ? Validators.turkishId(_nationalId.text) : null;
      _errors['miles'] = Validators.milesSmiles(_miles.text);
      // On domestic flights a citizen's passport is optional, but if one is
      // entered it still has to be valid.
      final checkPassport = _passportRequired || _passport.text.trim().isNotEmpty || _expiry.text.trim().isNotEmpty;
      _errors['passport'] = checkPassport ? Validators.passport(_passport.text) : null;
      _errors['expiry'] = !checkPassport
          ? null
          : expiry == null
              ? 'Use DD/MM/YYYY'
              : !expiry.isAfter(widget.travelDate)
                  ? 'Passport must be valid on ${Fmt.dayMonth(widget.travelDate)}'
                  : null;
    });
    if (_errors.values.any((e) => e != null)) return;
    Navigator.of(context).pop(
      Passenger(
        id: widget.id,
        fullName: _name.text.trim(),
        dateOfBirth: birth!,
        nationality: _nationality.text.trim(),
        passportNumber: _passport.text.trim().toUpperCase(),
        passportExpiry: _passport.text.trim().isEmpty ? null : expiry,
        title: _title,
        nationalId: _turkish ? _nationalId.text.trim() : null,
        frequentFlyer: _miles.text.trim().isEmpty ? null : _miles.text.trim().toUpperCase().replaceAll(' ', ''),
        isAccountHolder: widget.initial?.isAccountHolder ?? false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void clear(String key) {
      if (_errors[key] != null) setState(() => _errors[key] = null);
    }

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SysflySheetTitle(title: widget.title, subtitle: 'Exactly as printed on the passport'),
          if (widget.suggestions.isNotEmpty) ...[
            const SizedBox(height: 14),
            TrText('Saved travellers', style: SysflyTypography.captionStrong),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in widget.suggestions)
                  Semantics(
                    button: true,
                    label: 'Use ${p.fullName}',
                    child: SysflyPressable(
                      onTap: () => _fill(p),
                      child: ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                          decoration: BoxDecoration(
                            color: SysflyColors.field,
                            borderRadius: SysflyRadius.pillAll,
                            border: Border.all(color: SysflyColors.fieldBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SysflyInitials(initials: p.initials, size: 28),
                              const SizedBox(width: 8),
                              TrText(p.shortName, style: SysflyTypography.chip.copyWith(fontSize: 12.5)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: TrText('Title', style: SysflyTypography.captionStrong),
          ),
          SysflySegmentedControl(
            key: const ValueKey('passenger-title'),
            labels: [for (final t in PassengerTitle.values) t.label],
            index: _title.index,
            onChanged: (i) => setState(() => _title = PassengerTitle.values[i]),
          ),
          const SizedBox(height: 12),
          SysflyTextField(
            key: const ValueKey('passenger-name'),
            controller: _name,
            label: 'Full name',
            hint: 'First and last name',
            icon: SysflyIcons.user,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            errorText: _errors['name'],
            onChanged: (_) => clear('name'),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SysflyTextField(
                  key: const ValueKey('passenger-birth'),
                  controller: _birth,
                  label: 'Date of birth',
                  hint: 'DD/MM/YYYY',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: const [DateInputFormatter()],
                  errorText: _errors['birth'],
                  onChanged: (_) => clear('birth'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SysflyTextField(
                  key: const ValueKey('passenger-nationality'),
                  controller: _nationality,
                  label: 'Nationality',
                  hint: 'Country',
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['nationality'],
                  onChanged: (_) => setState(() => _errors['nationality'] = null),
                ),
              ),
            ],
          ),
          if (_turkish) ...[
            const SizedBox(height: 12),
            SysflyTextField(
              key: const ValueKey('passenger-national-id'),
              controller: _nationalId,
              label: 'T.C. identity number',
              hint: '11 digits',
              icon: SysflyIcons.documents,
              sensitive: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
              errorText: _errors['nationalId'],
              onChanged: (_) => clear('nationalId'),
            ),
          ],
          const SizedBox(height: 12),
          if (!_passportRequired)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: TrText('Not needed on domestic flights', style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SysflyTextField(
                  key: const ValueKey('passenger-passport'),
                  controller: _passport,
                  label: 'Passport number',
                  hint: _passportRequired ? 'X1234567' : 'Optional',
                  sensitive: true,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(9)],
                  errorText: _errors['passport'],
                  onChanged: (_) => clear('passport'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SysflyTextField(
                  key: const ValueKey('passenger-expiry'),
                  controller: _expiry,
                  label: 'Expires',
                  hint: 'DD/MM/YYYY',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: const [DateInputFormatter()],
                  errorText: _errors['expiry'],
                  onChanged: (_) => clear('expiry'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SysflyTextField(
            key: const ValueKey('passenger-miles'),
            controller: _miles,
            label: 'Miles&Smiles number (optional)',
            hint: 'TK123456789',
            icon: SysflyIcons.planeOutline,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(11)],
            errorText: _errors['miles'],
            onChanged: (_) => clear('miles'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18),
          SysflyGradientButton(key: const ValueKey('passenger-save'), label: 'Save traveller', onPressed: _save),
        ],
      ),
    );
  }
}

/// Edits the booking contact. Returns the new details, or null.
Future<ContactDetails?> showContactSheet(BuildContext context, {required ContactDetails initial}) {
  return showSysflySheet<ContactDetails>(context, builder: (_) => _ContactForm(initial: initial));
}

class _ContactForm extends StatefulWidget {
  const _ContactForm({required this.initial});

  final ContactDetails initial;

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  late final _email = TextEditingController(text: widget.initial.email);
  late final _phone = TextEditingController(text: widget.initial.phone);
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final emailError = Validators.email(_email.text);
    final phoneError = Validators.phone(_phone.text);
    setState(() {
      _emailError = emailError;
      _phoneError = phoneError;
    });
    if (emailError != null || phoneError != null) return;
    Navigator.of(context).pop(ContactDetails(email: _email.text.trim(), phone: _phone.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SysflySheetTitle(title: 'Contact details', subtitle: 'E-tickets and flight updates go here'),
          const SizedBox(height: 16),
          SysflyTextField(
            key: const ValueKey('contact-email'),
            controller: _email,
            label: 'Email',
            hint: 'name@example.com',
            icon: SysflyIcons.email,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _emailError,
            onChanged: (_) => setState(() => _emailError = null),
          ),
          const SizedBox(height: 12),
          SysflyTextField(
            key: const ValueKey('contact-phone'),
            controller: _phone,
            label: 'Mobile number',
            hint: '+62 812 3456 7890',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ()-]'))],
            errorText: _phoneError,
            onChanged: (_) => setState(() => _phoneError = null),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18),
          SysflyGradientButton(key: const ValueKey('contact-save'), label: 'Save contact', onPressed: _save),
        ],
      ),
    );
  }
}
