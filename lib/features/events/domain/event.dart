import 'package:flutter/material.dart';

import 'json_validation.dart';

class Event {
  const Event(
    this.id,
    this.title,
    this.category,
    this.venue,
    this.price,
    this.rating,
    this.image,
    this.color, {
    this.city = 'London',
    this.duration = 60,
    this.reviewCount = 1248,
    this.isOriginal = false,
    this.trendingRank,
    this.gallery = const [],
    this.description = '',
  });

  final String id, title, category, venue, city, image, description;
  final double price, rating;
  final int duration, reviewCount;
  final int? trendingRank;
  final bool isOriginal;
  final Color color;
  final List<String> gallery;
  List<String> get images => gallery.isEmpty ? [image] : gallery;

  factory Event.fromJson(Map<String, dynamic> json) {
    final rawGallery = json.containsKey('gallery')
        ? json['gallery']
        : const <String>[];
    if (rawGallery is! List)
      throw const FormatException('gallery must be a list of image paths');
    return Event(
      jsonString(json['id'], 'id'),
      jsonString(json['title'], 'title'),
      jsonString(json['category'], 'category'),
      jsonString(json['venue'], 'venue'),
      jsonNumber(json['price'], 'price'),
      jsonNumber(json['rating'], 'rating', max: 5),
      jsonString(json['image'], 'image'),
      Color(jsonInteger(json['color'], 'color', max: 0xffffffff)),
      city: jsonString(
        json.containsKey('city') ? json['city'] : 'London',
        'city',
      ),
      duration: jsonInteger(
        json.containsKey('duration') ? json['duration'] : 60,
        'duration',
        min: 1,
      ),
      reviewCount: jsonInteger(
        json.containsKey('reviewCount') ? json['reviewCount'] : 1248,
        'reviewCount',
      ),
      isOriginal: jsonBool(
        json.containsKey('isOriginal') ? json['isOriginal'] : false,
        'isOriginal',
      ),
      trendingRank: json['trendingRank'] == null
          ? null
          : jsonInteger(json['trendingRank'], 'trendingRank', min: 1),
      gallery: List<String>.unmodifiable(
        rawGallery.map((value) => jsonString(value, 'gallery image')),
      ),
      description:
          json.containsKey('description') && json['description'] is String
          ? (json['description'] as String)
          : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'venue': venue,
    'price': price,
    'rating': rating,
    'image': image,
    'color': color.toARGB32(),
    'city': city,
    'duration': duration,
    'reviewCount': reviewCount,
    'isOriginal': isOriginal,
    'trendingRank': trendingRank,
    'gallery': List<String>.of(gallery),
    'description': description,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Event && other.id == id;
  @override
  int get hashCode => Object.hash(Event, id);
}

class City {
  const City(this.name, this.country);
  final String name, country;

  factory City.fromJson(Map<String, dynamic> json) => City(
    jsonString(json['name'], 'name'),
    jsonString(json['country'], 'country'),
  );
  Map<String, dynamic> toJson() => {'name': name, 'country': country};
}

class Review {
  const Review(this.name, this.date, this.text, {this.rating = 5});
  final String name, date, text;
  final double rating;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
    jsonString(json['name'], 'name'),
    jsonString(json['date'], 'date'),
    jsonString(json['text'], 'text'),
    rating: jsonNumber(
      json.containsKey('rating') ? json['rating'] : 5,
      'rating',
      max: 5,
    ),
  );
  Map<String, dynamic> toJson() => {
    'name': name,
    'date': date,
    'text': text,
    'rating': rating,
  };
}

class Faq {
  const Faq(this.question, this.answer);
  final String question, answer;

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
    jsonString(json['question'], 'question'),
    jsonString(json['answer'], 'answer'),
  );
  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
}
