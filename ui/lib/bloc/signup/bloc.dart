import 'package:bloc/bloc.dart';
import 'package:email_validator/email_validator.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:tickets/model/httperror.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/provider/logger.dart';
import 'package:tickets/service/account.dart';

part 'model.dart';
part 'state.dart';

class SignUpBloc extends Cubit<SignUpState> {
  SignUpBloc() : super(const SignUpState());

  set email(final String value) {
    final email = SignUpEmail.dirty(value: value, externalError: null);
    emit(
      state.copyWith(
        email: email,
        isValid: Formz.validate([email]),
      ),
    );
  }

  Future<void> submit() async {
    final email = SignUpEmail.dirty(
      value: state.email.value,
      externalError: null,
    );
    emit(
      state.copyWith(
        email: email,
        isValid: Formz.validate([email]),
      ),
    );
    if (!state.isValid) {
      return;
    }
    try {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
      final res = await getIt<AccountService>().signUp(state.email.value);
      if (res.isSuccessful) {
        getIt<AccountService>().activation(state.email.value);
        emit(state.copyWith(status: FormzSubmissionStatus.success));
      } else {
        throw res.error as HttpError;
      }
    } catch (err, st) {
      logger.e(err.toString(), error: err, stackTrace: st);
      final email = SignUpEmail.dirty(
        externalError: SignUpEmailValidationError.unknown,
        value: state.email.value,
      );
      emit(
        state.copyWith(
          status: FormzSubmissionStatus.failure,
          email: email,
          isValid: Formz.validate([email]),
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      emit(state.copyWith(status: FormzSubmissionStatus.initial));
    }
  }
}
