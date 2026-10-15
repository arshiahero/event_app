import '../../events/domain/event.dart';
import '../../events/domain/json_validation.dart';

class Reservation {
  const Reservation({
    required this.id,
    required this.event,
    required this.date,
    required this.time,
    this.type = 'Standard',
    required this.quantity,
  });

  static const allowedTypes = ['Standard', 'VIP', 'Balcony'];

  static double multiplierFor(String type) => switch (type) {
    'VIP' => 1.5,
    'Balcony' => 0.85,
    _ => 1.0,
  };

  static String subtitleFor(String type) => switch (type) {
    'VIP' => 'Front row seating · Priority entry',
    'Balcony' => 'Elevated view · Reserved section',
    _ => 'General admission',
  };

  final String id, time, type;
  final Event event;
  final DateTime date;
  final int quantity;

  double get unitPrice =>
      double.parse((event.price * multiplierFor(type)).toStringAsFixed(2));
  double get total => double.parse((unitPrice * quantity).toStringAsFixed(2));

  DateTime get startsAt {
    final parts = clockParts(time);
    if (date.year < 1 || date.year > 9999) {
      throw const FormatException(
        'date must have a Gregorian year between 1 and 9999',
      );
    }
    return DateTime(date.year, date.month, date.day, parts[0], parts[1]);
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final time = jsonString(json['time'], 'time');
    clockParts(time);
    final type = jsonString(
      json.containsKey('type') ? json['type'] : 'Standard',
      'type',
    );
    if (!allowedTypes.contains(type)) {
      throw const FormatException('Invalid ticket type');
    }
    final reservation = Reservation(
      id: jsonString(json['id'], 'id'),
      event: Event.fromJson(jsonObject(json['event'], 'event')),
      date: jsonDate(json['date'], 'date'),
      time: time,
      type: type,
      quantity: jsonInteger(json['quantity'], 'quantity', min: 1, max: 10),
    );
    if (!reservation.total.isFinite) {
      throw const FormatException('reservation total must be finite');
    }
    reservation.startsAt;
    return reservation;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'event': event.toJson(),
    'date': date.toIso8601String(),
    'time': time,
    'type': type,
    'quantity': quantity,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Reservation && other.id == id;
  @override
  int get hashCode => Object.hash(Reservation, id);
}
