import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/validators.dart';
import '../../../data/mock/demo_catalog.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../../authentication/widgets/login_illustration.dart';
import '../../booking/booking_controller.dart';

/// Small bordered tile showing a payment brand mark.
class PaymentBrandMark extends StatelessWidget {
  const PaymentBrandMark({super.key, required this.brand, this.width = 52, this.height = 36});

  final PaymentBrand brand;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final Widget mark = switch (brand) {
      PaymentBrand.visa => TrText(
          'VISA',
          style: SysflyTypography.bodyStrong.copyWith(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1A2E9A),
            letterSpacing: 0.2,
          ),
        ),
      PaymentBrand.mastercard => SizedBox(
          width: 30,
          height: 19,
          child: Stack(
            children: const [
              Positioned(left: 0, child: _Disc(Color(0xFFEB001B))),
              Positioned(right: 0, child: _Disc(Color(0xD9F79E1B))),
            ],
          ),
        ),
      PaymentBrand.amex => TrText(
          'AMEX',
          style: SysflyTypography.chip.copyWith(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF1F72CD)),
        ),
      PaymentBrand.jcb => TrText(
          'JCB',
          style: SysflyTypography.chip.copyWith(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0B7A3B)),
        ),
      PaymentBrand.applePay => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SysflyIcon(SysflyIcons.apple, size: 15, color: Colors.black),
            const SizedBox(width: 1),
            Text('Pay', style: SysflyTypography.bodyStrong.copyWith(fontSize: 13.5, color: Colors.black)),
          ],
        ),
      PaymentBrand.googlePay => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GoogleMark(size: 13),
            const SizedBox(width: 3),
            Text('Pay', style: SysflyTypography.bodyStrong.copyWith(fontSize: 13, color: const Color(0xFF5F6368))),
          ],
        ),
    };
    return ExcludeSemantics(
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SysflyColors.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: SysflyColors.fieldBorder),
        ),
        child: mark,
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 19, height: 19, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// Express checkout options, in the order the reference lists them. Both are
/// simulated in the demo build, like every other payment method.
List<PaymentMethod> expressWallets() => const [DemoCatalog.applePay, DemoCatalog.googlePay];

/// Lets the traveller choose how to pay. Returns the chosen method.
Future<PaymentMethod?> showPaymentMethodSheet(BuildContext context, {required PaymentMethod current}) {
  return showSysflySheet<PaymentMethod>(context, builder: (_) => _PaymentMethodSheet(current: current));
}

class _PaymentMethodSheet extends ConsumerWidget {
  const _PaymentMethodSheet({required this.current});

  final PaymentMethod current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(paymentMethodsProvider).valueOrNull ?? const <PaymentMethod>[];
    final wallets = expressWallets();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SysflySheetTitle(title: 'Payment method'),
          const SizedBox(height: 14),
          const _Label('Cards'),
          SysflyFieldBox(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: Column(
              children: [
                for (final card in cards) ...[
                  _MethodRow(method: card, selected: card == current, onTap: () => Navigator.of(context).pop(card)),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE4E7F0)),
                ],
                Semantics(
                  button: true,
                  label: 'Add a new card',
                  child: SysflyPressable(
                    key: const ValueKey('add-card'),
                    onTap: () async {
                      final added = await showAddCardSheet(context);
                      if (added != null && context.mounted) Navigator.of(context).pop(added);
                    },
                    pressedScale: 0.985,
                    child: ExcludeSemantics(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 36,
                              decoration: BoxDecoration(color: SysflyColors.tile, borderRadius: BorderRadius.circular(9)),
                              child: const SysflyIcon(SysflyIcons.plus, size: 15, color: SysflyColors.link),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TrText('Add a new card', style: SysflyTypography.bodyStrong.copyWith(color: SysflyColors.royalText)),
                                  const SizedBox(height: 2),
                                  TrText('Visa, Mastercard, Amex or JCB', style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                                ],
                              ),
                            ),
                            const SysflyIcon(SysflyIcons.chevronRight, size: 14, color: Color(0xFFC6C9D4)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (wallets.isNotEmpty) ...[
            const SizedBox(height: 18),
            const _Label('Express checkout'),
            SysflyFieldBox(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              child: Column(
                children: [
                  for (final wallet in wallets) ...[
                    if (wallet != wallets.first) const Divider(height: 1, thickness: 1, color: Color(0xFFE4E7F0)),
                    _MethodRow(method: wallet, selected: wallet == current, onTap: () => Navigator.of(context).pop(wallet)),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: TrText(text, style: SysflyTypography.captionStrong),
      );
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({required this.method, required this.selected, required this.onTap});

  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${method.title}, ${method.subtitle}',
      child: SysflyPressable(
        key: ValueKey('method-${method.id}'),
        onTap: onTap,
        pressedScale: 0.985,
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              children: [
                PaymentBrandMark(brand: method.brand),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrText(method.title, style: SysflyTypography.bodyStrong),
                      const SizedBox(height: 2),
                      TrText(method.subtitle, style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                    ],
                  ),
                ),
                if (selected) const SysflyRadioCheck(selected: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Groups card digits in fours as they are typed.
class CardNumberFormatter extends TextInputFormatter {
  const CardNumberFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 19 ? digits.substring(0, 19) : digits;
    final out = StringBuffer();
    for (var i = 0; i < clipped.length; i++) {
      if (i > 0 && i % 4 == 0) out.write(' ');
      out.write(clipped[i]);
    }
    final text = out.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Inserts the slash of an MM/YY expiry.
class ExpiryFormatter extends TextInputFormatter {
  const ExpiryFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final clipped = digits.length > 4 ? digits.substring(0, 4) : digits;
    final text = clipped.length > 2 ? '${clipped.substring(0, 2)}/${clipped.substring(2)}' : clipped;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// Collects a new card. Only the brand, last four digits and expiry are kept;
/// the number and security code are discarded as soon as the sheet closes.
Future<PaymentMethod?> showAddCardSheet(BuildContext context) =>
    showSysflySheet<PaymentMethod>(context, builder: (_) => const _AddCardSheet());

class _AddCardSheet extends ConsumerStatefulWidget {
  const _AddCardSheet();

  @override
  ConsumerState<_AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends ConsumerState<_AddCardSheet> {
  final _number = TextEditingController();
  final _expiry = TextEditingController();
  final _cvc = TextEditingController();
  final _name = TextEditingController();
  final _errors = <String, String?>{};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_number, _expiry, _cvc, _name]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _errors['number'] = Validators.cardNumber(_number.text);
      _errors['expiry'] = Validators.cardExpiry(_expiry.text, ref.read(clockProvider).now());
      _errors['cvc'] = Validators.cvc(_cvc.text);
      _errors['name'] = Validators.required(_name.text, 'the name on the card');
    });
    if (_errors.values.any((e) => e != null)) return;
    setState(() => _saving = true);
    final method = await ref.read(paymentMethodsProvider.notifier).addCard(number: _number.text, expiry: _expiry.text);
    if (mounted) Navigator.of(context).pop(method);
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
          const SysflySheetTitle(
            title: 'Add a new card',
            subtitle: 'Demo build: use the test number 4242 4242 4242 4242. Only the last four digits and expiry are kept.',
          ),
          const SizedBox(height: 16),
          SysflyTextField(
            key: const ValueKey('card-number'),
            controller: _number,
            sensitive: true,
            label: 'Card number',
            hint: '4242 4242 4242 4242',
            icon: SysflyIcons.card,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: const [CardNumberFormatter()],
            autofillHints: const [AutofillHints.creditCardNumber],
            errorText: _errors['number'],
            onChanged: (_) => clear('number'),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SysflyTextField(
                  key: const ValueKey('card-expiry'),
                  controller: _expiry,
                  label: 'Expiry',
                  hint: 'MM/YY',
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: const [ExpiryFormatter()],
                  errorText: _errors['expiry'],
                  onChanged: (_) => clear('expiry'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SysflyTextField(
                  key: const ValueKey('card-cvc'),
                  controller: _cvc,
                  label: 'Security code',
                  hint: 'CVC',
                  obscure: true,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  errorText: _errors['cvc'],
                  onChanged: (_) => clear('cvc'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SysflyTextField(
            key: const ValueKey('card-name'),
            controller: _name,
            label: 'Name on card',
            hint: 'As printed on the card',
            icon: SysflyIcons.user,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            errorText: _errors['name'],
            onChanged: (_) => clear('name'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 18),
          SysflyGradientButton(key: const ValueKey('card-save'), label: 'Save card', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}

/// Asks for a promo code and applies it. Returns true when one was applied.
Future<bool?> showPromoSheet(BuildContext context) =>
    showSysflySheet<bool>(context, builder: (_) => const _PromoSheet());

class _PromoSheet extends ConsumerStatefulWidget {
  const _PromoSheet();

  @override
  ConsumerState<_PromoSheet> createState() => _PromoSheetState();
}

class _PromoSheetState extends ConsumerState<_PromoSheet> {
  final _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _apply() {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Enter a promo code');
      return;
    }
    if (ref.read(bookingControllerProvider.notifier).applyPromo(_code.text)) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'This code is not valid');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SysflySheetTitle(
            title: 'Promo code',
            subtitle: 'Demo code: ${DemoCatalog.promoCodes.first.code} (${DemoCatalog.promoCodes.first.description})',
          ),
          const SizedBox(height: 16),
          SysflyTextField(
            key: const ValueKey('promo-code'),
            controller: _code,
            hint: 'Enter code',
            icon: SysflyIcons.promo,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            autofocus: true,
            errorText: _error,
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => _apply(),
          ),
          const SizedBox(height: 16),
          SysflyGradientButton(key: const ValueKey('promo-apply'), label: 'Apply code', onPressed: _apply),
        ],
      ),
    );
  }
}
