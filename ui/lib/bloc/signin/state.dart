part of 'bloc.dart';

final class SignInState extends Equatable {
  const SignInState({
    this.email = const SignInEmail.pure(),
    this.password = const SignInPassword.pure(),
    this.isValid = false,
    this.status = FormzSubmissionStatus.initial,
  });

  final SignInEmail email;
  final SignInPassword password;
  final bool isValid;
  final FormzSubmissionStatus status;

  SignInState copyWith({
    final SignInEmail? email,
    final SignInPassword? password,
    final bool? obscurePassword,
    final bool? isValid,
    final FormzSubmissionStatus? status,
  }) =>
      SignInState(
        email: email ?? this.email,
        password: password ?? this.password,
        isValid: isValid ?? this.isValid,
        status: status ?? this.status,
      );

  @override
  List<Object> get props => [email, password, status];
}
