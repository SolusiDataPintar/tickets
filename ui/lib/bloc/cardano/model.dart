part of 'cubit.dart';

sealed class CardanoBalanceStatus extends Equatable {
  const CardanoBalanceStatus();
  @override
  List<Object?> get props => [];
}

final class CardanoBalanceStatusLoading extends CardanoBalanceStatus {
  const CardanoBalanceStatusLoading();
}

final class CardanoBalanceStatusSuccess extends CardanoBalanceStatus {
  final Balance balance;
  final double totalBalance;
  const CardanoBalanceStatusSuccess({
    required this.balance,
    required this.totalBalance,
  });
  @override
  List<Object?> get props => [balance, totalBalance];
}

final class CardanoBalanceStatusFailure extends CardanoBalanceStatus {
  final dynamic error;
  final StackTrace st;
  const CardanoBalanceStatusFailure(this.error, this.st);
  @override
  List<Object?> get props => [error, st];
}

sealed class CardanoAssetStatus extends Equatable {
  final CardanoAsset asset;
  const CardanoAssetStatus({required this.asset});
  @override
  List<Object?> get props => [asset];
}

final class CardanoAssetStatusLoading extends CardanoAssetStatus {
  const CardanoAssetStatusLoading({required super.asset});
  @override
  List<Object?> get props => [asset];
}

final class CardanoAssetStatusSuccess extends CardanoAssetStatus {
  final CardanoAssetDetail detail;
  const CardanoAssetStatusSuccess({
    required super.asset,
    required this.detail,
  });
  @override
  List<Object?> get props => [asset, detail];
}

final class CardanoAssetStatusFailure extends CardanoAssetStatus {
  final dynamic error;
  final StackTrace st;
  const CardanoAssetStatusFailure({
    required super.asset,
    required this.error,
    required this.st,
  });
  @override
  List<Object?> get props => [asset, error, st];
}

sealed class CardanoAddressListStatus extends Equatable {
  const CardanoAddressListStatus();
  @override
  List<Object?> get props => [];
}

final class CardanoAddressListStatusLoading extends CardanoAddressListStatus {
  const CardanoAddressListStatusLoading();
}

final class CardanoAddressListStatusSuccess extends CardanoAddressListStatus {
  final List<String> addressList;
  const CardanoAddressListStatusSuccess(this.addressList);
  @override
  List<Object?> get props => [addressList];
}

final class CardanoAddressListStatusFailure extends CardanoAddressListStatus {
  final dynamic error;
  final StackTrace st;
  const CardanoAddressListStatusFailure({
    required this.error,
    required this.st,
  });
  @override
  List<Object?> get props => [error, st];
}
