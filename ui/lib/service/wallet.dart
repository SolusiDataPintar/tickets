import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:injectable/injectable.dart';
import 'package:tickets/model/address_info.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/model/wallet.dart';
import 'package:tickets/provider/httpclient.dart';

part 'wallet.chopper.dart';

@Injectable()
@ChopperApi()
abstract class WalletService extends ChopperService {
  @FactoryMethod()
  static WalletService create(final HttpClient client) =>
      _$WalletService(client);

  @Post(path: "/wallet/cardano/send")
  Future<Response<String>> send(@Body() final SendCardano data);

  @FactoryConverter(response: _convertResponseBalance)
  @Get(path: "/wallet/cardano/balance")
  Future<Response<Balance>> balance();

  @Get(path: "/wallet/cardano/address")
  Future<Response<List<String>>> cardanoAddresses();

  @Get(path: "/wallet/cardano/address/add")
  Future<Response<String>> addCardanoAddress();

  @FactoryConverter(response: _convertResponseCardanoAddressinfo)
  @Get(path: "/wallet/cardano/address/info/{address}")
  Future<Response<CardanoAddressinfo>> cardanoAddressInfo(
    @Path() final String address,
  );

  @FactoryConverter(response: _convertResponseCardanoAssetDetail)
  @Get(path: "/wallet/cardano/asset/{policyId}/{assetId}")
  Future<Response<CardanoAssetDetail>> cardanoAssetDetail(
    @Path() final String policyId,
    @Path() final String assetId,
  );
}

Response _convertResponseBalance(final Response res) {
  return res.copyWith<Balance>(
    body: Balance.fromJson(
      jsonDecode(res.body as String) as Map<String, dynamic>,
    ),
  );
}

Response _convertResponseCardanoAddressinfo(final Response res) {
  return res.copyWith<CardanoAddressinfo>(
    body: CardanoAddressinfo.fromJson(
      jsonDecode(res.body as String) as Map<String, dynamic>,
    ),
  );
}

Response _convertResponseCardanoAssetDetail(final Response res) {
  return res.copyWith<CardanoAssetDetail>(
    body: CardanoAssetDetail.fromJson(
      jsonDecode(res.body as String) as Map<String, dynamic>,
    ),
  );
}
