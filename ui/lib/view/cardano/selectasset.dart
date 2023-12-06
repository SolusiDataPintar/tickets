import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/widget/appbarthemed.dart';
import 'package:tickets/widget/cardano/nft.dart';

@RoutePage<CardanoAssetDetail>()
class CardanoSelectAssetPage extends StatelessWidget {
  final List<CardanoAssetDetail> list;
  const CardanoSelectAssetPage({super.key, required this.list});
  @override
  Widget build(final BuildContext context) => Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (final _, final __) => [
            const SliverAppBar(
              centerTitle: true,
              title: Text("Select Asset"),
              elevation: 0,
              flexibleSpace: AppBarThemed(),
            ),
          ],
          body: CardanoNftList(
            list: list,
            onSelected: (final detail) => onAssetSelected(context, detail),
          ),
        ),
      );

  void onAssetSelected(
    final BuildContext context,
    final CardanoAssetDetail detail,
  ) =>
      context.router.pop<CardanoAssetDetail>(detail);
}
