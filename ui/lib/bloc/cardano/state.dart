part of 'cubit.dart';

final class CardanoState extends Equatable {
  final CardanoBalanceStatus balance;
  final Iterable<CardanoAssetStatus> nftList;
  final Iterable<Token> tokenList;
  final CardanoAddressListStatus addressList;

  const CardanoState({
    this.balance = const CardanoBalanceStatusLoading(),
    this.nftList = const [],
    this.tokenList = const [],
    this.addressList = const CardanoAddressListStatusLoading(),
  });

  CardanoState copyWith({
    final CardanoBalanceStatus? balance,
    final List<CardanoAssetStatus>? nftList,
    final List<Token>? tokenList,
    final CardanoAddressListStatus? addressList,
  }) =>
      CardanoState(
        balance: balance ?? this.balance,
        nftList: nftList ?? this.nftList,
        tokenList: tokenList ?? this.tokenList,
        addressList: addressList ?? this.addressList,
      );

  @override
  List<Object?> get props => [balance, nftList, tokenList, addressList];
}
