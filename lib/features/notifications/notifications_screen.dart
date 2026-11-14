import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/demo_catalog.dart';
import '../../data/repositories/providers.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../flight_filters/flight_filter.dart';
import '../flight_status/widgets/flight_status_sheet.dart';
import '../home/search_controller.dart';
import '../my_flights/trips_controller.dart';
import 'notifications_controller.dart';

/// Alerts: gate changes, boarding, landings, price drops, check-in.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  /// Marks the alert read and opens what it is about.
  Future<void> _open(BuildContext context, WidgetRef ref, AppNotification n) async {
    await ref.read(notificationsProvider.notifier).markRead(n.id);
    if (!context.mounted) return;
    switch (n.kind) {
      case NotificationKind.priceDrop:
        // "CGK → SIN" on Fri, 9 Oct: search that route and date.
        ref.read(searchControllerProvider.notifier).setRoute(
              origin: DemoCatalog.airport('CGK'),
              destination: DemoCatalog.airport('SIN'),
              date: DateTime(2026, 10, 9),
            );
        ref.read(flightFilterProvider.notifier).set(const FlightFilter(sort: FlightSort.cheapest));
        context.push(Routes.results);
      case NotificationKind.checkIn || NotificationKind.gate:
        final reference = n.tripReference;
        if (reference != null && ref.read(tripByReferenceProvider(reference)) != null) {
          context.push(Routes.tripDetails(reference));
        }
      case NotificationKind.boarding || NotificationKind.landed:
        final number = n.flightNumber;
        if (number == null) return;
        final status = await ref.read(flightStatusRepositoryProvider).byNumber(number, n.time);
        if (status != null && context.mounted) await showFlightStatusSheet(context, [status]);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider).now();
    final items = ref.watch(notificationsProvider).valueOrNull ?? const <AppNotification>[];
    final unread = ref.watch(unreadNotificationsProvider);
    final today = [for (final n in items) if (Fmt.sameDay(n.time, now)) n];
    final earlier = [for (final n in items) if (!Fmt.sameDay(n.time, now)) n];

    return Scaffold(
      backgroundColor: SysflyColors.background,
      body: Column(
        children: [
          SysflyHeader(title: 'Notifications', onBack: () => context.pop()),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(SysflySpacing.page, 22, SysflySpacing.page, 24 + MediaQuery.paddingOf(context).bottom),
              children: [
                TrText(Fmt.dayShort(now), style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                const SizedBox(height: 6),
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: TrText(
                    unread == 0
                        ? 'You’re all caught up'
                        : unread == 1
                            ? '1 new alert'
                            : '$unread new alerts',
                    key: const ValueKey('alerts-count'),
                    style: SysflyTypography.headline,
                  ),
                ),
                const SizedBox(height: 22),
                if (today.isNotEmpty) ...[
                  SysflySectionHeader(
                    title: 'Today',
                    action: unread > 0 ? 'Mark all as read' : null,
                    onAction: () => ref.read(notificationsProvider.notifier).markAllRead(),
                  ),
                  const SizedBox(height: 10),
                  for (final n in today)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SysflyNotificationCard(
                        key: ValueKey('notification-${n.id}'),
                        notification: n,
                        now: now,
                        onTap: () => _open(context, ref, n),
                      ),
                    ),
                ],
                if (earlier.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SysflySectionHeader(
                    title: 'Earlier',
                    action: today.isEmpty && unread > 0 ? 'Mark all as read' : null,
                    onAction: () => ref.read(notificationsProvider.notifier).markAllRead(),
                  ),
                  const SizedBox(height: 10),
                  for (final n in earlier)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SysflyNotificationCard(
                        key: ValueKey('notification-${n.id}'),
                        notification: n,
                        now: now,
                        onTap: () => _open(context, ref, n),
                      ),
                    ),
                ],
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(child: TrText('No alerts yet', style: SysflyTypography.bodySecondary)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
