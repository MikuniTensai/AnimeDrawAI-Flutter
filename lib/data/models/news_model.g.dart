// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsItem _$NewsItemFromJson(Map<String, dynamic> json) => NewsItem(
  id: json['id'] as String?,
  type: json['type'] as String,
  title: json['title'] as String,
  description: json['description'] as String,
  date: const TimestampConverter().fromJson(json['date']),
  imageUrl: json['imageUrl'] as String?,
  actionUrl: json['actionUrl'] as String?,
  version: json['version'] as String?,
);

Map<String, dynamic> _$NewsItemToJson(NewsItem instance) => <String, dynamic>{
  'id': instance.id,
  'type': instance.type,
  'title': instance.title,
  'description': instance.description,
  'date': const TimestampConverter().toJson(instance.date),
  'imageUrl': instance.imageUrl,
  'actionUrl': instance.actionUrl,
  'version': instance.version,
};
