import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design_system/design_system.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/share_service.dart';
import '../../core/utils/trip_documents.dart';
import '../../shared/models/models.dart';
import '../../shared/widgets/widgets.dart';

/// Things the traveller can do with a booked trip from more than one screen.
abstract final class TripActions {
  /// Where the share sheet anchors on large screens.
  static Rect? _origin(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  static Future<void> _guard(BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (context.mounted) {
        showSysflyToast(context, error is AppException ? error.message : 'Sharing is not available on this device', error: true);
      }
    }
  }

  static Future<void> copyReference(BuildContext context, Trip trip) async {
    await Clipboard.setData(ClipboardData(text: trip.reference));
    if (context.mounted) showSysflyToast(context, 'Booking reference copied', icon: SysflyIcons.copy);
  }

  static Future<void> share(BuildContext context, WidgetRef ref, Trip trip) => _guard(
        context,
        () => ref.read(shareServiceProvider).shareText(
              text: TripDocuments.itinerary(trip),
              subject: 'Trip ${trip.reference}',
              origin: _origin(context),
            ),
      );

  /// Hands the trip to the system as an .ics file, which Calendar can import.
  static Future<void> addToCalendar(BuildContext context, WidgetRef ref, Trip trip) => _guard(
        context,
        () => ref.read(shareServiceProvider).shareFile(
              fileName: 'sysfly-${trip.reference}.ics',
              mimeType: 'text/calendar',
              bytes: utf8.encode(TripDocuments.calendar(trip)),
              subject: 'Trip ${trip.reference}',
              origin: _origin(context),
            ),
      );

  static Future<void> eTicket(BuildContext context, WidgetRef ref, Trip trip) => _guard(
        context,
        () => ref.read(shareServiceProvider).shareFile(
              fileName: 'sysfly-eticket-${trip.reference}.pdf',
              mimeType: 'application/pdf',
              bytes: TripDocuments.eTicketPdf(trip),
              subject: 'E-ticket ${trip.reference}',
              origin: _origin(context),
            ),
      );
}
