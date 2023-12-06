import 'package:json_annotation/json_annotation.dart';
import 'package:tickets/model/cardano.dart';

part 'wallet.g.dart';

@JsonSerializable(createToJson: false)
class Balance {
  @JsonKey(required: true, disallowNullValue: true)
  final CardanoBalance cardano;
  const Balance(this.cardano);
  factory Balance.empty() => Balance(CardanoBalance.empty());
  factory Balance.fromJson(final Map<String, dynamic> json) =>
      _$BalanceFromJson(json);
}
