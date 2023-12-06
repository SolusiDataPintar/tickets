import 'package:auto_route/auto_route.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tickets/bloc/cardano/collectible/cubit.dart';
import 'package:tickets/generated/l10n.dart';
import 'package:tickets/ipfs/ipfs.dart';
import 'package:tickets/model/nft.dart';
import 'package:tickets/routes.gr.dart';
import 'package:tickets/widget/appbarthemed.dart';
import 'package:tickets/widget/error.dart';
import 'package:tickets/widget/labeled_text.dart';
import 'package:tickets/widget/labeled_widget.dart';

enum _EnumImageQrCodeFlip {
  image,
  qrCode,
}

@RoutePage()
class CardanoCollectiblePage extends StatelessWidget
    implements AutoRouteWrapper {
  final String policyId, assetId, address;
  const CardanoCollectiblePage({
    super.key,
    required this.policyId,
    required this.assetId,
    required this.address,
  });
  @override
  Widget build(final BuildContext context) => Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (final _, final __) => <Widget>[
            const SliverAppBar(
              title: _Name(),
              elevation: 0,
              flexibleSpace: AppBarThemed(),
            ),
          ],
          body: BlocConsumer<CardanoCollectibleCubit, CardanoCollectibleState>(
            listener: _listener,
            builder: _builder,
          ),
        ),
      );

  void _listener(
    final BuildContext context,
    final CardanoCollectibleState state,
  ) {
    final item = state.itemDialog;
    if (item != null) {
      showDialog(
        context: context,
        builder: (final BuildContext context) => _TicketIsValidDialog(item),
      );
    }
  }

  Widget _builder(
    final BuildContext context,
    final CardanoCollectibleState state,
  ) {
    final metaData = state.assetMetaData;
    switch (metaData) {
      case CardanoCollectibleAssetMetaDataStatusLoading():
        return const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(95, 5, 235, 243),
          ),
        );
      case CardanoCollectibleAssetMetaDataStatusFailure():
        return ErrorStatus(
          err: metaData.err.toString(),
          onTry: context.read<CardanoCollectibleCubit>().refresh,
        );
      case CardanoCollectibleAssetMetaDataStatusSuccess():
        return ListView(
          padding: const EdgeInsets.all(10),
          children: const <Widget>[
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              runAlignment: WrapAlignment.center,
              alignment: WrapAlignment.center,
              runSpacing: 20,
              spacing: 20,
              children: [
                _PolicyId(),
                _AssetId(),
              ],
            ),
            SizedBox(height: 20),
            _ImageQrCodeFlip(),
            SizedBox(height: 20),
            _Description(),
            SizedBox(height: 20),
            _RedeemableList(),
            SizedBox(height: 20),
          ],
        );
    }
  }

  @override
  Widget wrappedRoute(final BuildContext context) => BlocProvider(
        create: (final _) => CardanoCollectibleCubit(
          policyId: policyId,
          assetId: assetId,
          address: address,
        )..refresh(),
        child: this,
      );
}

class _ImageQrCodeFlip extends StatefulWidget {
  const _ImageQrCodeFlip();
  @override
  State<StatefulWidget> createState() => _ImageQrCodeFlipState();
}

class _ImageQrCodeFlipState extends State<_ImageQrCodeFlip> {
  _EnumImageQrCodeFlip imageQrCodeFlip = _EnumImageQrCodeFlip.image;
  @override
  Widget build(final BuildContext context) => Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            InkWell(
              onDoubleTap: () => onViewImage(context),
              onLongPress: () => onViewImage(context),
              child: FlipCard(
                direction: FlipDirection.HORIZONTAL,
                front: const _Image(),
                back: const _QrCode(),
                onFlipDone: onImageQrCodeFlip,
              ),
            ),
            Text(
              S.of(context).tapToView(
                    imageQrCodeFlip == _EnumImageQrCodeFlip.image
                        ? 'Qr Code'
                        : S.of(context).image,
                  ),
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
            Text(
              S.of(context).doubleTapToViewFullImage,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );

  void onViewImage(final BuildContext context) {
    final metaData =
        context.read<CardanoCollectibleCubit>().state.assetMetaData;
    switch (metaData) {
      case CardanoCollectibleAssetMetaDataStatusLoading():
        return;
      case CardanoCollectibleAssetMetaDataStatusFailure():
        return;
      case CardanoCollectibleAssetMetaDataStatusSuccess():
        context.router.push(
          ImageViewerRoute(
            name: metaData.detail.image,
            url: convertIpfsToHttp(metaData.detail.image),
          ),
        );
    }
  }

  void onImageQrCodeFlip(final bool flipped) {
    if (flipped) {
      imageQrCodeFlip = _EnumImageQrCodeFlip.qrCode;
      context.read<CardanoCollectibleCubit>().refreshCode();
    } else {
      imageQrCodeFlip = _EnumImageQrCodeFlip.image;
    }
  }
}

class _Image extends StatelessWidget {
  const _Image();
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<CardanoCollectibleCubit, CardanoCollectibleState>(
        builder: _builder,
      );
  Widget _builder(
    final BuildContext context,
    final CardanoCollectibleState state,
  ) {
    final metaData = state.assetMetaData;
    switch (metaData) {
      case CardanoCollectibleAssetMetaDataStatusLoading():
        return const SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(95, 5, 235, 243),
            ),
          ),
        );
      case CardanoCollectibleAssetMetaDataStatusFailure():
        return SizedBox(
          width: 200,
          height: 200,
          child: ErrorStatus(err: metaData.err.toString()),
        );
      case CardanoCollectibleAssetMetaDataStatusSuccess():
        return Image.network(
          convertIpfsToHttp(metaData.detail.image),
          width: 200,
          height: 200,
          fit: BoxFit.fill,
        );
    }
  }
}

class _QrCode extends StatelessWidget {
  const _QrCode();
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<CardanoCollectibleCubit, CardanoCollectibleState>(
        builder: _builder,
      );
  Widget _builder(
    final BuildContext context,
    final CardanoCollectibleState state,
  ) {
    final code = state.code;
    switch (code) {
      case CardanoCollectibleCodeStatusLoading():
        return const SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(95, 5, 235, 243),
            ),
          ),
        );
      case CardanoCollectibleCodeStatusFailure():
        return SizedBox(
          width: 200,
          height: 200,
          child: ErrorStatus(err: code.err.toString()),
        );
      case CardanoCollectibleCodeStatusSuccess():
        return QrImageView(
          data: code.code.code,
          size: 200,
        );
    }
  }
}

class _Description extends StatelessWidget {
  const _Description();
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<CardanoCollectibleCubit, CardanoCollectibleState>(
        builder: _builder,
      );

  String parseDescription(final dynamic description) {
    if (description is String) {
      return description;
    } else if (description is List) {
      return description.join("\n");
    }
    return "-";
  }

  Widget _builder(
    final BuildContext context,
    final CardanoCollectibleState state,
  ) {
    String text = ". . .";
    final metaData = state.assetMetaData;
    switch (metaData) {
      case CardanoCollectibleAssetMetaDataStatusLoading():
        break;
      case CardanoCollectibleAssetMetaDataStatusFailure():
        text = S.of(context).errorOccurred;
        break;
      case CardanoCollectibleAssetMetaDataStatusSuccess():
        text = parseDescription(metaData.detail.description);
        break;
    }
    return LabeledText(label: "Description", text: text);
  }
}

class _AssetId extends StatelessWidget {
  const _AssetId();
  @override
  Widget build(final BuildContext context) => LabeledText(
        label: "Asset ID",
        text: context.read<CardanoCollectibleCubit>().assetId,
      );
}

class _PolicyId extends StatelessWidget {
  const _PolicyId();
  @override
  Widget build(final BuildContext context) => LabeledText(
        label: "Policy ID",
        text: context.read<CardanoCollectibleCubit>().policyId,
      );
}

class _Name extends StatelessWidget {
  const _Name();
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<CardanoCollectibleCubit, CardanoCollectibleState>(
        builder: _builder,
      );

  Widget _builder(
    final BuildContext context,
    final CardanoCollectibleState state,
  ) {
    final metaData = state.assetMetaData;
    switch (metaData) {
      case CardanoCollectibleAssetMetaDataStatusLoading():
        return const Text(". . .");
      case CardanoCollectibleAssetMetaDataStatusFailure():
        return Text(S.of(context).errorOccurred);
      case CardanoCollectibleAssetMetaDataStatusSuccess():
        return Text(metaData.detail.name);
    }
  }
}

class _RedeemableList extends StatelessWidget {
  const _RedeemableList();
  @override
  Widget build(final BuildContext context) => LabeledWidget(
        label: 'Redeemable Item',
        content: BlocBuilder<CardanoCollectibleCubit, CardanoCollectibleState>(
          builder: _builder,
        ),
      );

  Widget _builder(
    final BuildContext context,
    final CardanoCollectibleState state,
  ) =>
      ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: state.redeemableList.length,
        separatorBuilder: (final _, final __) => const SizedBox(height: 10),
        itemBuilder: (final _, final int idx) =>
            _RedeemableCard(state.redeemableList[idx]),
      );
}

class _RedeemableCard extends StatelessWidget {
  final Redeemable item;
  const _RedeemableCard(this.item);
  @override
  Widget build(final BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.redeemedAt == null ? Colors.white : Colors.green,
              border: Border.all(
                color: const Color.fromARGB(255, 94, 101, 175),
              ),
            ),
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 10),
          Text(
            item.edges.item.name,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.start,
          ),
        ],
      );
}

class _TicketIsValidDialog extends StatelessWidget {
  final Item item;
  const _TicketIsValidDialog(this.item);

  @override
  Widget build(final BuildContext context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_sharp,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 10),
              Text(
                "Ticket is Valid for ${item.name}",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: Navigator.of(context).pop,
                child: Text(S.of(context).close),
              ),
            ],
          ),
        ),
      );
}
