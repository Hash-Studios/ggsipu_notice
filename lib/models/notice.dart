import 'package:json_annotation/json_annotation.dart';

part 'notice.g.dart';

@JsonSerializable(explicitToJson: true, fieldRename: FieldRename.snake)
class Notice {
  @JsonKey(required: true)
  String title;
  @JsonKey(required: true)
  String url;
  @JsonKey(required: true)
  String date;
  @JsonKey(required: true)
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
