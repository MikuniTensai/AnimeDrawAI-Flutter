import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'news_model.g.dart';

@JsonSerializable()
class NewsItem {
  final String? id;
  final String type; // "event", "update", "info"
  final String title;
  final String description;
  @TimestampConverter()
  final DateTime? date;
  final String? imageUrl;
  final String? actionUrl;
  final String? version;

  NewsItem({
    this.id,
    required this.type,
    required this.title,
    required this.description,
    this.date,
    this.imageUrl,
    this.actionUrl,
    this.version,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) =>
      _$NewsItemFromJson(json);
  Map<String, dynamic> toJson() => _$NewsItemToJson(this);

  NewsItem copyWith({String? id}) {
    return NewsItem(
      id: id ?? this.id,
      type: type,
      title: title,
      description: description,
      date: date,
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      version: version,
    );
  }
}

class TimestampConverter implements JsonConverter<DateTime?, dynamic> {
  const TimestampConverter();

  @override
  DateTime? fromJson(dynamic json) {
    if (json is Timestamp) return json.toDate();
    return null;
  }

  @override
  dynamic toJson(DateTime? date) =>
      date != null ? Timestamp.fromDate(date) : null;
}
