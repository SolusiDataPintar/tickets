import 'package:auto_route/auto_route.dart';
import 'package:injectable/injectable.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/provider/session.dart';
import 'package:tickets/routes.gr.dart';

@Singleton()
@AutoRouterConfig(replaceInRouteName: 'Page,Route')
class AppRouter extends $AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          path: '/',
          page: CardanoHomeRoute.page,
          guards: const [_AuthGuard()],
        ),
        AutoRoute(
          path: '/cardano',
          page: CardanoHomeRoute.page,
          guards: const [_AuthGuard()],
        ),
        AutoRoute(
          path: '/cardano/collectible',
          page: CardanoCollectibleRoute.page,
          guards: const [_AuthGuard()],
        ),
        AutoRoute(
          path: '/cardano/receive',
          page: CardanoReceiveRoute.page,
          guards: const [_AuthGuard()],
        ),
        AutoRoute(
          path: '/cardano/send',
          page: CardanoSendRoute.page,
          guards: const [_AuthGuard()],
        ),
        AutoRoute(
          path: '/cardano/select',
          page: CardanoSelectAssetRoute.page,
          guards: const [_AuthGuard()],
        ),
        AutoRoute(
          path: '/qr/scan',
          page: QrScannerRoute.page,
        ),
        AutoRoute(
          path: '/image/view',
          page: ImageViewerRoute.page,
        ),
        AutoRoute(path: '*', page: SignInRoute.page),
      ];
}

class _AuthGuard extends AutoRouteGuard {
  const _AuthGuard();
  @override
  void onNavigation(
    final NavigationResolver resolver,
    final StackRouter router,
  ) {
    if (getIt.isRegistered<SessionProvider>()) {
      resolver.next(true);
    } else {
      resolver.redirect(const SignInRoute());
    }
  }
}
