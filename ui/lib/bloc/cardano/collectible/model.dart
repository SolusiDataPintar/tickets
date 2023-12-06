part of 'cubit.dart';

sealed class CardanoCollectibleAssetMetaDataStatus extends Equatable {
  const CardanoCollectibleAssetMetaDataStatus();
  @override
  List<Object?> get props => [];
}

final class CardanoCollectibleAssetMetaDataStatusLoading
    extends CardanoCollectibleAssetMetaDataStatus {
  const CardanoCollectibleAssetMetaDataStatusLoading();
  @override
  List<Object?> get props => [];
}

final class CardanoCollectibleAssetMetaDataStatusSuccess
    extends CardanoCollectibleAssetMetaDataStatus {
  final CardanoAssetMetaData detail;
  const CardanoCollectibleAssetMetaDataStatusSuccess(this.detail);
  @override
  List<Object?> get props => [detail];
}

final class CardanoCollectibleAssetMetaDataStatusFailure
    extends CardanoCollectibleAssetMetaDataStatus {
  final dynamic err;
  final StackTrace st;
  const CardanoCollectibleAssetMetaDataStatusFailure(this.err, this.st);
  @override
  List<Object?> get props => [err, st];
}

sealed class CardanoCollectibleCodeStatus extends Equatable {
  const CardanoCollectibleCodeStatus();
  @override
  List<Object?> get props => [];
}

final class CardanoCollectibleCodeStatusLoading
    extends CardanoCollectibleCodeStatus {
  const CardanoCollectibleCodeStatusLoading();
}

final class CardanoCollectibleCodeStatusSuccess
    extends CardanoCollectibleCodeStatus {
  final CardanoAssetCodeBase64 code;
  const CardanoCollectibleCodeStatusSuccess(this.code);
  @override
  List<Object?> get props => [code];
}

final class CardanoCollectibleCodeStatusFailure
    extends CardanoCollectibleCodeStatus {
  final dynamic err;
  final StackTrace st;
  const CardanoCollectibleCodeStatusFailure(this.err, this.st);
  @override
  List<Object?> get props => [err, st];
}

sealed class CardanoCollectibleShowScannedDialogStatus extends Equatable {
  const CardanoCollectibleShowScannedDialogStatus();
  @override
  List<Object?> get props => [];
}
