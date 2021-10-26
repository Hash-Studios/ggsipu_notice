// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notice _$NoticeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['title', 'url', 'date', 'created_at', 'priority'],
  );
  return Notice(
    title: json['title'] as String,
    url: json['url'] as String,
    date: json['date'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
    priority: json['priority'] as bool,
  );
}

Map<String, dynamic> _$NoticeToJson(Notice instance) => <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'date': instance.date,
      'created_at': instance.createdAt.toIso8601String(),
      'priority': instance.priority,
    };
