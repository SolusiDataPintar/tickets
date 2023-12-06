import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:convert/convert.dart';
import 'package:equatable/equatable.dart';
import 'package:tickets/cardano/cardano.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/model/httperror.dart';
import 'package:tickets/model/token.dart';
import 'package:tickets/model/wallet.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/provider/logger.dart';
import 'package:tickets/provider/session.dart';
import 'package:tickets/service/wallet.dart';

part 'model.dart';
part 'state.dart';

class CardanoCubit extends Cubit<CardanoState> {
  CardanoCubit() : super(const CardanoState());

  Future<void> refresh() async {
    try {
      final balance = await _onRefreshBalance();
      await _onRefreshAsset(balance);
    } catch (err, st) {
      emit(
        state.copyWith(
          balance: CardanoBalanceStatusFailure(err, st),
        ),
      );
      logger.e(err.toString(), error: err, stackTrace: st);
    }
  }

  Future<void> refreshAddressList() async {
    try {
      emit(
        state.copyWith(addressList: const CardanoAddressListStatusLoading()),
      );
      final res = await getIt<WalletService>().cardanoAddresses();
      if (res.isSuccessful) {
        emit(
          state.copyWith(
            addressList: CardanoAddressListStatusSuccess(res.body ?? const []),
          ),
        );
      } else {
        throw res.error as HttpError;
      }
    } catch (err, st) {
      emit(
        state.copyWith(
          addressList: CardanoAddressListStatusFailure(
            error: err,
            st: st,
          ),
        ),
      );
      logger.e(err.toString(), error: err, stackTrace: st);
    }
  }

  Future<void> addAddress() async {
    try {
      emit(
        state.copyWith(addressList: const CardanoAddressListStatusLoading()),
      );
      final res = await getIt<WalletService>().addCardanoAddress();
      if (res.isSuccessful) {
        final res = await getIt<WalletService>().cardanoAddresses();
        if (res.isSuccessful) {
          emit(
            state.copyWith(
              addressList:
                  CardanoAddressListStatusSuccess(res.body ?? const []),
            ),
          );
        } else {
          throw res.error as HttpError;
        }
      } else {
        throw res.error as HttpError;
      }
    } catch (err, st) {
      emit(
        state.copyWith(
          addressList: CardanoAddressListStatusFailure(
            error: err,
            st: st,
          ),
        ),
      );
      logger.e(err.toString(), error: err, stackTrace: st);
    }
  }

  Future<Balance> _onRefreshBalance() async {
    final res = await getIt<WalletService>().balance();
    if (!res.isSuccessful) {
      throw res.error as HttpError;
    }
    final balance = res.body ?? Balance.empty();
    final price = getIt<SessionProvider>().price.cardano.idr;
    final lovelace = balance.cardano.coin.toDouble();

    //for (final asset in balance.cardano.assets) {
    //  lovelace -= asset.amount;
    //}
    emit(
      state.copyWith(
        balance: CardanoBalanceStatusSuccess(
          balance: balance,
          totalBalance: lovelaceToAda(lovelace) * price,
        ),
        tokenList: [AdaToken(balance.cardano)],
      ),
    );
    return balance;
  }

  Future<void> _onRefreshAsset(final Balance balance) async {
    final futures = <Future<void>>[];
    for (final e in balance.cardano.assets.asMap().entries) {
      emit(
        state.copyWith(
          nftList: [
            ...state.nftList,
            CardanoAssetStatusLoading(asset: e.value),
          ],
        ),
      );
      futures.add(_loadAsset(e.key, e.value));
    }
    await Future.wait(futures);
  }

  Future<void> _loadAsset(
    final int index,
    final CardanoAsset asset,
  ) async {
    final policyId = asset.policyId;
    final assetId = hex.encode(utf8.encode(asset.assetName));

    try {
      final res = await getIt<WalletService>().cardanoAssetDetail(
        policyId,
        assetId,
      );
      if (!res.isSuccessful) {
        throw res.error as HttpError;
      }
      emit(
        state.copyWith(
          nftList: [
            ...(index == 0 ? const [] : state.nftList.take(index - 1)),
            CardanoAssetStatusSuccess(
              asset: asset,
              detail: res.body!,
            ),
            ...state.nftList.skip(index + 1),
          ],
        ),
      );
    } catch (err, st) {
      emit(
        state.copyWith(
          nftList: [
            ...(index == 0 ? const [] : state.nftList.take(index - 1)),
            CardanoAssetStatusFailure(
              asset: asset,
              error: err,
              st: st,
            ),
            ...state.nftList.skip(index + 1),
          ],
        ),
      );
      logger.e(err.toString(), error: err, stackTrace: st);
    }
  }
}
