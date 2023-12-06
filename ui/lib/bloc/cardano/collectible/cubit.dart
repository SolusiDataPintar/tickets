import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/model/httperror.dart';
import 'package:tickets/model/nft.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/provider/logger.dart';
import 'package:tickets/service/redeemable.dart';
import 'package:tickets/service/wallet.dart';

part 'model.dart';
part 'state.dart';

class CardanoCollectibleCubit extends Cubit<CardanoCollectibleState> {
  final String policyId, assetId, address;
  final Client _httpClient;
  Timer? codeRefreshTimer;
  CardanoCollectibleCubit({
    required this.policyId,
    required this.assetId,
    required this.address,
  })  : _httpClient = Client(),
        super(const CardanoCollectibleState());
  StreamSubscription<CardanoRedeemEvent>? _redeemEventSubscription;
  Future<void> refresh() async {
    try {
      emit(
        state.copyWith(
          assetMetaData: const CardanoCollectibleAssetMetaDataStatusLoading(),
        ),
      );
      final res = await getIt<WalletService>().cardanoAssetDetail(
        policyId,
        assetId,
      );
      if (res.isSuccessful) {
        emit(
          state.copyWith(
            assetMetaData: CardanoCollectibleAssetMetaDataStatusSuccess(
              CardanoAssetMetaData.fromAssetDetailForNft(res.body!),
            ),
          ),
        );
        refreshCode();
        refreshRedeemableList();
        _redeemEventSubscription?.cancel();
        _redeemEventSubscription = getIt<RedeemableService>()
            .streamRedeemEvent(
              httpClient: _httpClient,
              policyId: policyId,
              assetId: assetId,
            )
            .listen(
              _onRedeemEvent,
              onError: (final err) => logger.e(err.toString(), error: err),
            );
      } else {
        throw res.error as HttpError;
      }
    } catch (err, st) {
      emit(
        state.copyWith(
          assetMetaData: CardanoCollectibleAssetMetaDataStatusFailure(err, st),
        ),
      );
      logger.e(err.toString(), error: err, stackTrace: st);
    }
  }

  Future<void> refreshCode() async {
    try {
      final res = await getIt<RedeemableService>().qr(
        address,
        policyId,
        assetId,
      );
      if (res.isSuccessful) {
        emit(
          state.copyWith(code: CardanoCollectibleCodeStatusSuccess(res.body!)),
        );
        codeRefreshTimer?.cancel();
        codeRefreshTimer = Timer.periodic(
          const Duration(seconds: 1),
          onCodeRefreshTimerTimeout,
        );
      } else {
        throw res.error as HttpError;
      }
    } catch (err, st) {
      codeRefreshTimer?.cancel();
      refreshCode();
      logger.e(err.toString(), error: err, stackTrace: st);
    }
  }

  Future<void> refreshRedeemableList() async {
    try {
      final res = await getIt<RedeemableService>().find(policyId, assetId);
      if (res.isSuccessful) {
        for (final i in state.redeemableList) {
          if (i.redeemedAt != null) {
            continue;
          }
          final c = res.body?.where((final e) => e.id == i.id).firstOrNull;
          if (c == null) {
            continue;
          }
          if (c.redeemedAt != null) {
            emit(state.copyWith(itemDialog: c.edges.item));
            await refreshCode();
            break;
          }
        }
        final items = res.body ?? const [];
        items.sort(
          (final left, final right) =>
              left.createdAt.millisecondsSinceEpoch -
              right.createdAt.millisecondsSinceEpoch,
        );
        emit(state.copyWith(redeemableList: items));
      } else {
        throw res.error as HttpError;
      }
    } catch (err, st) {
      logger.e(err.toString(), error: err, stackTrace: st);
    }
  }

  void onCodeRefreshTimerTimeout(final Timer timer) {
    final code = state.code;
    switch (code) {
      case CardanoCollectibleCodeStatusSuccess():
        if (code.code.asset.expiredAt.difference(DateTime.now()).inSeconds <
            5) {
          timer.cancel();
          refreshCode();
        }
        break;
      case CardanoCollectibleCodeStatusLoading():
      case CardanoCollectibleCodeStatusFailure():
        timer.cancel();
        refreshCode();
        break;
    }
  }

  void _onRedeemEvent(final CardanoRedeemEvent event) {
    refreshRedeemableList();
  }

  @override
  Future<void> close() {
    _redeemEventSubscription?.cancel();
    codeRefreshTimer?.cancel();
    _httpClient.close();
    return super.close();
  }
}
