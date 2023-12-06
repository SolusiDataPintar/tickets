import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:tickets/config/config.dart';
import 'package:tickets/ipfs/ipfs.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/widget/empty.dart';
import 'package:tickets/widget/glass.dart';

class CardanoNftList extends StatelessWidget {
  final List<CardanoAssetDetail> list;
  final ValueChanged<CardanoAssetDetail>? onSelected;
  const CardanoNftList({
    super.key,
    required this.list,
    this.onSelected,
  });
  @override
  Widget build(final BuildContext context) {
    if (list.isEmpty) {
      return const Empty();
    } else {
      return MasonryGridView.count(
        crossAxisCount: MediaQuery.of(context).size.width ~/ kGridSize,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: list.length,
        itemBuilder: _itemBuilder,
      );
    }
  }

  Widget _itemBuilder(final BuildContext context, final int index) {
    final card = CardanoNftCard(
      detail: list[index],
    );
    if (onSelected == null) {
      return card;
    } else {
      return InkWell(
        onTap: () => onSelected!(list[index]),
        child: card,
      );
    }
  }
}

class CardanoNftCard extends StatelessWidget {
  final CardanoAssetDetail detail;
  const CardanoNftCard({super.key, required this.detail});
  @override
  Widget build(final BuildContext context) => Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.primary,
        child: Column(
          children: [
            Image.network(
              convertIpfsToHttp(
                CardanoAssetMetaData.fromAssetDetailForNft(detail).image,
              ),
            ),
            GlassContainer(
              tintColor: Theme.of(context).colorScheme.primary,
              sigmaX: 30,
              sigmaY: 40,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Center(
                  child: Text(
                    CardanoAssetMetaData.fromAssetDetailForNft(detail).name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
