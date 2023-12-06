part of 'cubit.dart';

final class CardanoSendState extends Equatable {
  const CardanoSendState({
    this.receiver = const CardanoSendReceiver.pure(),
    this.lovelace = const CardanoSendLovelace.pure(),
    this.password = const CardanoSendPassword.pure(),
    this.selectedAssets = const [],
    this.isValid = false,
    this.status = FormzSubmissionStatus.initial,
    this.transactionHash = "",
  });

  final CardanoSendReceiver receiver;
  final CardanoSendLovelace lovelace;
  final CardanoSendPassword password;
  final List<CardanoAssetDetail> selectedAssets;
  final bool isValid;
  final FormzSubmissionStatus status;
  final String transactionHash;

  CardanoSendState copyWith({
    final CardanoSendReceiver? receiver,
    final CardanoSendLovelace? lovelace,
    final CardanoSendPassword? password,
    final List<CardanoAssetDetail>? selectedAssets,
    final bool? isValid,
    final FormzSubmissionStatus? status,
    final String? transactionHash,
  }) =>
      CardanoSendState(
        receiver: receiver ?? this.receiver,
        lovelace: lovelace ?? this.lovelace,
        password: password ?? this.password,
        selectedAssets: selectedAssets ?? this.selectedAssets,
        isValid: isValid ?? this.isValid,
        status: status ?? this.status,
        transactionHash: transactionHash ?? this.transactionHash,
      );

  @override
  List<Object> get props => [
        receiver,
        lovelace,
        password,
        selectedAssets,
        status,
        transactionHash,
      ];
}
