import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:formz_submit_button/formz_submit_button.dart';
import 'package:tickets/bloc/signin/bloc.dart';
import 'package:tickets/bloc/signup/bloc.dart';
import 'package:tickets/generated/assets.gen.dart';
import 'package:tickets/generated/l10n.dart';
import 'package:tickets/routes.gr.dart';
import 'package:tickets/widget/glass.dart';
import 'package:tickets/widget/hide_keyboard_up.dart';
import 'package:tickets/widget/logo.dart';

@RoutePage()
class SignInPage extends StatelessWidget implements AutoRouteWrapper {
  const SignInPage({super.key});
  @override
  Widget build(final BuildContext context) => Scaffold(
        body: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: Assets.images.signinbg.provider(),
              fit: BoxFit.fill,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 450),
                  child: GlassContainer(
                    tintColor: Colors.black,
                    sigmaX: 30,
                    sigmaY: 40,
                    clipBorderRadius: BorderRadius.circular(10),
                    child: ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(20),
                      physics: const NeverScrollableScrollPhysics(),
                      children: const [
                        HideKeyboardUp(child: Logo()),
                        _EmailField(),
                        _PasswordField(),
                        SizedBox(height: 10),
                        _Button(),
                        SizedBox(height: 10),
                        _SignUpButton(),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget wrappedRoute(final BuildContext context) =>
      BlocProvider(create: (final _) => SignInBloc(), child: this);
}

const _kFieldCursorColor = Colors.white;

const _kFieldStyle = TextStyle(color: Colors.white);

const _kFieldBorder =
    UnderlineInputBorder(borderSide: BorderSide(color: Colors.white));

const _kFieldDecoration = InputDecoration(
  labelText: "Email",
  focusColor: Colors.white,
  fillColor: Colors.white,
  prefixIconColor: Colors.white,
  suffixIconColor: Colors.white,
  labelStyle: TextStyle(color: Colors.white),
  errorStyle: TextStyle(color: Colors.white),
  enabledBorder: _kFieldBorder,
  focusedBorder: _kFieldBorder,
  border: _kFieldBorder,
  errorBorder: _kFieldBorder,
  focusedErrorBorder: _kFieldBorder,
);

class _EmailField extends StatelessWidget {
  const _EmailField();
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<SignInBloc, SignInState>(builder: _builder);

  Widget _builder(final BuildContext context, final SignInState state) =>
      TextFormField(
        initialValue: state.email.value,
        cursorColor: _kFieldCursorColor,
        style: _kFieldStyle,
        decoration: _kFieldDecoration.copyWith(
          labelText: "Email",
          errorText: _errorHandler(context, state.email.displayError),
          prefixIcon: const Icon(Icons.mail_lock_sharp),
        ),
        onChanged: (final text) =>
            context.read<SignInBloc>().add(SignInEmailChanged(text)),
      );

  String? _errorHandler(
    final BuildContext context,
    final SignInEmailValidationError? e,
  ) {
    if (e == null) {
      return null;
    }
    switch (e) {
      case SignInEmailValidationError.empty:
        return S.of(context).errorEmailEmpty;
      case SignInEmailValidationError.notFound:
        return S.of(context).errorInvalidCredential;
    }
  }
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
      BlocBuilder<SignInBloc, SignInState>(builder: _builder);

  Widget _builder(final BuildContext context, final SignInState state) =>
      TextField(
        cursorColor: _kFieldCursorColor,
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
        onChanged: (final text) => context
            .read<SignInBloc>()
            .add(SignInPasswordChanged(password: text)),
      );

  String? _errorHandler(
    final BuildContext context,
    final SignInPasswordValidationError? e,
  ) {
    if (e == null) {
      return null;
    }
    switch (e) {
      case SignInPasswordValidationError.empty:
        return S.of(context).errorEmailEmpty;
      case SignInPasswordValidationError.invalid:
        return S.of(context).errorInvalidCredential;
      case SignInPasswordValidationError.unknown:
        return S.of(context).errorOccurred;
    }
  }
}

class _Button extends StatelessWidget {
  const _Button();
  @override
  Widget build(final BuildContext context) =>
      BlocConsumer<SignInBloc, SignInState>(
        listener: _listener,
        builder: _builder,
      );

  Widget _builder(final BuildContext context, final SignInState state) =>
      FormzSubmitButton(
        onPressed: () => context.read<SignInBloc>().add(SignInFormSubmitted()),
        status: state.status,
        color: const Color.fromARGB(95, 5, 235, 243).withOpacity(0.25),
        child: Text(
          S.of(context).signIn,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );

  void _listener(final BuildContext context, final SignInState state) {
    if (state.status == FormzSubmissionStatus.success) {
      context.router.replaceAll([const CardanoHomeRoute()]);
    }
  }
}

class _SignUpButton extends StatelessWidget {
  const _SignUpButton();
  @override
  Widget build(final BuildContext context) => Center(
        child: TextButton(
          onPressed: () => _onPressed(context),
          style: const ButtonStyle(
            foregroundColor: MaterialStatePropertyAll(Colors.white),
          ),
          child: Text(S.of(context).signUp),
        ),
      );

  void _onPressed(final BuildContext context) => showDialog(
        context: context,
        builder: (final _) => const _SignUpDialog(),
      );
}

class _SignUpDialog extends StatefulWidget {
  const _SignUpDialog();
  @override
  State<StatefulWidget> createState() => _SignUpDialogState();
}

class _SignUpDialogState extends State<_SignUpDialog> {
  bool isSuccess = false;
  @override
  Widget build(final BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300, maxWidth: 500),
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              child: BlocProvider(
                create: (final _) => SignUpBloc(),
                child: BlocListener<SignUpBloc, SignUpState>(
                  listener: _listener,
                  child: _build(),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _build() {
    if (isSuccess) {
      return _SignUpSuccess();
    } else {
      return const _SignUpForm();
    }
  }

  void _listener(final BuildContext context, final SignUpState state) {
    if (state.status == FormzSubmissionStatus.success) {
      Future.delayed(const Duration(seconds: 3)).then(
        (final _) => setState(() => isSuccess = true),
      );
    }
  }
}

class _SignUpSuccess extends StatelessWidget {
  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              S.of(context).signUp,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              S.of(context).signUpSuccess,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: context.router.pop,
                style: const ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll(Colors.white),
                ),
                child: Text(S.of(context).close),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      );
}

class _SignUpForm extends StatelessWidget {
  const _SignUpForm();
  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Text(
              S.of(context).signUp,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            const _SignUpEmailField(),
            const SizedBox(height: 20),
            const _SignUpSubmitButton(),
            const SizedBox(height: 10),
          ],
        ),
      );
}

class _SignUpEmailField extends StatelessWidget {
  const _SignUpEmailField();
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<SignUpBloc, SignUpState>(builder: _builder);

  Widget _builder(final BuildContext context, final SignUpState state) =>
      TextFormField(
        initialValue: state.email.value,
        cursorColor: _kFieldCursorColor,
        style: _kFieldStyle,
        decoration: _kFieldDecoration.copyWith(
          labelText: "Email",
          errorText: _errorHandler(context, state.email.displayError),
          prefixIcon: const Icon(Icons.mail_lock_sharp),
        ),
        onChanged: (final text) => context.read<SignUpBloc>().email = text,
      );

  String? _errorHandler(
    final BuildContext context,
    final SignUpEmailValidationError? e,
  ) {
    if (e == null) {
      return null;
    }
    switch (e) {
      case SignUpEmailValidationError.empty:
        return S.of(context).errorEmailEmpty;
      case SignUpEmailValidationError.invalid:
        return S.of(context).errorInvalidEmail;
      case SignUpEmailValidationError.unknown:
        return S.of(context).errorOccurred;
    }
  }
}

class _SignUpSubmitButton extends StatelessWidget {
  const _SignUpSubmitButton();
  @override
  Widget build(final BuildContext context) =>
      BlocBuilder<SignUpBloc, SignUpState>(builder: _builder);

  Widget _builder(final BuildContext context, final SignUpState state) =>
      FormzSubmitButton(
        onPressed: context.read<SignUpBloc>().submit,
        status: state.status,
        color: const Color.fromARGB(95, 5, 235, 243).withOpacity(0.25),
        child: Text(
          S.of(context).signUp,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
}
