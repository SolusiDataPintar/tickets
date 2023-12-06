import 'package:envied/envied.dart';

part 'config.g.dart';

const kGridSize = 150;

@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'AUTH_URL')
  static const String authUrl = _Env.authUrl;

  @EnviedField(varName: 'AUTH_ID')
  static const String authId = _Env.authId;

  @EnviedField(varName: 'AUTH_SECRET')
  static const String authSecret = _Env.authSecret;

  @EnviedField(varName: 'URL')
  static const String url = _Env.url;

  @EnviedField(varName: 'TICKET_URL')
  static const String ticketUrl = _Env.ticketUrl;
}
