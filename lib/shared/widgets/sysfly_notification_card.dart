import 'package:flutter/material.dart';

import '../../core/animations/pressable.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/formatters.dart';
import '../models/models.dart';
import 'sysfly_controls.dart';
import 'sysfly_glass_card.dart';

/// One alert in the notifications list.
class SysflyNotificationCard extends StatelessWidget {
  const SysflyNotificationCard({super.key, required this.notification, required this.now, required this.onTap});

  final AppNotification notification;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (icon, background, foreground) = switch (n.kind) {
      NotificationKind.gate => (SysflyIcons.gate, SysflyColors.tile, SysflyColors.link),
      NotificationKind.boarding => (SysflyIcons.boarding, SysflyColors.selected, Colors.white),
      NotificationKind.landed => (SysflyIcons.landed, SysflyColors.successBg, SysflyColors.successText),
      NotificationKind.priceDrop => (SysflyIcons.priceDrop, SysflyColors.tile, SysflyColors.link),
      NotificationKind.checkIn => (SysflyIcons.checkIn, SysflyColors.tile, SysflyColors.link),
    };
    final tagIcon = n.kind == NotificationKind.priceDrop ? SysflyIcons.calendar : SysflyIcons.plane;
    final age = Fmt.ago(now.difference(n.time));

    return Semantics(
      button: true,
      label: '${n.read ? '' : 'Unread. '}${n.title}. ${n.body} $age',
      child: SysflyPressable(
        onTap: onTap,
        pressedScale: 0.985,
        child: ExcludeSemantics(
          child: SysflyCard(
            radius: SysflyRadius.xl,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SysflyIconTile(icon: icon, background: background, foreground: foreground, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TrText(n.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.bodyStrong.copyWith(fontSize: 14.5)),
                          ),
                          const SizedBox(width: 8),
                          TrText(age, style: SysflyTypography.caption.copyWith(fontSize: 11)),
                          AnimatedSize(
                            duration: SysflyMotion.normal,
                            child: n.read
                                ? const SizedBox(height: 7)
                                : const Padding(
                                    padding: EdgeInsets.only(left: 7),
                                    child: SizedBox(
                                      width: 7,
                                      height: 7,
                                      child: DecoratedBox(decoration: BoxDecoration(color: SysflyColors.selected, shape: BoxShape.circle)),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      TrText(n.body, style: SysflyTypography.bodySecondary.copyWith(fontSize: 13, height: 1.4)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: const BoxDecoration(color: SysflyColors.field, borderRadius: SysflyRadius.pillAll),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SysflyIcon(tagIcon, size: 11, color: SysflyColors.textSecondary),
                            const SizedBox(width: 6),
                            TrText(n.tag, style: SysflyTypography.chip.copyWith(fontSize: 10.5, color: SysflyColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
