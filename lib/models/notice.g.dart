// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notice _$NoticeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const ['title', 'url', 'date', 'createdAt', 'priority'],
  );
  return Notice(
    title: json['title'] as String,
    url: json['url'] as String,
    date: json['date'] as String,
    createdAt:
        const TimestampConverter().fromJson(json['createdAt'] as Timestamp),
    priority: json['priority'] as bool,
  );
}

Map<String, dynamic> _$NoticeToJson(Notice instance) => <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'date': instance.date,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'priority': instance.priority,
    };
