import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:synchronized/synchronized.dart';
import 'package:tickets/config/config.dart';
import 'package:tickets/model/httperror.dart';
import 'package:tickets/provider/injector.dart';
import 'package:tickets/provider/session.dart';

@Singleton()
final class AuthHttpClient extends ChopperClient {
  @FactoryMethod()
  static AuthHttpClient create() => AuthHttpClient(
        baseUrl: Uri.parse(Env.authUrl),
        converter: const JsonConverter(),
        errorConverter: const _ErrorConverter(),
      );
  AuthHttpClient({super.baseUrl, super.converter, super.errorConverter});
}

@Singleton()
final class HttpClient extends ChopperClient {
  @FactoryMethod()
  static HttpClient create() => HttpClient(
        baseUrl: Uri.parse(Env.url),
        converter: const JsonConverter(),
        errorConverter: const _ErrorConverter(),
        authenticator: const AppAuthenticator(),
        interceptors: [const AuthInterceptor()],
      );
  HttpClient({
    super.baseUrl,
    super.converter,
    super.errorConverter,
    super.authenticator,
    super.interceptors,
  });
}

@Singleton()
final class TicketHttpClient extends ChopperClient {
  @FactoryMethod()
  static TicketHttpClient create() => TicketHttpClient(
        baseUrl: Uri.parse(Env.ticketUrl),
        converter: const JsonConverter(),
        errorConverter: const _ErrorConverter(),
        authenticator: const AppAuthenticator(),
        interceptors: [const AuthInterceptor()],
      );
  TicketHttpClient({
    super.baseUrl,
    super.converter,
    super.errorConverter,
    super.authenticator,
    super.interceptors,
  });
}

class _ErrorConverter implements ErrorConverter {
  const _ErrorConverter();
  @override
  FutureOr<Response> convertError<BodyType, InnerType>(
    final Response response,
  ) {
    try {
      final body = jsonDecode(response.body);
      return response.copyWith<HttpError>(body: HttpError.fromJson(body));
    } catch (_, __) {
      return response;
    }
  }
}

class AppAuthenticator implements Authenticator {
  static final lock = Lock();
  const AppAuthenticator();
  @override
  FutureOr<Request?> authenticate(
    final Request request,
    final Response response, [
    final Request? originalRequest,
  ]) async {
    // 401
    if (response.statusCode == HttpStatus.unauthorized) {
      // Trying to update token only 1 time
      if (request.headers['Retry-Count'] != null) {
        return null;
      }

      try {
        final access = await lock.synchronized(() async {
          try {
            return await getIt<SessionProvider>().refreshAccessToken();
          } catch (err, st) {
            debugPrint(err.toString());
            debugPrintStack(stackTrace: st);
            return null;
          }
        });

        if (access == null) {
          return null;
        }

        return applyHeaders(
          request,
          {
            HttpHeaders.authorizationHeader: access,
            // Setting the retry count to not end up in an infinite loop
            // of unsuccessful updates
            'Retry-Count': '1',
          },
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  AuthenticationCallback? get onAuthenticationFailed => null;

  @override
  AuthenticationCallback? get onAuthenticationSuccessful => null;
}

class AuthInterceptor implements RequestInterceptor {
  const AuthInterceptor();
  @override
  Request onRequest(final Request request) {
    if (getIt.isRegistered<SessionProvider>()) {
      final updatedRequest = applyHeader(
        request,
        HttpHeaders.authorizationHeader,
        getIt<SessionProvider>().accessToken(),
        override: false,
      );
      return updatedRequest;
    } else {
      return request;
    }
  }
}
