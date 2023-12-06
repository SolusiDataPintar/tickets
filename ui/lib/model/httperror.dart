import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'httperror.g.dart';

@JsonSerializable()
class HttpError implements Exception {
  final int? code;
  final String message;
  HttpError(this.code, this.message);
  factory HttpError.fromJson(final Map<String, dynamic> json) =>
      _$HttpErrorFromJson(json);

  @override
  String toString() =>
      const JsonEncoder.withIndent('  ').convert(_$HttpErrorToJson(this));
}
