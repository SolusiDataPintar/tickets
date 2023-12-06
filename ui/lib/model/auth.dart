import 'package:json_annotation/json_annotation.dart';
import 'package:tickets/model/duration_second_converter.dart';

part 'auth.g.dart';

@JsonSerializable()
class SignIn {
  @JsonKey(name: 'grant_type', required: true, disallowNullValue: true)
  final String grantType;

  @JsonKey(name: 'client_id', required: true, disallowNullValue: true)
  final String clientId;

  @JsonKey(name: 'client_secret', required: true, disallowNullValue: true)
  final String clientSecret;

  @JsonKey(name: 'username', required: true, disallowNullValue: true)
  final String username;

  @JsonKey(name: 'password', required: true, disallowNullValue: true)
  final String password;

  @JsonKey(name: 'scope', required: true, disallowNullValue: true)
  final String scope;

  SignIn({
    required this.grantType,
    required this.clientId,
    required this.clientSecret,
    required this.username,
    required this.password,
    required this.scope,
  });

  factory SignIn.fromJson(final Map<String, dynamic> json) =>
      _$SignInFromJson(json);

  Map<String, dynamic> toJson() => _$SignInToJson(this);
}

@JsonSerializable(createToJson: false)
class TokenPair {
  @JsonKey(name: "access_token", required: true, disallowNullValue: true)
  final String accessToken;

  @JsonKey(name: "refresh_token", required: true, disallowNullValue: true)
  final String refreshToken;

  @DurationSecondConverter()
  @JsonKey(name: "expires_in", required: true, disallowNullValue: true)
  final Duration expireIn;

  @DurationSecondConverter()
  @JsonKey(name: "refresh_expires_in", required: true, disallowNullValue: true)
  final Duration refreshExpiresIn;

  TokenPair(
    this.accessToken,
    this.refreshToken,
    this.expireIn,
    this.refreshExpiresIn,
  );

  factory TokenPair.fromJson(final Map<String, dynamic> json) =>
      _$TokenPairFromJson(json);
}
