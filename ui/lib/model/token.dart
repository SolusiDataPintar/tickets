import 'package:equatable/equatable.dart';
import 'package:tickets/cardano/cardano.dart';
import 'package:tickets/model/cardano.dart';

sealed class Token extends Equatable {
  final String name;
  final String balance;
  final String image;
  const Token(this.name, this.balance, this.image);
  @override
  List<Object?> get props => [name, balance, image];
}

class AdaToken extends Token {
  AdaToken(final CardanoBalance balance)
      : super(
          "Cardano",
          "${lovelaceToAda(balance.coin.toDouble())} ADA",
          "https://chainsmart.obs.ap-southeast-4.myhuaweicloud.com/wallet/public/cardano.png",
        );
}
