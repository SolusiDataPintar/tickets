part of 'cubit.dart';

enum CardanoSendReceiverValidationError { empty }

final class CardanoSendReceiver
    extends FormzInput<String, CardanoSendReceiverValidationError> {
  const CardanoSendReceiver.pure() : super.pure('');
  const CardanoSendReceiver.dirty({required final String value})
      : super.dirty(value);

  @override
  CardanoSendReceiverValidationError? validator(final String value) {
    if (value.isEmpty) {
      return CardanoSendReceiverValidationError.empty;
    }
    return null;
  }
}

enum CardanoSendLovelaceValidationError { empty }

final class CardanoSendLovelace
    extends FormzInput<int, CardanoSendLovelaceValidationError> {
  const CardanoSendLovelace.pure() : super.pure(0);
  const CardanoSendLovelace.dirty({required final int value})
      : super.dirty(value);

  @override
  CardanoSendLovelaceValidationError? validator(final int value) {
    if (value < 2000000) {
      return CardanoSendLovelaceValidationError.empty;
    }
    return null;
  }
}

enum CardanoSendPasswordValidationError {
  empty,
  invalid,
  unknown,
}

final class CardanoSendPassword
    extends FormzInput<String, CardanoSendPasswordValidationError> {
  final CardanoSendPasswordValidationError? externalError;

  const CardanoSendPassword.pure()
      : externalError = null,
        super.pure('');
  const CardanoSendPassword.dirty({this.externalError, final String value = ''})
      : super.dirty(value);

  @override
  CardanoSendPasswordValidationError? validator(final String value) {
    if (externalError != null) {
      return externalError;
    } else if (value.isEmpty) {
      return CardanoSendPasswordValidationError.empty;
    } else {
      return null;
    }
  }
}
