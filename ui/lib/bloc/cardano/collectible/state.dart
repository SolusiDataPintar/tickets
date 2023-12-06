part of 'cubit.dart';

final class CardanoCollectibleState extends Equatable {
  final CardanoCollectibleAssetMetaDataStatus assetMetaData;
  final CardanoCollectibleCodeStatus code;
  final List<Redeemable> redeemableList;
  final Item? itemDialog;

  const CardanoCollectibleState({
    this.assetMetaData = const CardanoCollectibleAssetMetaDataStatusLoading(),
    this.code = const CardanoCollectibleCodeStatusLoading(),
    this.redeemableList = const [],
    this.itemDialog,
  });

  CardanoCollectibleState copyWith({
    final CardanoCollectibleAssetMetaDataStatus? assetMetaData,
    final CardanoCollectibleCodeStatus? code,
    final List<Redeemable>? redeemableList,
    final Item? itemDialog,
  }) =>
      CardanoCollectibleState(
        assetMetaData: assetMetaData ?? this.assetMetaData,
        code: code ?? this.code,
        redeemableList: redeemableList ?? this.redeemableList,
        itemDialog: itemDialog,
      );

  @override
  List<Object?> get props => [assetMetaData, code, redeemableList, itemDialog];
}
