// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notice.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notice _$NoticeFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    requiredKeys: const [
      'title',
      'url',
      'date',
      'createdAt',
      'priority',
      'color'
    ],
  );
  return Notice(
    title: json['title'] as String,
    url: json['url'] as String,
    date: json['date'] as String,
    createdAt:
        const TimestampConverter().fromJson(json['createdAt'] as Timestamp),
    priority: json['priority'] as bool,
    color: json['color'] as String,
    college: json['college'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String?).toList(),
  );
}

Map<String, dynamic> _$NoticeToJson(Notice instance) => <String, dynamic>{
      'title': instance.title,
      'url': instance.url,
      'date': instance.date,
      'createdAt': const TimestampConverter().toJson(instance.createdAt),
      'priority': instance.priority,
      'color': instance.color,
      'college': instance.college,
      'tags': instance.tags,
    };
