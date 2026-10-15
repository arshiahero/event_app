import 'event.dart';

abstract class EventsRepository {
  Future<List<Event>> getEvents();
  Future<Event?> getEventById(String id);
  Future<List<Review>> getReviews(String eventId);
  Future<List<Faq>> getFaqs(String eventId);
  Future<List<City>> getCities();
  Future<EventPage> queryEvents(
    EventQuery query, {
    int offset = 0,
    int limit = 20,
  });
}

class EventQuery {
  const EventQuery({
    this.city,
    this.category = 'All',
    this.maxPrice,
    this.date,
    this.query = '',
  });

  final String? city;
  final String category;
  final double? maxPrice;
  final DateTime? date;
  final String query;

  bool matches(Event event) =>
      (city == null || event.city == city) &&
      (category == 'All' || event.category == category) &&
      (maxPrice == null ||
          (maxPrice!.isFinite && maxPrice! >= 0 && event.price <= maxPrice!)) &&
      matchesEventQuery(event, query);
}

class EventPage {
  EventPage({
    required List<Event> items,
    required this.total,
    required this.hasMore,
  }) : items = List<Event>.unmodifiable(items);

  final List<Event> items;
  final int total;
  final bool hasMore;
}

// Keep search semantics aligned with discovery, including its exact mood keywords.
String normalizeEventQuery(String value) {
  var normalized = value.toLowerCase().replaceAll('&', ' and ');
  for (final entry in const {
    '[áàäâãå]': 'a',
    '[éèëê]': 'e',
    '[íìïî]': 'i',
    '[óòöôõ]': 'o',
    '[úùüû]': 'u',
    'ç': 'c',
    'ñ': 'n',
  }.entries) {
    normalized = normalized.replaceAll(RegExp(entry.key), entry.value);
  }
  const singular = {
    'experiences': 'experience',
    'concerts': 'concert',
    'gardens': 'garden',
    'events': 'event',
    'plans': 'plan',
    'kids': 'kid',
    'adventures': 'adventure',
  };
  return normalized
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => singular[word] ?? word)
      .join(' ');
}

bool matchesEventQuery(Event event, String query) {
  final text = normalizeEventQuery(
    '${event.title} ${event.category} ${event.venue} ${event.city}',
  );
  final needle = normalizeEventQuery(query);
  switch (needle) {
    case 'on a budget':
      return event.price <= 25;
    case 'nightlife and party':
      return text.contains('night') || text.contains('rooftop');
    case 'romantic':
    case 'plan for two':
      return text.contains('candlelight') || text.contains('supper club');
    case 'relaxing':
      return event.category == 'Wellness';
    case 'artistic':
      return event.category == 'Culture';
    case 'music event':
    case 'concert':
      return event.category == 'Live Music';
    case 'candlelight concert':
      return text.contains('candlelight');
    case 'immersive experience':
      return text.contains('immersive');
    case 'family adventure':
    case 'with the kid':
      return event.category == 'Family';
    case 'art and culture':
      return event.category == 'Culture';
    case 'wellness and mindfulness':
      return event.category == 'Wellness';
  }
  return needle.isEmpty || needle.split(' ').every(text.contains);
}
