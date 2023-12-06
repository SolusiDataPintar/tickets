import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:injectable/injectable.dart';
import 'package:tickets/model/account.dart';
import 'package:tickets/provider/httpclient.dart';

part 'account.chopper.dart';

@Injectable()
@ChopperApi()
abstract class AccountService extends ChopperService {
  @FactoryMethod()
  static AccountService create(final HttpClient client) =>
      _$AccountService(client);

  @FactoryConverter(
    request: _convertRequestSignUp,
    response: _convertResponseSignUp,
  )
  @Post(path: "/account")
  Future<Response<List<SignUpResponse>>> signUp(@Body() final String email);

  @Get(path: "/account/activation/{email}")
  Future<Response<void>> activation(@Path() final String email);
}

Request _convertRequestSignUp(final Request request) => request.copyWith(
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "emails": [request.body as String],
      }),
    );

Response _convertResponseSignUp(final Response res) =>
    res.copyWith<List<SignUpResponse>>(
      body: (jsonDecode(res.body as String) as List)
          .map((final e) => SignUpResponse.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
