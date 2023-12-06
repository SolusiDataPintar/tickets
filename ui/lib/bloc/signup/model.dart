part of 'bloc.dart';

enum SignUpEmailValidationError { empty, invalid, unknown }

final class SignUpEmail extends FormzInput<String, SignUpEmailValidationError> {
  const SignUpEmail.pure()
      : externalError = null,
        super.pure('');
  const SignUpEmail.dirty({
    required final String value,
    this.externalError,
  }) : super.dirty(value);

  final SignUpEmailValidationError? externalError;

  @override
  SignUpEmailValidationError? validator(final String value) {
    if (value.isEmpty) {
      return SignUpEmailValidationError.empty;
    } else if (!EmailValidator.validate(value)) {
      return SignUpEmailValidationError.invalid;
    }
    return externalError;
  }
}
