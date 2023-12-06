import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tickets/bloc/cardano/cubit.dart';
import 'package:tickets/config/config.dart';
import 'package:tickets/generated/l10n.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/widget/appbarthemed.dart';
import 'package:tickets/widget/error.dart';

@RoutePage()
class CardanoReceivePage extends StatefulWidget implements AutoRouteWrapper {
  const CardanoReceivePage({super.key});
  @override
  State<StatefulWidget> createState() => _CardanoReceivePageState();

  @override
  Widget wrappedRoute(final BuildContext context) => BlocProvider(
        create: (final _) {
          if (getIt.isRegistered<CardanoCubit>()) {
            return getIt<CardanoCubit>();
          } else {
            return getIt.registerSingleton(CardanoCubit());
          }
        },
        child: this,
      );
}

class _CardanoReceivePageState extends State<CardanoReceivePage> {
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).receive),
          elevation: 0,
          flexibleSpace: const AppBarThemed(),
        ),
        body: RefreshIndicator(
          key: refreshKey,
          onRefresh: context.read<CardanoCubit>().refreshAddressList,
          child: BlocBuilder<CardanoCubit, CardanoState>(builder: _builder),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.read<CardanoCubit>().refreshAddressList(),
          child: const Icon(Icons.add),
        ),
      );

  Widget _builder(final BuildContext context, final CardanoState state) {
    final status = state.addressList;
    switch (status) {
      case CardanoAddressListStatusLoading():
        return const Center(child: CircularProgressIndicator());
      case CardanoAddressListStatusFailure():
        return ErrorStatus(
          err: status.error.toString(),
          onTry: context.read<CardanoCubit>().refreshAddressList,
        );
      case CardanoAddressListStatusSuccess():
        return MasonryGridView.count(
          crossAxisCount: MediaQuery.of(context).size.width ~/ kGridSize,
          mainAxisSpacing: 5,
          crossAxisSpacing: 5,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: status.addressList.length,
          itemBuilder: (final _, final index) => _Addr(
            status.addressList[index],
          ),
        );
    }
  }

  Future<void> _onFirstRefresh() async {
    while (refreshKey.currentState == null) {
      final state = refreshKey.currentState;
      if (state == null) {
        await Future.delayed(const Duration(milliseconds: 250));
        continue;
      }
      if (!state.mounted) {
        await Future.delayed(const Duration(milliseconds: 250));
        continue;
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    refreshKey.currentState!.show();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(microseconds: 500), _onFirstRefresh);
  }
}

class _Addr extends StatelessWidget {
  final String addr;
  const _Addr(this.addr);
  @override
  Widget build(final BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _QrAddr(addr),
          const SizedBox(height: 10),
          _TextAddr(addr),
        ],
      );
}

class _QrAddr extends StatelessWidget {
  final String addr;
  const _QrAddr(this.addr);
  @override
  Widget build(final BuildContext context) => QrImageView(
        data: addr,
        size: kGridSize - 10,
      );
}

class _TextAddr extends StatelessWidget {
  final String addr;
  const _TextAddr(this.addr);
  @override
  Widget build(final BuildContext context) =>
      SelectableText(addr, textAlign: TextAlign.center);
}
