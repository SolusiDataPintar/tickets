import 'package:json_annotation/json_annotation.dart';

part 'address_info.g.dart';

@JsonSerializable(createToJson: false)
class CardanoAddressinfo {
  final String address;
  final int balance;
  final bool scriptAddress;
  final List<CardanoUtxoSet> utxoSets;

  CardanoAddressinfo(
    this.address,
    this.balance,
    this.scriptAddress,
    this.utxoSets,
  );

  factory CardanoAddressinfo.fromJson(final Map<String, dynamic> json) =>
      _$CardanoAddressinfoFromJson(json);
}

@JsonSerializable(createToJson: false)
class CardanoUtxoSet {
  final String txHash;
  final int txIndex;
  final String? paymentAddress;
  final String? stakeAddress;
  final String value;
  final String datumHash;
  final String? inlineDatum;
  final String? referenceScript;
  final List<CardanoUtxoSetAsset> assets;

  CardanoUtxoSet(
    this.txHash,
    this.txIndex,
    this.paymentAddress,
    this.stakeAddress,
    this.value,
    this.datumHash,
    this.inlineDatum,
    this.referenceScript,
    this.assets,
  );

  factory CardanoUtxoSet.fromJson(final Map<String, dynamic> json) =>
      _$CardanoUtxoSetFromJson(json);
}

@JsonSerializable(createToJson: false)
class CardanoUtxoSetAsset {
  @JsonKey(required: true, disallowNullValue: true)
  final String assetName;

  @JsonKey(required: true, disallowNullValue: true)
  final String fingerprint;

  @JsonKey(required: true, disallowNullValue: true)
  final String policyId;

  @JsonKey(required: true, disallowNullValue: true)
  final String quantity;

  CardanoUtxoSetAsset(
    this.assetName,
    this.fingerprint,
    this.policyId,
    this.quantity,
  );

  factory CardanoUtxoSetAsset.fromJson(final Map<String, dynamic> json) =>
      _$CardanoUtxoSetAssetFromJson(json);
}
