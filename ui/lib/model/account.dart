import 'package:json_annotation/json_annotation.dart';

part 'account.g.dart';

@JsonSerializable(createToJson: false)
class SignUpResponse {
  @JsonKey(required: true, disallowNullValue: true)
  final bool success;

  @JsonKey(required: true, disallowNullValue: true)
  final String email;

  @JsonKey(required: true, disallowNullValue: true)
  final String error;

  SignUpResponse(this.success, this.email, this.error);
  factory SignUpResponse.fromJson(final Map<String, dynamic> json) =>
      _$SignUpResponseFromJson(json);
}
