import 'dart:math';

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

  Notice({
    required this.title,
    required this.url,
    required this.date,
    required this.createdAt,
    required this.priority,
    required this.color,
    this.college,
    this.tags,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    json['color'] = Colors.primaries[Random().nextInt(Colors.primaries.length)]
        .withOpacity(0.3)
        .toHex();
    return _$NoticeFromJson(json);
  }
  Map<String, dynamic> toJson() => _$NoticeToJson(this);
}

class TimestampConverter implements JsonConverter<DateTime, Timestamp> {
  const TimestampConverter();

  @override
  DateTime fromJson(Timestamp timestamp) {
    return timestamp.toDate();
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
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}
