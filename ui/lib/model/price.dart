import 'package:json_annotation/json_annotation.dart';

part 'price.g.dart';

@JsonSerializable(createToJson: false)
class Price {
  final PriceDetail cardano;
  const Price({this.cardano = const PriceDetail(0.0)});
  factory Price.fromJson(final Map<String, dynamic> json) =>
      _$PriceFromJson(json);
}

@JsonSerializable(createToJson: false)
class PriceDetail {
  final double idr;
  const PriceDetail(this.idr);
  factory PriceDetail.fromJson(final Map<String, dynamic> json) =>
      _$PriceDetailFromJson(json);
}
