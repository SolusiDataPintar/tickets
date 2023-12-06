import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tickets/model/duration_second_converter.dart';

part 'cardano.g.dart';

@JsonSerializable()
class SendCardano {
  @JsonKey(required: true, disallowNullValue: true)
  final String password;

  @JsonKey(required: true, disallowNullValue: true)
  final String receiver;

  @JsonKey(required: true, disallowNullValue: true)
  final int coin;

  @JsonKey(required: true, disallowNullValue: true)
  final List<CardanoAsset> assets;

  SendCardano({
    required this.password,
    required this.receiver,
    required this.coin,
    required this.assets,
  });
  factory SendCardano.fromJson(final Map<String, dynamic> json) =>
      _$SendCardanoFromJson(json);
  Map<String, dynamic> toJson() => _$SendCardanoToJson(this);
}

@JsonSerializable()
class CardanoAsset extends Equatable {
  @JsonKey(required: true, disallowNullValue: true)
  final String policyId;

  @JsonKey(required: true, disallowNullValue: true)
  final String assetName;

  @JsonKey(required: true, disallowNullValue: true)
  final int qty;

  const CardanoAsset(this.policyId, this.assetName, this.qty);
  factory CardanoAsset.fromJson(final Map<String, dynamic> json) =>
      _$CardanoAssetFromJson(json);
  Map<String, dynamic> toJson() => _$CardanoAssetToJson(this);

  @override
  List<Object?> get props => [policyId, assetName, qty];
}

@JsonSerializable(createToJson: false)
class CardanoBalance extends Equatable {
  @JsonKey(required: true, disallowNullValue: true)
  final int coin;

  @JsonKey(required: true, disallowNullValue: true)
  final List<CardanoAsset> assets;

  const CardanoBalance(this.coin, this.assets);
  factory CardanoBalance.empty() => const CardanoBalance(0, []);
  factory CardanoBalance.fromJson(final Map<String, dynamic> json) =>
      _$CardanoBalanceFromJson(json);

  @override
  List<Object?> get props => [coin, assets];
}

@JsonSerializable(createToJson: false)
class CardanoAssetDetail extends Equatable {
  @JsonKey(required: true, disallowNullValue: true)
  final String policyId;

  @JsonKey(required: true, disallowNullValue: true)
  final String assetId;

  @JsonKey(required: true, disallowNullValue: true)
  final String assetName;

  @JsonKey(required: true, disallowNullValue: true)
  final String fingerprint;

  @JsonKey(required: true, disallowNullValue: true)
  final String mintingTxHash;

  @JsonKey(required: true, disallowNullValue: true)
  final String totalSupply;

  @JsonKey(required: true, disallowNullValue: true)
  final int mintCnt;

  @JsonKey(required: true, disallowNullValue: true)
  final int burnCnt;

  @JsonKey(required: true, disallowNullValue: true)
  @EpochDateTimeConverter()
  final DateTime creationTime;

  @JsonKey(required: true, disallowNullValue: true)
  final Map<String, dynamic> mintingTxMetaData;

  const CardanoAssetDetail(
    this.policyId,
    this.assetId,
    this.assetName,
    this.fingerprint,
    this.mintingTxHash,
    this.totalSupply,
    this.mintCnt,
    this.burnCnt,
    this.creationTime,
    this.mintingTxMetaData,
  );

  factory CardanoAssetDetail.fromJson(final Map<String, dynamic> json) =>
      _$CardanoAssetDetailFromJson(json);

  @override
  List<Object?> get props => [
        policyId,
        assetId,
        assetName,
        fingerprint,
        mintingTxHash,
        totalSupply,
        mintCnt,
        burnCnt,
        creationTime,
        mintingTxMetaData,
      ];
}

class AssetMetaDataNotFound implements Exception {
  String cause;
  AssetMetaDataNotFound(this.cause);
}

@JsonSerializable(createToJson: false)
class CardanoAssetMetaData {
  @JsonKey(required: true, disallowNullValue: true)
  final String name;

  @JsonKey(required: true, disallowNullValue: true)
  final String image;

  @JsonKey(required: true, disallowNullValue: true)
  final String website;

  @JsonKey(required: true, disallowNullValue: true)
  final String copyright;

  @JsonKey(required: true, disallowNullValue: true)
  final String mediaType;

  @JsonKey(required: true, disallowNullValue: true)
  final String publisher;

  @JsonKey(required: true, disallowNullValue: true)
  final dynamic description;

  CardanoAssetMetaData(
    this.name,
    this.image,
    this.website,
    this.copyright,
    this.mediaType,
    this.publisher,
    this.description,
  );

  factory CardanoAssetMetaData.fromJson(final Map<String, dynamic> json) =>
      _$CardanoAssetMetaDataFromJson(json);
  factory CardanoAssetMetaData.fromAssetDetailForNft(
    final CardanoAssetDetail asset,
  ) {
    if (!asset.mintingTxMetaData.containsKey("721")) {
      throw AssetMetaDataNotFound("asset meta data has no key 721");
    }

    final nfts = asset.mintingTxMetaData["721"] as Map<String, dynamic>;
    if (!nfts.containsKey(asset.policyId)) {
      throw AssetMetaDataNotFound(
        "asset meta data has no policy id ${asset.policyId}",
      );
    }
    return CardanoAssetMetaData.fromJson(
      (nfts[asset.policyId] as Map<String, dynamic>).values.first,
    );
  }
}

@JsonSerializable(createToJson: false)
class CardanoAssetCode {
  @JsonKey(required: true, disallowNullValue: true)
  final String policyId;

  @JsonKey(required: true, disallowNullValue: true)
  final String assetId;

  @JsonKey(required: true, disallowNullValue: true)
  final String code;

  @JsonKey(required: true, disallowNullValue: true)
  final DateTime expiredAt;

  CardanoAssetCode(this.policyId, this.assetId, this.code, this.expiredAt);

  factory CardanoAssetCode.fromJson(final Map<String, dynamic> json) =>
      _$CardanoAssetCodeFromJson(json);
}

class CardanoAssetCodeBase64 {
  final String code;
  final CardanoAssetCode asset;

  CardanoAssetCodeBase64(this.code)
      : asset = CardanoAssetCode.fromJson(
          jsonDecode(utf8.decode(base64Decode(code))),
        );
}

@JsonSerializable(createToJson: false)
class CardanoRedeemEvent {
  @JsonKey(required: true, disallowNullValue: true)
  final String policyId;

  @JsonKey(required: true, disallowNullValue: true)
  final String assetId;

  @JsonKey(required: true, disallowNullValue: true)
  final String code;

  @JsonKey(required: true, disallowNullValue: true)
  final int itemId;

  CardanoRedeemEvent(this.policyId, this.assetId, this.code, this.itemId);
  factory CardanoRedeemEvent.fromJson(final Map<String, dynamic> json) =>
      _$CardanoRedeemEventFromJson(json);
}
