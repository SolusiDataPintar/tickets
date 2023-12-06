import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:formz_submit_button/formz_submit_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tickets/bloc/cardano/cubit.dart';
import 'package:tickets/bloc/cardano/send/cubit.dart';
import 'package:tickets/cardano/cardano.dart';
import 'package:tickets/generated/l10n.dart';
import 'package:tickets/model/cardano.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/routes.gr.dart';
import 'package:tickets/widget/appbarthemed.dart';
import 'package:tickets/widget/cardano/nft.dart';
import 'package:tickets/widget/glass.dart';
import 'package:tickets/widget/labeled_widget.dart';
import 'package:tickets/widget/logo.dart';

const _kFieldStyle = TextStyle(color: Color.fromARGB(255, 5, 116, 243));

const _kFieldBorder = UnderlineInputBorder(
  borderSide: BorderSide(color: Color.fromARGB(255, 15, 14, 14)),
  borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
);

const _kFieldDecoration = InputDecoration(
  labelText: "Choose Account",
  focusColor: Color.fromARGB(255, 44, 17, 17),
  fillColor: Color.fromARGB(255, 0, 0, 0),
  prefixIconColor: Color.fromARGB(255, 15, 14, 14),
  suffixIconColor: Color.fromARGB(255, 223, 24, 24),
  labelStyle: TextStyle(color: Color.fromARGB(255, 5, 4, 4)),
  errorStyle: TextStyle(color: Colors.white),
  enabledBorder: _kFieldBorder,
  focusedBorder: _kFieldBorder,
  border: _kFieldBorder,
  errorBorder: _kFieldBorder,
  focusedErrorBorder: _kFieldBorder,
);

@RoutePage()
class CardanoSendPage extends StatefulWidget implements AutoRouteWrapper {
  final int balance;
  const CardanoSendPage({super.key, required this.balance});
  @override
  State<StatefulWidget> createState() => _CardanoSendPageState();

  @override
  Widget wrappedRoute(final BuildContext context) => BlocProvider(
        create: (final _) {
          if (getIt.isRegistered<CardanoCubit>()) {
            return getIt<CardanoCubit>();
          } else {
            return getIt.registerSingleton(CardanoCubit());
          }
        },
        child:
            BlocProvider(create: (final _) => CardanoSendCubit(), child: this),
      );
}

class _CardanoSendPageState extends State<CardanoSendPage> {
  @override
  Widget build(final BuildContext context) => Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (final _, final __) => <Widget>[
            SliverAppBar(
              title: Text(S.of(context).send),
              elevation: 0,
              flexibleSpace: const AppBarThemed(),
            ),
          ],
          body: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              const _ReceiverField(),
              const SizedBox(height: 30),
              _Ada(widget.balance),
              const SizedBox(height: 10),
              const _NftList(),
              const SizedBox(height: 30),
              const _PasswordField(),
              const SizedBox(height: 10),
              const _Button(),
            ],
          ),
        ),
        floatingActionButton: BlocBuilder<CardanoSendCubit, CardanoSendState>(
          builder: (final _, final state) => FloatingActionButton(
            onPressed: () => onAddAsset(state.selectedAssets),
            child: const Icon(Icons.add),
          ),
        ),
      );

  Future<void> onAddAsset(final List<CardanoAssetDetail> selecteds) async {
    final unselectedAssets = <CardanoAssetDetail>[];
    final assetList = getIt<CardanoCubit>()
        .state
        .nftList
        .whereType<CardanoAssetStatusSuccess>()
        .map((final e) => e.detail);
    for (final a in assetList) {
      final contains = selecteds
          .where(
            (final e) => e.policyId == a.policyId && e.assetName == a.assetName,
          )
          .firstOrNull;
      if (contains == null) {
        unselectedAssets.add(a);
      }
    }
    final res = await context.router.push<CardanoAssetDetail>(
      CardanoSelectAssetRoute(
        list: unselectedAssets,
      ),
    );
    if (res == null || !context.mounted) {
      return;
    }
    context.read<CardanoSendCubit>().changeAsset(res);
  }
}

class _ReceiverField extends StatelessWidget {
  const _ReceiverField();
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<CardanoSendCubit, CardanoSendState>(builder: _builder);

  Widget _builder(final BuildContext context, final CardanoSendState state) =>
      TextFormField(
        decoration: InputDecoration(
          labelText: S.of(context).receiver,
          errorText: _errorHandler(context, state.receiver.displayError),
          prefix: const Icon(Icons.wallet_sharp),
          suffixIcon: IconButton(
            icon: const Icon(Icons.qr_code_scanner_sharp),
            onPressed: () => onScanned(context),
          ),
        ),
        onChanged: (final text) =>
            context.read<CardanoSendCubit>().receiver = text,
      );

  String? _errorHandler(
    final BuildContext context,
    final CardanoSendReceiverValidationError? e,
  ) {
    if (e == null) {
      return null;
    }
    switch (e) {
      case CardanoSendReceiverValidationError.empty:
        return "Penerima tidak boleh kosong";
    }
  }

  Future<void> onScanned(final BuildContext context) async {
    final res = await context.router.push<String?>(const QrScannerRoute());
    if (res == null) {
      return;
    }
    if (!context.mounted) {
      return;
    }
    context.read<CardanoSendCubit>().receiver = res;
  }
}

class _Ada extends StatefulWidget {
  final int balance;
  const _Ada(this.balance);
  @override
  State<StatefulWidget> createState() => _AdaState();
}

class _AdaState extends State<_Ada> {
  late final TextEditingController textEditingController;
  @override
  Widget build(final BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("ADA"),
              BlocBuilder<CardanoCubit, CardanoState>(builder: _adaBuilder),
            ],
          ),
          const SizedBox(width: 20),
          Flexible(
            child: BlocBuilder<CardanoSendCubit, CardanoSendState>(
              builder: _builder,
            ),
          ),
        ],
      );

  Widget _builder(final BuildContext context, final CardanoSendState state) =>
      TextField(
        controller: textEditingController,
        decoration: InputDecoration(
          suffix: TextButton(
            onPressed: () => textEditingController.text =
                "${lovelaceToAda(widget.balance.toDouble())}",
            child: const Text("Max"),
          ),
          errorText: _errorHandler(context, state.lovelace.displayError),
        ),
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(
          signed: true,
          decimal: true,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (final text) => context.read<CardanoSendCubit>().lovelace =
            adaToLovelace(double.tryParse(text) ?? 0).toInt(),
      );

  Widget _adaBuilder(final BuildContext context, final CardanoState state) =>
      Text('balance: ${lovelaceToAda(widget.balance.toDouble()).toDouble()}');

  String? _errorHandler(
    final BuildContext context,
    final CardanoSendLovelaceValidationError? e,
  ) {
    if (e == null) {
      return null;
    }
    switch (e) {
      case CardanoSendLovelaceValidationError.empty:
        return S.of(context).errorNotEnoughBalance;
    }
  }

  @override
  void initState() {
    super.initState();
    textEditingController = TextEditingController();
  }

  @override
  void dispose() {
    textEditingController.dispose();
    super.dispose();
  }
}

class _NftList extends StatelessWidget {
  const _NftList();
  @override
  Widget build(final BuildContext context) => LabeledWidget(
        label: "NFT",
        labelStyle: Theme.of(context).textTheme.titleMedium,
        content: BlocBuilder<CardanoSendCubit, CardanoSendState>(
          builder: _builder,
        ),
      );

  Widget _builder(final BuildContext context, final CardanoSendState state) =>
      CardanoNftList(list: state.selectedAssets);
}

class _PasswordField extends StatefulWidget {
  const _PasswordField();
  @override
  State<StatefulWidget> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool obscurePassword = true;
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<CardanoSendCubit, CardanoSendState>(builder: _builder);

  Widget _builder(final BuildContext context, final CardanoSendState state) =>
      TextField(
        style: _kFieldStyle,
        decoration: _kFieldDecoration.copyWith(
          labelText: S.of(context).password,
          errorText: _errorHandler(context, state.password.displayError),
          prefixIcon: const Icon(Icons.lock_sharp),
          suffixIcon: IconButton(
            icon: obscurePassword
                ? const Icon(Icons.visibility_sharp)
                : const Icon(Icons.visibility_off_sharp),
            onPressed: () => setState(() => obscurePassword = !obscurePassword),
          ),
        ),
        obscureText: obscurePassword,
        onChanged: (final text) =>
            context.read<CardanoSendCubit>().password = text,
      );

  String? _errorHandler(
    final BuildContext context,
    final CardanoSendPasswordValidationError? e,
  ) {
    if (e == null) {
      return null;
    }
    switch (e) {
      case CardanoSendPasswordValidationError.empty:
        return S.of(context).errorEmailEmpty;
      case CardanoSendPasswordValidationError.invalid:
        return S.of(context).errorInvalidCredential;
      case CardanoSendPasswordValidationError.unknown:
        return S.of(context).errorOccurred;
    }
  }
}

class _Button extends StatelessWidget {
  const _Button();
  @override
  Widget build(final BuildContext context) =>
      BlocConsumer<CardanoSendCubit, CardanoSendState>(
        listener: _listener,
        builder: _builder,
      );

  Widget _builder(final BuildContext context, final CardanoSendState state) =>
      FormzSubmitButton(
        onPressed: context.read<CardanoSendCubit>().submit,
        status: state.status,
        child: Text(
          S.of(context).send,
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
      );

  void _listener(final BuildContext context, final CardanoSendState state) {
    if (state.status == FormzSubmissionStatus.success) {
      showDialog(
        context: context,
        builder: (final BuildContext context) => _SendSuccessDialog(
          state.transactionHash,
        ),
      );
    }
  }
}

class _SendSuccessDialog extends StatelessWidget {
  final String trxHash;
  const _SendSuccessDialog(this.trxHash);
  @override
  Widget build(final BuildContext context) => Material(
        color: Colors.transparent,
        elevation: 0.0,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: GlassContainer(
              tintColor: Colors.black,
              sigmaX: 30,
              sigmaY: 40,
              clipBorderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(20),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      const Center(child: Logo()),
                      const SizedBox(height: 30),
                      Text(
                        S.of(context).sendSuccess,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        child: Text(
                          trxHash,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 30),
                      TextButton(
                        onPressed: () async {
                          final uri = Uri.parse(
                            "https://cardanoscan.io/transaction/$trxHash",
                          );
                          if (await canLaunchUrl(uri)) {
                            launchUrl(uri);
                          }
                        },
                        style: const ButtonStyle(
                          foregroundColor:
                              MaterialStatePropertyAll(Colors.white),
                        ),
                        child: Text(S.of(context).openExplorer),
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      onPressed: Navigator.of(context).pop,
                      color: Colors.white,
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
