import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:openid_client/openid_client.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:tickets/bloc/cardano/cubit.dart';
import 'package:tickets/config/config.dart';
import 'package:tickets/model/auth.dart';
import 'package:tickets/model/httperror.dart';
import 'package:tickets/model/price.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/service/auth.dart';
import 'package:tickets/service/price.dart';

class ExceptionInvalidCredential implements Exception {
  String cause;
  ExceptionInvalidCredential(this.cause);
}

class SessionProvider {
  final Credential _credential;
  String _accessToken;
  UserInfo userInfo;
  Price _price = const Price();
  SessionProvider(final String accessToken, final Credential credential)
      : _accessToken = accessToken,
        _credential = credential,
        userInfo = UserInfo.fromJson({});

  static Future<void>? _refreshSessionFuture;
  String accessToken() => "Bearer $_accessToken";
  Price get price => _price;

  Future<String> refreshAccessToken() async {
    if (_refreshSessionFuture != null) await _refreshSessionFuture;
    if (shouldRefreshAccessToken()) {
      Completer<void> completer;
      if (_refreshSessionFuture == null) {
        completer = Completer();
        _refreshSessionFuture = completer.future;
        try {
          final res = await _credential.getTokenResponse();
          _accessToken = res.accessToken!;
        } catch (error, st) {
          Future.delayed(
            Duration.zero,
            () => getIt.unregister<SessionProvider>(),
          );
          Sentry.captureException(error, stackTrace: st);
          return "Bearer ";
        } finally {
          completer.complete();
          _refreshSessionFuture = null;
        }
      } else {
        await _refreshSessionFuture;
      }
    }
    return "Bearer $_accessToken";
  }

  bool shouldRefreshAccessToken() => true;

  Future<void> refreshData() async {
    userInfo = await _credential.getUserInfo();
    Future.delayed(Duration.zero, loadPrice);
  }

  Future<void> loadPrice() async {
    try {
      final res = await getIt<PriceService>().get();
      if (res.isSuccessful) {
        _price = res.body!;
      } else {
        throw res.error as HttpError;
      }
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrintStack(stackTrace: st);
    }
  }

  static bool get hasSession => getIt.isRegistered<SessionProvider>();
  static Future<void> signIn(
    final String email,
    final String password,
  ) async {
    final issuer = await Issuer.discover(Uri.parse(Env.authUrl));
    final client = Client(issuer, Env.authId, clientSecret: Env.authSecret);
    final res = await getIt<AuthService>().signIn(
      SignIn(
        grantType: 'password',
        clientId: Env.authId,
        clientSecret: Env.authSecret,
        username: email,
        password: password,
        scope: 'openid',
      ),
    );
    if (res.isSuccessful) {
      final tokenPair = res.body!;
      final credential = client.createCredential(
        accessToken: tokenPair.accessToken,
        refreshToken: tokenPair.refreshToken,
        expiresIn: tokenPair.expireIn,
      );
      final session = SessionProvider(tokenPair.accessToken, credential);
      await session.loadPrice();
      getIt.registerSingleton(session);
    } else {
      if (res.statusCode == 401) {
        throw ExceptionInvalidCredential(res.error.toString());
      } else {
        throw res.error as HttpError;
      }
    }
  }

  static Future<void> signOut() async {
    try {
      final cred = getIt<SessionProvider>()._credential;
      await getIt.unregister<SessionProvider>();
      if (getIt.isRegistered<CardanoCubit>()) {
        await getIt.unregister<CardanoCubit>();
      }
      final url = cred.generateLogoutUrl();
      if (url == null) {
        return;
      }
      http.get(url);
    } catch (err, st) {
      debugPrint(err.toString());
      debugPrintStack(stackTrace: st);
      Sentry.captureException(err, stackTrace: st);
    }
  }
}
