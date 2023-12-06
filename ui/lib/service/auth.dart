import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:injectable/injectable.dart';
import 'package:tickets/model/auth.dart';
import 'package:tickets/provider/httpclient.dart';

part 'auth.chopper.dart';

@Injectable()
@ChopperApi()
abstract class AuthService extends ChopperService {
  @FactoryMethod()
  static AuthService create(final AuthHttpClient client) =>
      _$AuthService(client);

  @FactoryConverter(
    request: _convertRequestSignIn,
    response: _convertResponseSignIn,
  )
  @Post(path: "/protocol/openid-connect/token")
  Future<Response<TokenPair>> signIn(@Body() final SignIn body);
}

Future<Request> _convertRequestSignIn(final Request request) async {
  final headers = request.headers;
  headers['Content-Type'] = 'application/x-www-form-urlencoded';
  final body = request.body as SignIn;
  final bodyMap = body.toJson();
  final bodyMapStr = <String, String>{};
  for (final entry in bodyMap.entries) {
    bodyMapStr[entry.key] = entry.value as String;
  }
  return request.copyWith(headers: headers, body: bodyMapStr);
}

Future<Response> _convertResponseSignIn(final Response res) async {
  return res.copyWith<TokenPair>(
    body: TokenPair.fromJson(
      jsonDecode(res.body as String) as Map<String, dynamic>,
    ),
  );
}
