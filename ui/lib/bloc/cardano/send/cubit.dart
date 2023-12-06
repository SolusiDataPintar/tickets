import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tickets/bloc/cardano/cubit.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/model/httperror.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/provider/logger.dart';
import 'package:tickets/service/wallet.dart';

part 'model.dart';
part 'state.dart';

class CardanoSendCubit extends Cubit<CardanoSendState> {
  CardanoSendCubit() : super(const CardanoSendState());

  set receiver(final String value) {
    final receiver = CardanoSendReceiver.dirty(value: value);
    emit(
      state.copyWith(
        receiver: receiver,
        isValid: Formz.validate([receiver, state.lovelace, state.password]),
      ),
    );
  }

  set lovelace(final int value) {
    final lovelace = CardanoSendLovelace.dirty(value: value);
    emit(
      state.copyWith(
        lovelace: lovelace,
        isValid: Formz.validate([state.receiver, lovelace, state.password]),
      ),
    );
  }

  set password(final String value) {
    final password =
        CardanoSendPassword.dirty(externalError: null, value: value);
    emit(
      state.copyWith(
        password: password,
        isValid: Formz.validate([state.receiver, state.lovelace, password]),
      ),
    );
  }

  void changeAsset(final CardanoAssetDetail asset) {
    final foundAsset = state.selectedAssets
        .where(
          (final e) =>
              e.policyId == asset.policyId && e.assetId == asset.assetId,
        )
        .firstOrNull;
    if (foundAsset == null) {
      emit(
        state.copyWith(
          selectedAssets: [
            ...state.selectedAssets,
            asset,
          ],
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedAssets: [
            ...state.selectedAssets.where((final e) => e != foundAsset),
          ],
        ),
      );
    }
  }

  Future<void> submit() async {
    final receiver = CardanoSendReceiver.dirty(value: state.receiver.value);
    final lovelace = CardanoSendLovelace.dirty(value: state.lovelace.value);
    final password = CardanoSendPassword.dirty(
      externalError: null,
      value: state.password.value,
    );
    emit(
      state.copyWith(
        receiver: receiver,
        lovelace: lovelace,
        password: password,
        isValid: Formz.validate([receiver, lovelace, password]),
      ),
    );
    if (!state.isValid) {
      return;
    }
    try {
      emit(state.copyWith(status: FormzSubmissionStatus.inProgress));
      final sendAssets = <CardanoAsset>[];
      final assets =
          getIt<CardanoCubit>().state.balance as CardanoBalanceStatusSuccess;
      for (final selectedAsset in state.selectedAssets) {
        final item = assets.balance.cardano.assets
            .where(
              (final e) =>
                  e.policyId == selectedAsset.policyId &&
                  e.assetName == selectedAsset.assetName,
            )
            .firstOrNull;
        if (item != null) {
          sendAssets.add(item);
        }
      }
      final res = await getIt<WalletService>().send(
        SendCardano(
          receiver: state.receiver.value,
          coin: state.lovelace.value,
          assets: sendAssets,
          password: state.password.value,
        ),
      );
      if (res.isSuccessful) {
        emit(
          state.copyWith(
            status: FormzSubmissionStatus.success,
            transactionHash: res.bodyString,
            lovelace: const CardanoSendLovelace.dirty(value: 0),
            selectedAssets: const [],
          ),
        );
      } else {
        throw res.error as HttpError;
      }
    } on HttpError catch (err, st) {
      if (err.code == 403) {
        final password = CardanoSendPassword.dirty(
          externalError: CardanoSendPasswordValidationError.invalid,
          value: state.password.value,
        );
        emit(
          state.copyWith(
            status: FormzSubmissionStatus.failure,
            password: password,
            isValid: Formz.validate([state.receiver, state.lovelace, password]),
          ),
        );
      } else {
        logger.e(err.toString(), error: err, stackTrace: st);
        Sentry.captureException(err, stackTrace: st);
        final password = CardanoSendPassword.dirty(
          externalError: CardanoSendPasswordValidationError.unknown,
          value: state.password.value,
        );
        emit(
          state.copyWith(
            status: FormzSubmissionStatus.failure,
            password: password,
            isValid: Formz.validate([state.receiver, state.lovelace, password]),
          ),
        );
      }
    } catch (err, st) {
      logger.e(err.toString(), error: err, stackTrace: st);
      Sentry.captureException(err, stackTrace: st);
      final password = CardanoSendPassword.dirty(
        externalError: CardanoSendPasswordValidationError.unknown,
        value: state.password.value,
      );
      emit(
        state.copyWith(
          status: FormzSubmissionStatus.failure,
          password: password,
          isValid: Formz.validate([state.receiver, state.lovelace, password]),
        ),
      );
    }
  }
}
