part of 'bloc.dart';

enum SignInEmailValidationError { empty, notFound }

final class SignInEmail extends FormzInput<String, SignInEmailValidationError> {
  final SignInEmailValidationError? externalError;

  const SignInEmail.pure()
      : externalError = null,
        super.pure('');
  const SignInEmail.dirty({this.externalError, required final String value})
      : super.dirty(value);

  @override
  SignInEmailValidationError? validator(final String value) {
    if (value.isEmpty) {
      return SignInEmailValidationError.empty;
    }
    return externalError;
  }
}

enum SignInPasswordValidationError {
  empty,
  invalid,
  unknown,
}

final class SignInPassword
    extends FormzInput<String, SignInPasswordValidationError> {
  final SignInPasswordValidationError? externalError;

  const SignInPassword.pure()
      : externalError = null,
        super.pure('');
  const SignInPassword.dirty({this.externalError, final String value = ''})
      : super.dirty(value);

  @override
  SignInPasswordValidationError? validator(final String value) {
    if (externalError != null) {
      return externalError;
    } else if (value.isEmpty) {
      return SignInPasswordValidationError.empty;
    } else {
      return null;
    }
  }
}
