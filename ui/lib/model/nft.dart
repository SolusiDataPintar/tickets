import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tickets/model/cardano.dart';

part 'nft.g.dart';

@JsonSerializable(createToJson: false)
class Item extends Equatable {
  @JsonKey(required: true, disallowNullValue: true)
  final int id;

  @JsonKey(required: true, disallowNullValue: true)
  final String name;

  @JsonKey(required: false, disallowNullValue: false, defaultValue: "-")
  final String description;

  @JsonKey(required: true, disallowNullValue: true)
  final DateTime createdAt;

  @JsonKey(required: true, disallowNullValue: true)
  final DateTime updatedAt;

  const Item(
    this.id,
    this.name,
    this.description,
    this.createdAt,
    this.updatedAt,
  );

  factory Item.fromJson(final Map<String, dynamic> json) =>
      _$ItemFromJson(json);

  @override
  List<Object?> get props => [id, name, description, createdAt, updatedAt];
}

@JsonSerializable(createToJson: false)
class RedeemableEdges {
  @JsonKey(required: true, disallowNullValue: true)
  final Item item;

  RedeemableEdges(this.item);

  factory RedeemableEdges.fromJson(final Map<String, dynamic> json) =>
      _$RedeemableEdgesFromJson(json);
}

@JsonSerializable(createToJson: false)
class Redeemable {
  @JsonKey(required: true, disallowNullValue: true)
  final int id;

  @JsonKey(required: true, disallowNullValue: true)
  final String policyId;

  @JsonKey(required: true, disallowNullValue: true)
  final String assetId;

  @JsonKey(required: true, disallowNullValue: true)
  final int itemId;

  @JsonKey(required: true, disallowNullValue: false)
  final DateTime? redeemedAt;

  @JsonKey(required: true, disallowNullValue: true)
  final DateTime createdAt;

  @JsonKey(required: true, disallowNullValue: true)
  final DateTime updatedAt;

  @JsonKey(required: true, disallowNullValue: true)
  final RedeemableEdges edges;

  Redeemable(
    this.id,
    this.policyId,
    this.assetId,
    this.itemId,
    this.redeemedAt,
    this.createdAt,
    this.updatedAt,
    this.edges,
  );

  factory Redeemable.fromJson(final Map<String, dynamic> json) =>
      _$RedeemableFromJson(json);
}

@JsonSerializable(createToJson: false)
class RedeemResult {
  @JsonKey(required: true, disallowNullValue: true)
  final CardanoAssetDetail asset;

  @JsonKey(required: true, disallowNullValue: false)
  final Redeemable? redeemable;

  @JsonKey(required: true, disallowNullValue: true)
  final List<Redeemable> redeemableList;

  RedeemResult(this.asset, this.redeemable, this.redeemableList);

  factory RedeemResult.fromJson(final Map<String, dynamic> json) =>
      _$RedeemResultFromJson(json);
}
