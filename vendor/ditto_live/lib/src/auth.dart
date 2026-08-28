import "package:equatable/equatable.dart";
import "package:meta/meta.dart";

import "../ditto_live.dart";
import "analysis/annotations.dart";
import "ditto.dart";

import "bridge/bridge.dart" as core;

/// A function that handles authentication expiration events for Ditto.
///
/// This handler is called when the authentication for a Ditto instance has or is
/// about to expire, or if authentication has not yet occurred. It provides the
/// relevant `Ditto` instance and the time interval (in seconds) until expiration.
/// You can use this to login or to perform other necessary actions before
/// authentication expires.
///
/// Important - when using server connections (i.e. a [DittoConfigConnectServer]),
/// you **must** set an expiration handler via [Authenticator.expirationHandler].
/// Otherwise [Sync.start] will throw a [DittoException].
@external
typedef AuthenticationExpirationHandler = void Function(
  Ditto ditto,
  Duration timeUntilExpiration,
);

@internal
Authenticator makeAuthenticator(Ditto ditto) => Authenticator._(ditto);

@internal
Future<void> cleanupAuth(Authenticator auth) => auth._cleanup();

/// An object that provides access to authentication information and provides methods
/// for logging into Ditto Cloud.
///
/// An instance of [Authenticator] can be obtained from [Ditto.auth]:
/// ```dart
/// final ditto = await Ditto.open(/* ... */);
/// final auth = ditto.auth;
/// ```
///
/// This class is not user-constructible.
@external
final class Authenticator {
  final Ditto ditto;

  Authenticator._(this.ditto);

  /// The built-in development authentication provider to be used together with
  /// development authentication tokens.
  ///
  /// Example usage:
  /// ```dart
  /// await ditto.auth.login(
  ///   token: yourDevelopmentToken,
  ///   provider: Authenticator.developmentProvider,
  /// );
  /// ```
  // ignore: non_constant_identifier_names
  static String get developmentProvider =>
      core.dittoffiGetDevelopmentProvider();

  /// The current authentication status
  AuthenticationStatus get status => AuthenticationStatus(
        userID: core.dittoAuthClientUserId(ditto.ptr),
        isAuthenticated: core.dittoAuthClientIsWebValid(ditto.ptr),
      );

  /// Logs into Ditto using a third-party authentication token
  Future<AuthResponse> login({
    required String token,
    required String provider,
  }) async =>
      core.dittoAuthClientLoginWithTokenAndFeedback(
        ditto.ptr,
        token,
        provider,
      );

  /// Logs out of Ditto.
  ///
  /// Stops sync as part of logout, matching the Kotlin and Cocoa SDKs. Core
  /// does not yet stop sync on logout itself (see SDKS-1550), so the SDK
  /// makes the two operations atomic from the caller's perspective.
  Future<void> logout() async {
    await core.dittoAuthClientLogout(ditto.ptr).extract();
    core.dittoFfiDittoStopSync(ditto.ptr);
  }

  AuthenticationExpirationHandler? _expirationHandler;
  core.CPFreeable? _expirationHandlerFreeable;
  bool _isShuttingDown = false;

  AuthenticationExpirationHandler? get expirationHandler => _expirationHandler;

  Future<void> setExpirationHandler(
    AuthenticationExpirationHandler? value,
  ) async {
    // TODO(cameron): stop leaking these. For now, not a huge issue, since it's
    // not very many resources. Requires the retain/release mechanism to be
    // implemented, which we haven't implemented yet.
    // final oldFreeable = _expirationHandlerFreeable;

    if (value == null) {
      await core.dittoAuthSetLoginProvider(ditto.ptr, null);
      _expirationHandler = null;
      _expirationHandlerFreeable = null;
    } else {
      final (provider, freeable) =
          core.dittoAuthClientMakeLoginProvider(ditto.ptr, (seconds) {
        // Guard against callbacks arriving during/after shutdown (SDKS-3626).
        // Same crash class as SDKS-3134 but for auth: invoking the user's
        // handler while the Dart isolate is tearing down can SIGABRT.
        if (_isShuttingDown) return;
        value(ditto, Duration(seconds: seconds));
      });

      await core.dittoAuthSetLoginProvider(ditto.ptr, provider);
      _expirationHandler = value;
      _expirationHandlerFreeable = freeable;
    }

    // oldFreeable?.free();
  }

  /// Internal cleanup method called when Ditto is closing.
  /// Frees the auth login provider's NativeCallable safely before shutdown.
  ///
  /// To prevent SIGABRT from callbacks arriving after the NativeCallable is
  /// closed (SDKS-3626, mirrors SDKS-3134 for presence), the cleanup is
  /// sequenced via the `CPMultiFreeable` returned by the bridge:
  ///   [0] CPDartFnFreeable - deregisters the provider from the auth client
  ///       via `ditto_auth_set_login_provider(null)`, so no new callbacks
  ///       are scheduled (auth equivalent of presence's
  ///       `ditto_clear_presence_v3_callback`).
  ///   [1] NativeCallableFreeable - closes the NativeCallable.
  ///
  /// We free [0], wait for in-flight callbacks to drain, then free [1]. The
  /// shutdown flag set first ensures any callback that *does* land between
  /// [0] and [1] becomes a no-op rather than dispatching to user code on a
  /// dying isolate.
  ///
  /// This method is async and MUST be awaited to ensure cleanup completes
  /// before the Dart VM/isolate shuts down.
  Future<void> _cleanup() async {
    _isShuttingDown = true;
    final freeable = _expirationHandlerFreeable;
    _expirationHandlerFreeable = null;
    _expirationHandler = null;
    if (freeable == null) return;

    if (freeable is core.CPMultiFreeable) {
      final freeables = freeable.freeables.toList();
      if (freeables.isNotEmpty) {
        freeables[0].free();
        // 500ms matches presence cleanup; provides margin on slower CI
        // machines for in-flight callbacks to arrive and be ignored.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        for (var i = 1; i < freeables.length; i++) {
          freeables[i].free();
        }
      }
    } else {
      // Fallback for non-CPMultiFreeable (e.g. WASM noop). The delay is
      // unnecessary on web where there is no NativeCallable, but cheap.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      freeable.free();
    }
  }
}

/// Provides info about the authentication status.
@external
final class AuthenticationStatus with EquatableMixin {
  /// Indicates whether the user is authenticated.
  /// `true` if authenticated, otherwise `false`.
  final bool isAuthenticated;

  /// The user ID provided by the authentication service, if authenticated.
  /// `null` if not authenticated or no user ID was provided.
  final String? userID;

  AuthenticationStatus({
    this.isAuthenticated = false,
    this.userID,
  });

  /// @nodoc
  @override
  List<Object?> get props => [isAuthenticated, userID];

  @override
  String toString() =>
      "AuthenticationStatus(isAuthenticated: $isAuthenticated, userID: $userID)";
}
