import '../../../data/catalog.dart' as catalog;
import '../domain/event.dart';
import '../domain/events_repository.dart';

class MockEventsRepository implements EventsRepository {
  const MockEventsRepository();

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 250));

  Event? _find(String id) {
    for (final event in catalog.events) {
      if (event.id == id) return event;
    }
    return null;
  }

  @override
  Future<List<Event>> getEvents() async {
    await _delay();
    return catalog.events;
  }

  @override
  Future<Event?> getEventById(String id) async {
    await _delay();
    return _find(id);
  }

  @override
  Future<List<Review>> getReviews(String eventId) async {
    await _delay();
    return _find(eventId) == null ? const <Review>[] : catalog.reviews;
  }

  @override
  Future<List<Faq>> getFaqs(String eventId) async {
    await _delay();
    return _find(eventId) == null ? const <Faq>[] : catalog.faqs;
  }

  @override
  Future<List<City>> getCities() async {
    await _delay();
    return catalog.cities;
  }

  @override
  Future<EventPage> queryEvents(
    EventQuery query, {
    int offset = 0,
    int limit = 20,
  }) async {
    if (offset < 0 || offset > 2147483647) {
      throw const FormatException('offset must be between 0 and 2147483647');
    }
    if (limit < 1 || limit > 2147483647) {
      throw const FormatException('limit must be between 1 and 2147483647');
    }
    if (query.maxPrice != null &&
        (!query.maxPrice!.isFinite || query.maxPrice! < 0)) {
      throw const FormatException('maxPrice must be finite and non-negative');
    }
    await _delay();
    // There is no dated inventory: every mock event is available on every date.
    final seen = <String>{};
    final matches = catalog.events
        .where((event) => query.matches(event) && seen.add(event.id))
        .toList();
    final start = offset > matches.length ? matches.length : offset;
    final remaining = matches.length - start;
    final end = start + (limit > remaining ? remaining : limit);
    return EventPage(
      items: matches.sublist(start, end),
      total: matches.length,
      hasMore: end < matches.length,
    );
  }
}
