import 'package:json_annotation/json_annotation.dart';

class DurationSecondConverter implements JsonConverter<Duration, int> {
  const DurationSecondConverter();
  @override
  Duration fromJson(final int json) => Duration(seconds: json);
  @override
  int toJson(final Duration object) => object.inSeconds;
}

class EpochDateTimeConverter implements JsonConverter<DateTime, int> {
  const EpochDateTimeConverter();
  @override
  DateTime fromJson(final int json) =>
      DateTime.fromMillisecondsSinceEpoch(json);
  @override
  int toJson(final DateTime object) => object.millisecondsSinceEpoch;
}
