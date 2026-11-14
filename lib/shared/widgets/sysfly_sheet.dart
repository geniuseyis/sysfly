import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';

/// Presents [builder] as a rounded bottom sheet over a dimmed backdrop.
///
/// The sheet resizes with the keyboard and can be dragged down to dismiss.
Future<T?> showSysflySheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool expand = false,
}) {
  // The sheet's own context has the top inset removed, so capture it here.
  final topInset = MediaQuery.paddingOf(context).top;
  final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x800A0C28),
    elevation: 0,
    sheetAnimationStyle: reduce
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: SysflyMotion.sheet,
            reverseDuration: Duration(milliseconds: 260),
            curve: SysflyMotion.emphasized,
            reverseCurve: SysflyMotion.exit,
          ),
    builder: (context) => SysflySheet(expand: expand, topInset: topInset, child: builder(context)),
  );
}

/// White sheet surface with a drag handle.
class SysflySheet extends StatelessWidget {
  const SysflySheet({super.key, required this.child, this.expand = false, this.topInset = 0});

  final Widget child;

  /// Fill the available height (used by long lists).
  final bool expand;

  /// Status bar height of the screen the sheet is shown over.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Content-sized sheets may grow to just under the status bar; tall
    // sheets (lists) stop 114 pt below it so the screen behind stays visible.
    final available = media.size.height - media.padding.top - 24 - media.viewInsets.bottom;
    final maxHeight = expand ? (media.size.height - topInset - 114).clamp(200.0, available.clamp(200.0, double.infinity)) : available;
    final body = Column(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          width: 40,
          height: 4,
          decoration: const BoxDecoration(color: Color(0xFFDADDE8), borderRadius: SysflyRadius.pillAll),
        ),
        const SizedBox(height: 14),
        Flexible(fit: expand ? FlexFit.tight : FlexFit.loose, child: child),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight, minHeight: expand ? maxHeight : 0),
        child: Material(
          color: SysflyColors.surface,
          borderRadius: SysflyRadius.sheetTop,
          clipBehavior: Clip.antiAlias,
          child: SafeArea(top: false, child: body),
        ),
      ),
    );
  }
}

/// Title block at the top of a sheet.
class SysflySheetTitle extends StatelessWidget {
  const SysflySheetTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(header: true, child: TrText(title, style: SysflyTypography.section.copyWith(fontSize: 20))),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          TrText(subtitle!, style: SysflyTypography.bodySecondary.copyWith(fontSize: 13.5)),
        ],
      ],
    );
  }
}
