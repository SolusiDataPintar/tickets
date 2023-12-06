import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:injectable/injectable.dart';
import 'package:tickets/model/price.dart';
import 'package:tickets/provider/httpclient.dart';

part 'price.chopper.dart';

@Injectable()
@ChopperApi()
abstract class PriceService extends ChopperService {
  @FactoryMethod()
  static PriceService create(final HttpClient client) => _$PriceService(client);

  @FactoryConverter(response: _convertResponsePrice)
  @Get(path: "/price")
  Future<Response<Price>> get();
}

Response _convertResponsePrice(final Response res) => res.copyWith<Price>(
      body: Price.fromJson(
        jsonDecode(res.body as String) as Map<String, dynamic>,
      ),
    );
