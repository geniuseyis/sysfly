import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/design_system.dart';
import '../../../shared/widgets/widgets.dart';

/// Frame shared by the four booking steps: header, step progress, a
/// scrolling body and the fixed checkout bar.
class BookingScaffold extends StatelessWidget {
  const BookingScaffold({
    super.key,
    required this.title,
    required this.step,
    required this.children,
    required this.bottomBar,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(SysflySpacing.page, 4, SysflySpacing.page, 24),
    this.controller,
  });

  final String title;

  /// 0 Fare, 1 Passengers, 2 Seats, 3 Pay.
  final int step;
  final List<Widget> children;
  final Widget bottomBar;
  final Widget? trailing;
  final EdgeInsets padding;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SysflyColors.background,
      body: Column(
        children: [
          SysflyHeader(title: title, onBack: () => context.pop(), trailing: trailing),
          Padding(
            padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 16, SysflySpacing.page, 10),
            child: SysflyStepProgress(current: step),
          ),
          Expanded(
            child: ListView(
              controller: controller,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: padding,
              children: children,
            ),
          ),
          bottomBar,
        ],
      ),
    );
  }
}

/// The "Continue" button of the checkout bar.
class BookingContinueButton extends StatelessWidget {
  const BookingContinueButton({super.key, required this.onPressed, this.label = 'Continue', this.icon});

  final VoidCallback? onPressed;
  final String label;
  final SysflyIconData? icon;

  @override
  Widget build(BuildContext context) {
    return SysflyGradientButton(
      key: const ValueKey('booking-continue'),
      label: label,
      icon: icon,
      expand: false,
      onPressed: onPressed,
    );
  }
}
