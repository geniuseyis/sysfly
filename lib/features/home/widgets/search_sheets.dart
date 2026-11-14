import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../../core/services/haptics.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/widgets.dart';
import '../search_controller.dart';

/// Lets the traveller choose how many adults are flying.
Future<int?> showPassengerSheet(BuildContext context, {required int current}) {
  return showSysflySheet<int>(context, builder: (_) => _PassengerSheet(initial: current));
}

class _PassengerSheet extends StatefulWidget {
  const _PassengerSheet({required this.initial});

  final int initial;

  @override
  State<_PassengerSheet> createState() => _PassengerSheetState();
}

class _PassengerSheetState extends State<_PassengerSheet> {
  late int _count = widget.initial;

  void _change(int by) {
    final next = (_count + by).clamp(1, SearchQuery.maxPassengers);
    if (next == _count) return;
    SysflyHaptics.selection();
    setState(() => _count = next);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SysflySheetTitle(title: 'Passengers', subtitle: 'Up to ${SearchQuery.maxPassengers} travellers per booking'),
          const SizedBox(height: 18),
          SysflyFieldBox(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const SysflyIconTile(icon: SysflyIcons.passengers, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrText('Adults', style: SysflyTypography.bodyStrong),
                      const SizedBox(height: 2),
                      TrText('12 years and over', style: SysflyTypography.caption),
                    ],
                  ),
                ),
                _StepButton(icon: SysflyIcons.minus, label: 'Fewer adults', onTap: _count > 1 ? () => _change(-1) : null),
                SizedBox(
                  width: 40,
                  child: TrText('$_count', textAlign: TextAlign.center, style: SysflyTypography.cardTitle.copyWith(fontSize: 18)),
                ),
                _StepButton(
                  icon: SysflyIcons.plus,
                  label: 'More adults',
                  onTap: _count < SearchQuery.maxPassengers ? () => _change(1) : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SysflyGradientButton(
            label: _count == 1 ? 'Confirm 1 adult' : 'Confirm $_count adults',
            onPressed: () => Navigator.of(context).pop(_count),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.label, required this.onTap});

  final SysflyIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SysflyPressable(
        onTap: onTap,
        haptic: PressHaptic.none,
        pressedScale: 0.88,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: enabled ? SysflyColors.surface : Colors.transparent,
            border: Border.all(color: SysflyColors.fieldBorder),
            boxShadow: enabled ? SysflyShadows.soft : null,
          ),
          child: SysflyIcon(icon, size: 15, color: enabled ? SysflyColors.link : SysflyColors.textDisabled),
        ),
      ),
    );
  }
}

/// Lets the traveller choose a cabin class.
Future<CabinClass?> showCabinSheet(BuildContext context, {required CabinClass current}) {
  return showSysflySheet<CabinClass>(
    context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SysflySheetTitle(title: 'Cabin class', subtitle: 'Prices update for the class you choose'),
          const SizedBox(height: 16),
          for (final cabin in CabinClass.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Semantics(
                button: true,
                selected: cabin == current,
                label: cabin.label,
                child: SysflyPressable(
                  onTap: () => Navigator.of(sheetContext).pop(cabin),
                  pressedScale: 0.985,
                  child: ExcludeSemantics(
                    child: SysflyFieldBox(
                      selected: cabin == current,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                      child: Row(
                        children: [
                          const SysflyIcon(SysflyIcons.cabin, size: 20, color: SysflyColors.link),
                          const SizedBox(width: 14),
                          Expanded(child: TrText(cabin.label, style: SysflyTypography.bodyStrong)),
                          SysflyRadioCheck(selected: cabin == current),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Explains a capability that the demo build does not include.
Future<void> showDemoNotice(BuildContext context, {required String title, required String message}) {
  return showSysflySheet<void>(
    context,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SysflySheetTitle(title: title, subtitle: message),
          const SizedBox(height: 18),
          SysflyGradientButton(label: 'Got it', onPressed: () => Navigator.of(sheetContext).pop()),
        ],
      ),
    ),
  );
}
