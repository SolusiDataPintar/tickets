import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:tickets/provider/logger.dart';
import 'package:tickets/provider/session.dart';

part 'event.dart';
part 'model.dart';
part 'state.dart';

class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc() : super(const SignInState()) {
    on<SignInEmailChanged>(_onEmailChanged);
    on<SignInPasswordChanged>(_onPasswordChanged);
    on<SignInFormSubmitted>(_onFormSubmitted);
  }

  void _onEmailChanged(
    final SignInEmailChanged event,
    final Emitter<SignInState> emit,
  ) {
    final email = SignInEmail.dirty(
      externalError: null,
      value: event.email,
    );
    emit(
      state.copyWith(
        email: email,
        isValid: Formz.validate([email, state.password]),
      ),
    );
  }

  void _onPasswordChanged(
    final SignInPasswordChanged event,
    final Emitter<SignInState> emit,
  ) {
    final password = SignInPassword.dirty(
      externalError: null,
      value: event.password,
    );
    emit(
      state.copyWith(
        password: password,
        isValid: Formz.validate([state.email, password]),
      ),
    );
  }

  Future<void> _onFormSubmitted(
    final SignInFormSubmitted event,
    final Emitter<SignInState> emit,
  ) async {
    final email = SignInEmail.dirty(
      externalError: null,
      value: state.email.value,
    );
    final password = SignInPassword.dirty(
      externalError: null,
      value: state.password.value,
    );
    emit(
      state.copyWith(
        email: email,
        password: password,
        isValid: Formz.validate([email, password]),
      ),
    );
    if (!state.isValid) {
      return;
    }
    try {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
      await SessionProvider.signIn(email.value, password.value);
      emit(state.copyWith(status: FormzSubmissionStatus.success));
    } on ExceptionInvalidCredential {
      final password = SignInPassword.dirty(
        externalError: SignInPasswordValidationError.invalid,
        value: state.password.value,
      );
      emit(
        state.copyWith(
          status: FormzSubmissionStatus.failure,
          password: password,
          isValid: Formz.validate([email, password]),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: FormzSubmissionStatus.initial));
    } catch (err, st) {
      logger.e(err.toString(), error: err, stackTrace: st);
      final password = SignInPassword.dirty(
        externalError: SignInPasswordValidationError.unknown,
        value: state.password.value,
      );
      emit(
        state.copyWith(
          status: FormzSubmissionStatus.failure,
          password: password,
          isValid: Formz.validate([email, password]),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: FormzSubmissionStatus.initial));
    }
  }
}
