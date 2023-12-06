import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:tickets/bloc/cardano/cubit.dart';
import 'package:tickets/config/config.dart';
import 'package:tickets/generated/l10n.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/widget/cardano/nft.dart';
import 'package:tickets/widget/empty.dart';
import 'package:tickets/widget/glass.dart';
import 'package:tickets/widget/labeled_widget.dart';

class CardanoNftCardStatusList extends StatelessWidget {
  final ValueChanged<CardanoAssetDetail>? onSelected;
  const CardanoNftCardStatusList({super.key, this.onSelected});
  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: LabeledWidget(
          label: "NFT",
          labelStyle: Theme.of(context).textTheme.titleMedium,
          content: BlocBuilder<CardanoCubit, CardanoState>(builder: _builder),
        ),
      );

  Widget _builder(final BuildContext context, final CardanoState state) {
    if (state.nftList.isEmpty) {
      return const Empty();
    } else {
      final list = state.nftList.toList(growable: false);
      return MasonryGridView.count(
        crossAxisCount: MediaQuery.of(context).size.width ~/ kGridSize,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: list.length,
        itemBuilder: (final _, final index) => CardanoNftCardStatus(
          status: list[index],
          onSelected: onSelected,
        ),
      );
    }
  }
}

class CardanoNftCardStatus extends StatelessWidget {
  final CardanoAssetStatus status;
  final ValueChanged<CardanoAssetDetail>? onSelected;
  const CardanoNftCardStatus({
    super.key,
    required this.status,
    this.onSelected,
  });
  @override
  Widget build(final BuildContext context) {
    final state = status;
    switch (state) {
      case CardanoAssetStatusLoading():
        return _loading(context, state.asset);
      case CardanoAssetStatusFailure():
        return _failure(
          context,
          state.error,
          state.st,
        );
      case CardanoAssetStatusSuccess():
        return _success(context, state.detail);
    }
  }

  Widget _loading(final BuildContext context, final CardanoAsset asset) => Card(
        elevation: 0,
        child: GlassContainer(
          tintColor: Theme.of(context).colorScheme.primary,
          child: Column(
            children: [
              const Center(child: CircularProgressIndicator()),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Center(
                  child: Text(
                    asset.assetName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _failure(
    final BuildContext context,
    final dynamic err,
    final StackTrace st,
  ) =>
      Card(
        elevation: 0,
        child: GlassContainer(
          tintColor: Theme.of(context).colorScheme.primary,
          child: Column(
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: Center(
                  child: Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5),
                child: Center(
                  child: Text(
                    S.of(context).errorOccurred,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _success(
    final BuildContext context,
    final CardanoAssetDetail detail,
  ) {
    final card = CardanoNftCard(detail: detail);
    if (onSelected == null) {
      return card;
    } else {
      return InkWell(
        onTap: () => onSelected!(detail),
        child: card,
      );
    }
  }
}
