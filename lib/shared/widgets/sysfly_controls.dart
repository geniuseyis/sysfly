import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';
import '../../core/services/haptics.dart';

/// Pill segmented control with a sliding white thumb.
class SysflySegmentedControl extends StatelessWidget {
  const SysflySegmentedControl({super.key, required this.labels, required this.index, required this.onChanged, this.height = 44});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SysflyColors.field,
        borderRadius: SysflyRadius.pillAll,
        border: Border.all(color: SysflyColors.fieldBorder),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: Alignment(labels.length == 1 ? 0 : -1 + 2 * index / (labels.length - 1), 0),
            duration: SysflyMotion.normal,
            curve: SysflyMotion.emphasized,
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              heightFactor: 1,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: SysflyColors.surface,
                  borderRadius: SysflyRadius.pillAll,
                  boxShadow: SysflyShadows.pill,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: labels[i],
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != index) {
                          SysflyHaptics.selection();
                          onChanged(i);
                        }
                      },
                      child: Center(
                        child: ExcludeSemantics(
                          child: AnimatedDefaultTextStyle(
                            duration: SysflyMotion.normal,
                            style: SysflyTypography.body.copyWith(
                              fontSize: 14.5,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                              color: i == index ? SysflyColors.link : const Color(0xFF4B4E60),
                            ),
                            child: TrText(labels[i], maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Rounded-square checkbox, navy when checked.
class SysflyCheckbox extends StatelessWidget {
  const SysflyCheckbox({super.key, required this.value, this.size = 22});

  final bool value;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SysflyMotion.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: value ? SysflyColors.selected : SysflyColors.surface,
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: value ? SysflyColors.selected : const Color(0xFFD5D8E4), width: 1.4),
      ),
      child: AnimatedScale(
        scale: value ? 1 : 0,
        duration: SysflyMotion.normal,
        curve: Curves.easeOutBack,
        child: SysflyIcon(SysflyIcons.check, size: size * 0.62, color: Colors.white),
      ),
    );
  }
}

/// Circular radio that shows a check when selected.
class SysflyRadioCheck extends StatelessWidget {
  const SysflyRadioCheck({super.key, required this.selected, this.size = 22});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: SysflyMotion.fast,
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? SysflyColors.selected : SysflyColors.surface,
        border: Border.all(color: selected ? SysflyColors.selected : const Color(0xFFD9DCE7), width: 1.4),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: SysflyMotion.normal,
        curve: Curves.easeOutBack,
        child: SysflyIcon(SysflyIcons.check, size: size * 0.58, color: Colors.white),
      ),
    );
  }
}

/// Rounded tile holding an icon, e.g. in settings rows and extras.
class SysflyIconTile extends StatelessWidget {
  const SysflyIconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.background = SysflyColors.tile,
    this.foreground = SysflyColors.link,
    this.radius,
  });

  final SysflyIconData icon;
  final double size;
  final Color background;
  final Color foreground;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius ?? size * 0.32)),
      child: SysflyIcon(icon, size: size * 0.48, color: foreground),
    );
  }
}

enum SysflyChipTone { success, info, neutral, danger }

/// Small status pill with an optional leading dot.
class SysflyStatusChip extends StatelessWidget {
  const SysflyStatusChip({super.key, required this.label, this.tone = SysflyChipTone.success, this.dot = true, this.icon});

  final String label;
  final SysflyChipTone tone;
  final bool dot;
  final SysflyIconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, dotColor) = switch (tone) {
      SysflyChipTone.success => (SysflyColors.successBg, SysflyColors.successText, SysflyColors.success),
      SysflyChipTone.info => (SysflyColors.infoBg, SysflyColors.infoText, SysflyColors.info),
      SysflyChipTone.neutral => (SysflyColors.chip, SysflyColors.chipText, SysflyColors.chipText),
      SysflyChipTone.danger => (SysflyColors.errorBg, SysflyColors.error, SysflyColors.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: SysflyRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SysflyIcon(icon!, size: 12, color: fg),
            const SizedBox(width: 5),
          ] else if (dot) ...[
            Container(width: 6, height: 6, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
          ],
          TrText(label, style: SysflyTypography.chip.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Booking progress: Fare, Passengers, Seats, Pay.
class SysflyStepProgress extends StatelessWidget {
  const SysflyStepProgress({super.key, required this.current});

  /// Index of the active step, 0 to 3.
  final int current;

  static const steps = ['Fare', 'Passengers', 'Seats', 'Pay'];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Step ${current + 1} of ${steps.length}: ${steps[current]}',
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: i <= current ? 1 : 0),
                      duration: SysflyMotion.slow,
                      curve: SysflyMotion.standard,
                      builder: (context, value, _) => ClipRRect(
                        borderRadius: SysflyRadius.pillAll,
                        child: SizedBox(
                          height: 3,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              const ColoredBox(color: Color(0xFFDFE2EE)),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: value,
                                child: const ColoredBox(color: SysflyColors.selected),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        if (i < current) ...[
                          Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(color: SysflyColors.selected, shape: BoxShape.circle),
                            child: const SysflyIcon(SysflyIcons.check, size: 9, color: Colors.white),
                          ),
                          const SizedBox(width: 5),
                        ],
                        Flexible(
                          child: TrText(
                            steps[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SysflyTypography.caption.copyWith(
                              fontSize: 12,
                              fontWeight: i <= current ? FontWeight.w600 : FontWeight.w400,
                              color: i < current
                                  ? SysflyColors.textPrimary
                                  : i == current
                                      ? SysflyColors.royalText
                                      : SysflyColors.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fixed checkout bar: amount and note on the left, action on the right.
class SysflyBottomBar extends StatelessWidget {
  const SysflyBottomBar({super.key, required this.title, required this.subtitle, required this.action, this.compact = false});

  final String title;
  final String subtitle;
  final Widget action;

  /// Use a sentence-sized title (for messages rather than amounts).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(SysflySpacing.page, 18, SysflySpacing.page, 14 + bottom),
      decoration: const BoxDecoration(
        color: SysflyColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(SysflyRadius.card)),
        boxShadow: [BoxShadow(color: Color(0x14181D5A), blurRadius: 24, offset: Offset(0, -6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: SysflyMotion.normal,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(animation),
                      child: child,
                    ),
                  ),
                  layoutBuilder: (current, previous) =>
                      Stack(alignment: Alignment.centerLeft, children: [...previous, ?current]),
                  child: TrText(
                    title,
                    key: ValueKey(title),
                    style: compact ? SysflyTypography.cardTitle.copyWith(fontSize: 16.5) : SysflyTypography.total,
                  ),
                ),
                const SizedBox(height: 3),
                TrText(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.caption),
              ],
            ),
          ),
          const SizedBox(width: 12),
          action,
        ],
      ),
    );
  }
}

/// Rounded text field used on the auth screens and in sheets.
class SysflyTextField extends StatefulWidget {
  const SysflyTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
    this.focusNode,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.label,
    this.enabled = true,
    this.autofocus = false,
    this.height = 56,
    this.sensitive = false,
  });

  final TextEditingController controller;
  final String hint;
  final SysflyIconData? icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  /// Optional caption above the field.
  final String? label;
  final bool enabled;
  final bool autofocus;
  final double height;

  /// Card, passport and ID numbers: the keyboard must not suggest or learn
  /// them.
  final bool sensitive;

  @override
  State<SysflyTextField> createState() => _SysflyTextFieldState();
}

class _SysflyTextFieldState extends State<SysflyTextField> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  late bool _hidden = widget.obscure;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(SysflyTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  void _onFocus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;
    final focused = _node.hasFocus;
    final borderColor = hasError
        ? SysflyColors.error
        : focused
            ? SysflyColors.indigoMid
            : SysflyColors.fieldBorder;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: TrText(widget.label!, style: SysflyTypography.captionStrong),
          ),
        ],
        AnimatedContainer(
          duration: SysflyMotion.fast,
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: focused ? SysflyColors.surface : SysflyColors.field,
            borderRadius: SysflyRadius.fieldAll,
            border: Border.all(color: borderColor, width: focused || hasError ? 1.5 : 1),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                SysflyIcon(widget.icon!, size: 20, color: focused ? SysflyColors.textSecondary : SysflyColors.textTertiary),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _node,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  obscureText: _hidden,
                  obscuringCharacter: '•',
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  inputFormatters: widget.inputFormatters,
                  textCapitalization: widget.textCapitalization,
                  autocorrect: false,
                  enableSuggestions: !widget.obscure && !widget.sensitive,
                  cursorColor: SysflyColors.indigoMid,
                  cursorWidth: 1.6,
                  scrollPadding: const EdgeInsets.only(bottom: 120),
                  style: SysflyTypography.body.copyWith(fontSize: 15, color: SysflyColors.textPrimary),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: tr(widget.hint),
                    hintStyle: SysflyTypography.body.copyWith(fontSize: 15, fontWeight: FontWeight.w400, color: SysflyColors.textTertiary),
                  ),
                ),
              ),
              if (widget.obscure)
                Semantics(
                  button: true,
                  label: _hidden ? 'Show password' : 'Hide password',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _hidden = !_hidden),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                      child: SysflyIcon(_hidden ? SysflyIcons.eyeOff : SysflyIcons.eye, size: 20, color: SysflyColors.textTertiary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        AnimatedSize(
          duration: SysflyMotion.fast,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(left: 6, top: 6),
                  child: TrText(
                    widget.errorText!,
                    style: SysflyTypography.caption.copyWith(color: SysflyColors.error, fontWeight: FontWeight.w500),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Section title with an optional trailing text action.
class SysflySectionHeader extends StatelessWidget {
  const SysflySectionHeader({super.key, required this.title, this.subtitle, this.action, this.onAction});

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: TrText(title, style: SysflyTypography.section)),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                TrText(subtitle!, style: SysflyTypography.caption),
              ],
            ],
          ),
        ),
        if (action != null)
          Semantics(
            button: true,
            label: action,
            child: SysflyPressable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                child: ExcludeSemantics(child: TrText(action!, style: SysflyTypography.link.copyWith(fontSize: 13.5))),
              ),
            ),
          ),
      ],
    );
  }
}

/// Brief floating message.
void showSysflyToast(BuildContext context, String message, {SysflyIconData? icon, bool error = false}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: const Duration(milliseconds: 2600),
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        padding: EdgeInsets.zero,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: error ? SysflyColors.error : SysflyColors.navy,
            borderRadius: BorderRadius.circular(SysflyRadius.lg),
            boxShadow: SysflyShadows.nav,
          ),
          child: Row(
            children: [
              SysflyIcon(icon ?? (error ? SysflyIcons.warning : SysflyIcons.info), size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: TrText(
                  message,
                  style: SysflyTypography.body.copyWith(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
