import 'package:cloud_firestore/cloud_firestore.dart';
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

  Notice({
    required this.title,
    required this.url,
    required this.date,
    required this.createdAt,
    required this.priority,
  });

  factory Notice.fromJson(Map<String, dynamic> json) => _$NoticeFromJson(json);
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
