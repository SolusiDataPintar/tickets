part of 'bloc.dart';

final class SignUpState extends Equatable {
  const SignUpState({
    this.email = const SignUpEmail.pure(),
    this.isValid = false,
    this.status = FormzSubmissionStatus.initial,
  });

  final SignUpEmail email;
  final bool isValid;
  final FormzSubmissionStatus status;

  SignUpState copyWith({
    final SignUpEmail? email,
    final bool? isValid,
    final FormzSubmissionStatus? status,
  }) =>
      SignUpState(
        email: email ?? this.email,
        isValid: isValid ?? this.isValid,
        status: status ?? this.status,
      );

  @override
  List<Object> get props => [email, status];
}
