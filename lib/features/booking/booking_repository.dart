import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/catalog.dart';

class BookingValidationFailure implements Exception {
  const BookingValidationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class BookingRepository {
  Future<Reservation> confirm(Reservation snapshot);
}

class MockBookingRepository implements BookingRepository {
  final Map<String, Reservation> _confirmed = {};
  final Map<String, Future<Reservation>> _pending = {};
  final Map<String, Reservation> _pendingSelections = {};

  @override
  Future<Reservation> confirm(Reservation snapshot) {
    final existing = _confirmed[snapshot.id];
    if (existing != null) {
      if (!_same(existing, snapshot)) {
        return Future.error(
          const BookingValidationFailure(
            'This reservation reference belongs to a different selection. Please start again.',
          ),
        );
      }
      return Future.value(existing);
    }
    final pending = _pending[snapshot.id];
    if (pending != null) {
      if (!_same(_pendingSelections[snapshot.id]!, snapshot)) {
        return Future.error(
          const BookingValidationFailure(
            'A different selection is already being confirmed for this reference.',
          ),
        );
      }
      return pending;
    }
    // Schedule after both maps are populated so synchronous validation failures
    // cannot leave a failed future permanently registered as pending.
    final operation = Future<Reservation>(() => _confirm(snapshot));
    _pending[snapshot.id] = operation;
    _pendingSelections[snapshot.id] = snapshot;
    return operation;
  }

  Future<Reservation> _confirm(Reservation snapshot) async {
    try {
      _validate(snapshot);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      // A selected start time may pass while the confirmation is open.
      _validate(snapshot);
      _confirmed[snapshot.id] = snapshot;
      return snapshot;
    } finally {
      _pending.remove(snapshot.id);
      _pendingSelections.remove(snapshot.id);
    }
  }

  void _validate(Reservation snapshot) {
    if (snapshot.id.trim().isEmpty ||
        !events.any(
          (event) =>
              event.id == snapshot.event.id &&
              event.price == snapshot.event.price,
        )) {
      throw const BookingValidationFailure(
        'This sample experience is no longer available. Choose another experience.',
      );
    }
    if (snapshot.quantity < 1 || snapshot.quantity > 10) {
      throw const BookingValidationFailure('Choose between 1 and 10 tickets.');
    }
    if (!const ['17:00', '19:00', '21:00'].contains(snapshot.time) ||
        !Reservation.allowedTypes.contains(snapshot.type)) {
      throw const BookingValidationFailure(
        'Choose an available sample time and Standard ticket.',
      );
    }
    if (!snapshot.startsAt.isAfter(DateTime.now())) {
      throw const BookingValidationFailure(
        'This start time has passed. Close this window and choose a future date or time.',
      );
    }
    if (!snapshot.total.isFinite || snapshot.total < 0) {
      throw const BookingValidationFailure(
        'The sample total could not be calculated. Please start again.',
      );
    }
  }

  bool _same(Reservation first, Reservation second) =>
      first.event.id == second.event.id &&
      first.date == second.date &&
      first.time == second.time &&
      first.type == second.type &&
      first.quantity == second.quantity &&
      first.total == second.total;
}

final bookingRepositoryProvider = Provider<BookingRepository>(
  (ref) => MockBookingRepository(),
);
