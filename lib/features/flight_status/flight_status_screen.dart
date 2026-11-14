import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../core/design_system/design_system.dart';
import '../../core/services/haptics.dart';
import '../../core/utils/clock.dart';
import '../../core/utils/formatters.dart';
import '../../data/mock/demo_catalog.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';
import '../airports/airport_sheet.dart';
import '../notifications/notifications_controller.dart';
import 'flight_status_controller.dart';
import 'widgets/flight_status_card.dart';
import 'widgets/flight_status_sheet.dart';

/// Flight Status tab: a status search, live cards for every flight the
/// traveller holds, and the flights they follow.
class FlightStatusScreen extends ConsumerStatefulWidget {
  const FlightStatusScreen({super.key});

  @override
  ConsumerState<FlightStatusScreen> createState() => _FlightStatusScreenState();
}

class _FlightStatusScreenState extends ConsumerState<FlightStatusScreen> {
  final _number = TextEditingController();
  StatusSearchMode _mode = StatusSearchMode.flightNumber;
  int _dayOffset = 0;
  Airport _from = DemoCatalog.airport('DPS');
  Airport _to = DemoCatalog.airport('CGK');

  @override
  void dispose() {
    _number.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    FocusScope.of(context).unfocus();
    final date = Fmt.dateOnly(ref.read(clockProvider).now()).add(Duration(days: _dayOffset));
    final lookup = ref.read(statusLookupProvider.notifier);
    final results = _mode == StatusSearchMode.flightNumber
        ? await lookup.byNumber(_number.text, date)
        : await lookup.byRoute(_from, _to, date);
    if (results != null && mounted) await showFlightStatusSheet(context, results);
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider).now();
    final unread = ref.watch(unreadNotificationsProvider);
    final lookup = ref.watch(statusLookupProvider);
    final held = ref.watch(heldFlightStatusesProvider);
    final tracked = ref.watch(trackedFlightsProvider).valueOrNull ?? const <FlightStatus>[];
    final today = Fmt.dateOnly(now);

    return ColoredBox(
      color: SysflyColors.background,
      child: Column(
        children: [
          SysflyHeader.brand(
            title: 'Flight Status',
            trailing: SysflyCircleButton(
              icon: SysflyIcons.bell,
              badge: unread > 0,
              semanticLabel: unread > 0 ? 'Notifications, $unread unread' : 'Notifications',
              onTap: () => context.push(Routes.notifications),
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(SysflySpacing.page, 18, SysflySpacing.page, SysflySpacing.navClearance),
              children: [
                SysflyCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SysflySegmentedControl(
                        labels: const ['Flight number', 'Route'],
                        index: _mode.index,
                        onChanged: (i) {
                          ref.read(statusLookupProvider.notifier).clearError();
                          setState(() => _mode = StatusSearchMode.values[i]);
                        },
                      ),
                      const SizedBox(height: 18),
                      AnimatedSwitcher(
                        duration: SysflyMotion.normal,
                        child: _mode == StatusSearchMode.flightNumber
                            ? SysflyTextField(
                                key: const ValueKey('status-number'),
                                controller: _number,
                                hint: 'Flight number, e.g. GA 159',
                                icon: SysflyIcons.planeOutline,
                                height: 54,
                                textCapitalization: TextCapitalization.characters,
                                textInputAction: TextInputAction.search,
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')), LengthLimitingTextInputFormatter(8)],
                                errorText: lookup.error,
                                onChanged: (_) => ref.read(statusLookupProvider.notifier).clearError(),
                                onSubmitted: (_) => _check(),
                              )
                            : Column(
                                key: const ValueKey('status-route'),
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _RouteEnd(
                                          label: 'From',
                                          airport: _from,
                                          onTap: () async {
                                            final a = await showAirportSheet(context, title: 'Flying from', selected: _from, disabled: _to);
                                            if (a != null) setState(() => _from = a);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _RouteEnd(
                                          label: 'To',
                                          airport: _to,
                                          onTap: () async {
                                            final a = await showAirportSheet(context, title: 'Flying to', selected: _to, disabled: _from);
                                            if (a != null) setState(() => _to = a);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (lookup.error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6, top: 6),
                                      child: TrText(
                                        lookup.error!,
                                        style: SysflyTypography.caption.copyWith(color: SysflyColors.error, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (final (offset, label) in const [(-1, 'Yesterday'), (0, 'Today'), (1, 'Tomorrow')]) ...[
                            if (offset != -1) const SizedBox(width: 8),
                            Expanded(
                              child: _DayChip(
                                label: label,
                                date: today.add(Duration(days: offset)),
                                selected: _dayOffset == offset,
                                onTap: () => setState(() => _dayOffset = offset),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 18),
                      SysflyGradientButton(
                        key: const ValueKey('check-status'),
                        height: 52,
                        label: 'Check Status',
                        icon: SysflyIcons.target,
                        loading: lookup.loading,
                        onPressed: _check,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: SysflyColors.info, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TrText('Live board', style: SysflyTypography.captionStrong.copyWith(color: SysflyColors.infoText, fontWeight: FontWeight.w700)),
                    ),
                    TrText('Updated just now', style: SysflyTypography.caption),
                  ],
                ),
                const SizedBox(height: 20),
                const SysflySectionHeader(title: 'Your flights', subtitle: 'Live for every trip you hold'),
                const SizedBox(height: 14),
                if (held.isEmpty)
                  SysflyCard(
                    child: TrText('Flights you book will show here with their live status.', style: SysflyTypography.bodySecondary),
                  )
                else ...[
                  FlightStatusCard(status: held.first, now: now, onTap: () => showFlightStatusSheet(context, [held.first])),
                  if (held.length > 1) ...[
                    const SizedBox(height: 14),
                    SysflyCard(
                      radius: SysflyRadius.xl,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Column(
                        children: [
                          for (var i = 1; i < held.length; i++) ...[
                            if (i > 1) const Divider(height: 1, thickness: 1, color: SysflyColors.divider),
                            FlightStatusRow(status: held[i], now: now, onTap: () => showFlightStatusSheet(context, [held[i]])),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 26),
                SysflySectionHeader(
                  title: 'Tracked flights',
                  subtitle: tracked.isEmpty
                      ? 'Check a flight above to start following it'
                      : 'Following ${tracked.length} ${tracked.length == 1 ? 'flight' : 'flights'}',
                ),
                const SizedBox(height: 14),
                for (final status in tracked)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: FlightStatusCard(
                      key: ValueKey('tracked-${status.flight.id}'),
                      status: status,
                      now: now,
                      onTap: () => showFlightStatusSheet(context, [status]),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.label, required this.date, required this.selected, required this.onTap});

  final String label;
  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label, ${Fmt.dayShort(date)}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!selected) {
            SysflyHaptics.selection();
            onTap();
          }
        },
        child: ExcludeSemantics(
          child: AnimatedContainer(
            duration: SysflyMotion.normal,
            curve: SysflyMotion.standard,
            height: 56,
            decoration: BoxDecoration(
              color: selected ? SysflyColors.selected : SysflyColors.field,
              borderRadius: BorderRadius.circular(SysflyRadius.md),
              border: Border.all(color: selected ? SysflyColors.selected : SysflyColors.fieldBorder),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TrText(
                  label,
                  style: SysflyTypography.caption.copyWith(fontSize: 11.5, color: selected ? const Color(0xCCFFFFFF) : SysflyColors.textTertiary),
                ),
                const SizedBox(height: 3),
                TrText(
                  Fmt.dayShort(date),
                  style: SysflyTypography.bodyStrong.copyWith(fontSize: 13.5, color: selected ? Colors.white : SysflyColors.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteEnd extends StatelessWidget {
  const _RouteEnd({required this.label, required this.airport, required this.onTap});

  final String label;
  final Airport airport;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label ${airport.city}, ${airport.code}',
      child: SysflyPressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: ExcludeSemantics(
          child: SysflyFieldBox(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TrText(label, style: SysflyTypography.fieldLabel.copyWith(fontSize: 11.5)),
                      const SizedBox(height: 1),
                      TrText(airport.code, style: SysflyTypography.cardTitle.copyWith(fontSize: 19)),
                      TrText(airport.city, maxLines: 1, overflow: TextOverflow.ellipsis, style: SysflyTypography.caption.copyWith(fontSize: 11.5)),
                    ],
                  ),
                ),
                const SysflyIcon(SysflyIcons.chevronDown, size: 13, color: SysflyColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
