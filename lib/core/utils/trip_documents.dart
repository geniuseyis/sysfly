import 'dart:convert';
import 'dart:typed_data';

import '../../shared/models/models.dart';
import 'formatters.dart';
import 'pdf_writer.dart';

/// Plain-text and calendar exports of a trip, used by the share actions.
abstract final class TripDocuments {
  /// Human readable itinerary.
  static String itinerary(Trip trip) {
    final out = StringBuffer()
      ..writeln('sysfly itinerary \u00b7 ${trip.reference}')
      ..writeln('${trip.travellerLabel} \u00b7 ${trip.cabin.label} ${trip.fareName}')
      ..writeln();
    for (final leg in trip.legs) {
      final f = leg.flight;
      out
        ..writeln('${f.airline.name} ${f.number}')
        ..writeln('${f.origin.city} (${f.origin.code}) ${Fmt.dayShort(f.departure)}, ${Fmt.time(f.departure)}')
        ..writeln('${f.destination.city} (${f.destination.code}) ${Fmt.time(f.arrival)} \u00b7 ${Fmt.duration(f.duration)}')
        ..writeln('Terminal ${leg.terminal} \u00b7 Gate ${leg.gate} \u00b7 Boarding ${Fmt.time(leg.boarding)}')
        ..writeln();
    }
    return out.toString().trimRight();
  }

  /// E-ticket receipt text. The demo issues no real ticket, and says so.
  static String eTicket(Trip trip) {
    final out = StringBuffer()
      ..writeln('SYSFLY E-TICKET (DEMO \u00b7 NOT VALID FOR TRAVEL)')
      ..writeln('Booking reference: ${trip.reference}')
      ..writeln('Booked: ${Fmt.full(trip.bookedAt)}')
      ..writeln();
    for (var i = 0; i < trip.passengers.length; i++) {
      final p = trip.passengers[i];
      out.writeln('Traveller ${i + 1}: ${p.fullName}');
      for (final leg in trip.legs) {
        out.writeln('  ${leg.flight.number} ${leg.flight.origin.code}-${leg.flight.destination.code} '
            'seat ${leg.seatOf(i) ?? 'assigned at check-in'}');
      }
    }
    out
      ..writeln()
      ..writeln(itinerary(trip))
      ..writeln()
      ..writeln('Fare: ${trip.cabin.label} ${trip.fareName}');
    for (final extra in trip.extras) {
      out.writeln('Extra: ${extra.title}');
    }
    final method = trip.paymentLabel.isEmpty ? '' : ', ${trip.paymentLabel}';
    out.writeln('Total: ${Fmt.money(trip.totalPaid)} (simulated payment$method)');
    return out.toString();
  }

  /// The e-ticket as a one-page PDF.
  static Uint8List eTicketPdf(Trip trip) => buildTextPdf(const LineSplitter().convert(eTicket(trip)));

  static String _stamp(DateTime local, double utcOffsetHours) {
    final utc = local.subtract(Duration(minutes: (utcOffsetHours * 60).round()));
    String two(int v) => v.toString().padLeft(2, '0');
    return '${utc.year}${two(utc.month)}${two(utc.day)}T${two(utc.hour)}${two(utc.minute)}00Z';
  }

  static String _escape(String s) => s.replaceAll('\\', '\\\\').replaceAll(',', '\\,').replaceAll(';', '\\;').replaceAll('\n', '\\n');

  /// iCalendar file with one event per flight.
  static String calendar(Trip trip) {
    final out = StringBuffer()
      ..write('BEGIN:VCALENDAR\r\n')
      ..write('VERSION:2.0\r\n')
      ..write('PRODID:-//sysfly//Trips//EN\r\n')
      ..write('CALSCALE:GREGORIAN\r\n');
    for (final leg in trip.legs) {
      final f = leg.flight;
      out
        ..write('BEGIN:VEVENT\r\n')
        ..write('UID:${trip.reference}-${f.id}@sysfly.app\r\n')
        ..write('DTSTAMP:${_stamp(trip.bookedAt, 0)}\r\n')
        ..write('DTSTART:${_stamp(f.departure, f.origin.utcOffsetHours)}\r\n')
        ..write('DTEND:${_stamp(f.arrival, f.destination.utcOffsetHours)}\r\n')
        ..write('SUMMARY:${_escape('${f.number} ${f.origin.code} to ${f.destination.code}')}\r\n')
        ..write('LOCATION:${_escape('${f.origin.name}, ${f.origin.city}')}\r\n')
        ..write('DESCRIPTION:${_escape('Booking ${trip.reference}. Terminal ${leg.terminal}, gate ${leg.gate}. '
            'Boarding ${Fmt.time(leg.boarding)}.')}\r\n')
        ..write('END:VEVENT\r\n');
    }
    out.write('END:VCALENDAR\r\n');
    return out.toString();
  }
}
