import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:tickets/generated/l10n.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/routes.dart';

part 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(final BuildContext context) => MaterialApp.router(
        localizationsDelegates: const [
          GlobalWidgetsLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
          S.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        debugShowCheckedModeBanner: false,
        locale: const Locale("id", ""),
        theme: _theme,
        routerConfig: getIt<AppRouter>().config(),
      );
}
