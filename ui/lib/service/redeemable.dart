import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:tickets/config/config.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/model/nft.dart';
import 'package:tickets/provider/httpclient.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/provider/session.dart';

part 'redeemable.chopper.dart';

@Injectable()
@ChopperApi()
abstract class RedeemableService extends ChopperService {
  @FactoryMethod()
  static RedeemableService create(final TicketHttpClient client) =>
      _$RedeemableService(client);

  @FactoryConverter(response: _convertResponseAssetCodeBase64)
  @Get(path: "/redeemable/code/{address}/{policyId}/{assetId}")
  Future<Response<CardanoAssetCodeBase64>> qr(
    @Path() final String address,
    @Path() final String policyId,
    @Path() final String assetId,
  );

  @FactoryConverter(response: _convertResponseRedeemableList)
  @Get(path: "/redeemable/{policyId}/{assetId}")
  Future<Response<List<Redeemable>>> find(
    @Path() final String policyId,
    @Path() final String assetId,
  );

  Stream<CardanoRedeemEvent> streamRedeemEvent({
    required final http.Client httpClient,
    required final String policyId,
    required final String assetId,
  }) async* {
    final req = http.Request(
      'GET',
      Uri.parse('${Env.ticketUrl}/redeemable/stream/$policyId/$assetId'),
    );
    req.headers['Cache-Control'] = 'no-store, no-cache';
    req.headers['Accept'] = 'text/event-stream';
    req.headers['Authorization'] = getIt<SessionProvider>().accessToken();
    final res = await httpClient.send(req);
    await for (final v in res.stream.toStringStream()) {
      yield CardanoRedeemEvent.fromJson(jsonDecode(v) as Map<String, dynamic>);
    }
  }
}

Response _convertResponseAssetCodeBase64(final Response res) {
  return res.copyWith<CardanoAssetCodeBase64>(
    body: CardanoAssetCodeBase64(res.bodyString),
  );
}

Response _convertResponseRedeemableList(final Response res) {
  return res.copyWith<List<Redeemable>>(
    body: (jsonDecode(res.body as String) as List)
        .map((final e) => Redeemable.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}
