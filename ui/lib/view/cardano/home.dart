import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:intl/intl.dart';
import 'package:tickets/bloc/cardano/cubit.dart';
import 'package:tickets/config/config.dart';
import 'package:tickets/generated/assets.gen.dart';
import 'package:tickets/generated/l10n.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/model/token.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/provider/session.dart';
import 'package:tickets/routes.gr.dart';
import 'package:tickets/service/wallet.dart';
import 'package:tickets/widget/appbarthemed.dart';
import 'package:tickets/widget/cardano/nftstatus.dart';
import 'package:tickets/widget/empty.dart';
import 'package:tickets/widget/glass.dart';
import 'package:tickets/widget/labeled_text.dart';
import 'package:tickets/widget/labeled_widget.dart';

@RoutePage()
class CardanoHomePage extends StatefulWidget implements AutoRouteWrapper {
  const CardanoHomePage({super.key});
  @override
  State<StatefulWidget> createState() => _CardanoHomePageState();

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

class _CardanoHomePageState extends State<CardanoHomePage> {
  final drawerController = ZoomDrawerController();
  final refreshKey = GlobalKey<RefreshIndicatorState>();
  @override
  Widget build(final BuildContext context) => ZoomDrawer(
        controller: drawerController,
        borderRadius: 24.0,
        showShadow: true,
        angle: -12.0,
        drawerShadowsBackgroundColor: Colors.grey,
        slideWidth: MediaQuery.of(context).size.width < 750
            ? (MediaQuery.of(context).size.width * 0.75)
            : (MediaQuery.of(context).size.width * 0.25),
        menuScreen: _HomeDrawer(_onFirstRefresh),
        androidCloseOnBackTap: true,
        menuBackgroundColor: Colors.white30,
        mainScreen: Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (final _, final __) => <Widget>[
              SliverAppBar(
                centerTitle: true,
                title: Assets.images.logo.image(height: 38),
                elevation: 0,
                leading: IconButton(
                  onPressed: drawerController.toggle,
                  icon: const Icon(Icons.menu),
                ),
                flexibleSpace: const AppBarThemed(),
                actions: [
                  IconButton(
                    onPressed: () => refreshKey.currentState?.show(),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ],
            body: RefreshIndicator(
              key: refreshKey,
              onRefresh: context.read<CardanoCubit>().refresh,
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: const <Widget>[
                  _Balance(),
                  SizedBox(height: 30),
                  _NftList(),
                  SizedBox(height: 30),
                  _TokenList(),
                ],
              ),
            ),
          ),
        ),
      );

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

class _HomeDrawer extends StatelessWidget {
  final VoidCallback onRefresh;
  const _HomeDrawer(this.onRefresh);
  @override
  Widget build(final BuildContext context) => Drawer(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(S.of(context).receive),
              leading: const Icon(Icons.wallet_sharp),
              onTap: () => context.router.push(const CardanoReceiveRoute()),
            ),
            BlocBuilder<CardanoCubit, CardanoState>(builder: _builder),
            ListTile(
              title: const Text("Logout"),
              leading: const Icon(Icons.logout),
              onTap: () async {
                await SessionProvider.signOut();
                if (!context.mounted) {
                  return;
                }
                context.router.replaceAll([const SignInRoute()]);
              },
            ),
          ],
        ),
      );

  Widget _builder(final BuildContext context, final CardanoState state) {
    final balance = state.balance;
    switch (balance) {
      case CardanoBalanceStatusLoading():
        return const ListTile(
          title: Text("Send"),
          leading: Icon(Icons.send_sharp),
          onTap: null,
        );
      case CardanoBalanceStatusFailure():
        return const ListTile(
          title: Text("Send"),
          leading: Icon(Icons.send_sharp),
          onTap: null,
        );
      case CardanoBalanceStatusSuccess():
        return ListTile(
          title: const Text("Send"),
          leading: const Icon(Icons.send_sharp),
          onTap: () async {
            await context.router.push(
              CardanoSendRoute(balance: balance.balance.cardano.coin),
            );
            onRefresh();
          },
        );
    }
  }
}

class _Balance extends StatelessWidget {
  const _Balance();

  @override
  Widget build(final BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: BlocBuilder<CardanoCubit, CardanoState>(builder: _builder),
          ),
        ),
      );

  Widget _builder(final BuildContext context, final CardanoState state) {
    switch (state.balance) {
      case CardanoBalanceStatusLoading():
        return LabeledText(
          labelStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
          textStyle: Theme.of(context).textTheme.headlineSmall,
          label: S.of(context).totalBalance,
          text: NumberFormat.currency(locale: "id", symbol: "Rp. ").format(0),
        );
      case CardanoBalanceStatusFailure():
        return LabeledText(
          labelStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
          textStyle: Theme.of(context).textTheme.headlineSmall,
          label: S.of(context).totalBalance,
          text: S.of(context).errorOccurred,
        );
      case CardanoBalanceStatusSuccess():
        return LabeledText(
          labelStyle: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
          textStyle: Theme.of(context).textTheme.headlineSmall,
          label: S.of(context).totalBalance,
          text: NumberFormat.currency(locale: "id", symbol: "Rp. ").format(
            (state.balance as CardanoBalanceStatusSuccess).totalBalance,
          ),
        );
    }
  }
}

class _NftList extends StatelessWidget {
  const _NftList();
  @override
  Widget build(final BuildContext context) => CardanoNftCardStatusList(
        onSelected: (final detail) => _onSelected(context, detail),
      );

  void _onSelected(
    final BuildContext context,
    final CardanoAssetDetail detail,
  ) async {
    final addressListRes = await getIt<WalletService>().cardanoAddresses();
    if (addressListRes.isSuccessful && context.mounted) {
      context.router.push(
        CardanoCollectibleRoute(
          policyId: detail.policyId,
          assetId: detail.assetId,
          address: addressListRes.body![0],
        ),
      );
    }
  }
}

class _TokenList extends StatelessWidget {
  const _TokenList();
  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: LabeledWidget(
          label: "Tokens",
          labelStyle: Theme.of(context).textTheme.titleMedium,
          content: BlocBuilder<CardanoCubit, CardanoState>(builder: _builder),
        ),
      );

  Widget _builder(final BuildContext context, final CardanoState state) {
    if (state.tokenList.isEmpty) {
      return const Empty();
    } else {
      final list = state.tokenList.toList(growable: false);
      return MasonryGridView.count(
        crossAxisCount: MediaQuery.of(context).size.width ~/ kGridSize,
        mainAxisSpacing: 5,
        crossAxisSpacing: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: list.length,
        itemBuilder: (final _, final index) => _TokenCard(list[index]),
      );
    }
  }
}

class _TokenCard extends StatelessWidget {
  final Token token;
  const _TokenCard(this.token);
  @override
  Widget build(final BuildContext context) => Card(
        elevation: 0,
        child: Column(
          children: [
            Image.network(token.image),
            GlassContainer(
              tintColor: Theme.of(context).colorScheme.primary,
              sigmaX: 30,
              sigmaY: 40,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Center(
                  child: Text(
                    "${token.name} ${token.balance}",
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
