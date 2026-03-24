import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'notice.g.dart';

@JsonSerializable(explicitToJson: true)
class Notice {
  @JsonKey(required: true)
  String title;
  @JsonKey(required: true)
  String url;
  @JsonKey(required: true)
  String date;
  @JsonKey(required: true)
  @TimestampConverter()
  DateTime createdAt;
  @JsonKey(required: true)
  bool priority;
  @JsonKey(required: true)
  String color;
  @JsonKey()
  String? college;
  @JsonKey()
  List<String?>? tags;
  @JsonKey(defaultValue: false)
  bool isArchived;

  Notice({
    required this.title,
    required this.url,
    required this.date,
    required this.createdAt,
    required this.priority,
    required this.color,
    this.college,
    this.tags,
    this.isArchived = false,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    final seed = (json['title'] as String? ?? json['url'] as String? ?? '').hashCode.abs();
    json['color'] = Colors.primaries[seed % Colors.primaries.length]
        .withValues(alpha: 0.3)
        .toHex();
    // Algolia hits don't have createdAt — fall back to parsing the date string
    if (!json.containsKey('createdAt') || json['createdAt'] == null) {
      json['createdAt'] = _dateStringToMillis(json['date'] as String? ?? '');
    }
    return _$NoticeFromJson(json);
  }

  static int _dateStringToMillis(String date) {
    try {
      final parts = date.split('-');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      ).millisecondsSinceEpoch;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }
  Map<String, dynamic> toJson() => _$NoticeToJson(this);
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Object timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is String) {
      return DateTime.parse(timestamp.toString());
    } else {
      return DateTime.fromMillisecondsSinceEpoch(timestamp as int);
    }
  }

  @override
  Timestamp toJson(DateTime date) => Timestamp.fromDate(date);
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${(a * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(r * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(g * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}'
      '${(b * 255.0).round().clamp(0, 255).toRadixString(16).padLeft(2, '0')}';
}
