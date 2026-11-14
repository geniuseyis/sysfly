import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../authentication/auth_controller.dart';
import '../flight_filters/flight_filter.dart';
import '../notifications/notifications_controller.dart';
import 'search_controller.dart';
import 'widgets/flight_search_card.dart';

/// Home tab: greeting header, the search form and popular routes.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  /// Height of the navy header including the status bar, on the reference
  /// device (62 pt top inset).
  static const double headerHeight = 242;
  static const double referenceTopInset = 62;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showAll = false;

  void _openRoute(Flight flight) {
    ref.read(searchControllerProvider.notifier).setRoute(
          origin: flight.origin,
          destination: flight.destination,
          date: flight.departure,
        );
    ref.read(flightFilterProvider.notifier).reset();
    context.push(Routes.results);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final routes = ref.watch(popularRoutesProvider).valueOrNull ?? const <Flight>[];
    final top = MediaQuery.paddingOf(context).top;
    // Keep the measured layout below the status bar on any device.
    final header = HomeScreen.headerHeight - HomeScreen.referenceTopInset + top;
    final shown = _showAll ? routes : routes.take(2).toList();

    return ColoredBox(
      color: SysflyColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: SysflySpacing.navClearance),
        child: Stack(
          children: [
            SizedBox(
              height: header,
              width: double.infinity,
              child: SysflyHeaderBackground(
                showMap: true,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(SysflySpacing.page, top + 26, SysflySpacing.page, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 3),
                            TrText(
                              '${Fmt.greeting(ref.watch(clockProvider).deviceHour())}, ${user.firstName}',
                              style: SysflyTypography.bodySecondary.copyWith(color: const Color(0xD1FFFFFF)),
                            ),
                            const SizedBox(height: 10),
                            Semantics(
                              header: true,
                              child: TrText('Where Are You Going?', style: SysflyTypography.hero.copyWith(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                      SysflyCircleButton(
                        icon: SysflyIcons.bell,
                        badge: unread > 0,
                        semanticLabel: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
                        onTap: () => context.push(Routes.notifications),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(SysflySpacing.page, header - 43, SysflySpacing.page, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FlightSearchCard(),
                  const SizedBox(height: 14),
                  SysflySectionHeader(
                    title: 'Popular Flight Routes',
                    action: routes.length > 2 ? (_showAll ? 'See Less' : 'See All') : null,
                    onAction: () => setState(() => _showAll = !_showAll),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSize(
                    duration: SysflyMotion.slow,
                    curve: SysflyMotion.standard,
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        for (final flight in shown)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: SysflyFlightTicket(
                              key: ValueKey('popular-${flight.id}'),
                              flight: flight,
                              details: [
                                TicketDetail('FLIGHT', flight.number),
                                TicketDetail('CLASS', flight.cabin.label),
                                TicketDetail('SEATS', '${flight.seatsLeft} left'),
                              ],
                              stub: TicketFareStub(label: 'BEST FARE', price: flight.basePrice, barcode: flight.id),
                              onTap: () => _openRoute(flight),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
