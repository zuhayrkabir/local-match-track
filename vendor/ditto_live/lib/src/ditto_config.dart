// ignore_for_file: unnecessary_cast

// ignore_for_file: avoid_bool_literals_in_conditional_expressions, ditto_missing_visibility, require_trailing_commas, cast_nullable_to_non_nullable, annotate_overrides
// WARNING: DO NOT EDIT - generated from `types/transort-config.kdl`
import "package:meta/meta.dart";
import "analysis/annotations.dart";

import "auth.dart";
import "ditto.dart";
import "logger.dart";
import "sync.dart";

/// A configuration object for initializing a [Ditto] instance.
///
/// [DittoConfig] encapsulates all the parameters required to configure a Ditto
/// instance, including identity, connectivity, persistence, and experimental
/// features.

@immutable
@external
final class DittoConfig {
  /// The unique identifier for the Ditto database.
  ///
  /// This must be a valid UUID string. You can find the database ID in the Ditto
  /// portal, or provide your own if you only need to sync with a small peers only.
  ///
  /// - Note: "Database ID" was previously referred to as "App ID" in older versions
  /// of the SDK.
  final String? databaseID;

  /// The connectivity configuration for this Ditto instance.
  ///
  /// Specifies how this instance discovers and connects to peers, including network
  /// settings and authentication options.
  final DittoConfigConnect connect;

  /// The persistence directory used by Ditto to persist data.
  ///
  /// When a relative path is provided, it will be resolved relative to the
  /// application documents directory (i.e. the return value of `await
  /// getApplicationDocumentsDirectory()` from `package:path_provider`).
  ///
  /// When `null` is provided, Ditto will use a default directory name of
  /// `ditto-{database-id}` within the [Ditto/defaultRootDirectory] where
  /// `{database-id}` corresponds to the lowercase version of the [databaseID] passed
  /// alongside the [DittoConfig].
  ///
  /// To access the final resolved absolute path after creating a Ditto instance, use
  /// [Ditto.absolutePersistenceDirectory]. This property will always return the
  /// effective absolute file path being used, regardless of whether you provided an
  /// absolute path, relative path, or `null`.
  ///
  /// Note: "Database ID" was previously referred to as "App ID" in older versions
  /// of the SDK.
  ///
  /// Note: It is not recommended to directly read from or write to this directory,
  /// as its structure and contents are managed by Ditto and may change in future
  /// versions.
  ///
  /// Note: When [DittoLogger] is enabled, logs may be written to this directory
  /// even after a Ditto instance has been deallocated. Please refer to the
  /// documentation of [DittoLogger] for more information.
  ///
  /// See also:
  /// - [Ditto.absolutePersistenceDirectory]
  /// - [Ditto.defaultRootDirectory]
  final String? persistenceDirectory;

  /// Configuration for experimental features.
  ///
  /// This property allows you to enable or configure features that are not yet part
  /// of the stable API. Use with caution, as experimental features may change or be
  /// removed in future releases.
  ///
  /// Warning: Experimental functionality should not be used in production
  /// applications as it may be changed or removed at any time, and may not have the
  /// same security features.
  final DittoConfigExperimental experimental;

  const DittoConfig({
    this.databaseID = "00000000-0000-0000-0000-000000000000",
    this.connect = const DittoConfigConnectSmallPeersOnly(),
    this.persistenceDirectory,
    this.experimental = const DittoConfigExperimental(),
  });

  static DittoConfigBuilder builder({
    String? databaseID = "00000000-0000-0000-0000-000000000000",
    DittoConfigConnect connect = const DittoConfigConnectSmallPeersOnly(),
    String? persistenceDirectory,
    DittoConfigExperimental experimental = const DittoConfigExperimental(),
  }) =>
      DittoConfigBuilder(
        databaseID: databaseID == null ? null : (databaseID as String),
        connect: connect.toBuilder(),
        persistenceDirectory: persistenceDirectory == null
            ? null
            : (persistenceDirectory as String),
        experimental: experimental.toBuilder(),
      );
  DittoConfigBuilder toBuilder() => DittoConfigBuilder(
        databaseID: databaseID == null ? null : (databaseID as String),
        connect: connect.toBuilder(),
        persistenceDirectory: persistenceDirectory == null
            ? null
            : (persistenceDirectory as String),
        experimental: experimental.toBuilder(),
      );

  Map<String, dynamic> toJson() => {
        "database_id": databaseID,
        "connect": connect.toJson(),
        "persistence_directory": persistenceDirectory,
        "experimental": experimental.toJson(),
      };
  factory DittoConfig.fromJson(Map<String, dynamic> json) => DittoConfig(
        databaseID: json["database_id"] == null
            ? "00000000-0000-0000-0000-000000000000"
            : json["database_id"] == null
                ? null
                : json["database_id"] as String,
        connect: json["connect"] == null
            ? const DittoConfigConnectSmallPeersOnly()
            : DittoConfigConnect.fromJson(
                json["connect"] as Map<String, dynamic>),
        persistenceDirectory: json["persistence_directory"] == null
            ? null
            : json["persistence_directory"] == null
                ? null
                : json["persistence_directory"] as String,
        experimental: json["experimental"] == null
            ? const DittoConfigExperimental()
            : DittoConfigExperimental.fromJson(
                json["experimental"] as Map<String, dynamic>,
              ),
      );

  @override
  String toString() => "DittoConfig("
      "databaseID: $databaseID, "
      "connect: $connect, "
      "persistenceDirectory: $persistenceDirectory, "
      "experimental: $experimental"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! DittoConfig) {
      return false;
    }
    if (databaseID != other.databaseID) {
      return false;
    }
    if (connect != other.connect) {
      return false;
    }
    if (persistenceDirectory != other.persistenceDirectory) {
      return false;
    }
    if (experimental != other.experimental) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
        databaseID?.hashCode,
        connect.hashCode,
        persistenceDirectory?.hashCode,
        experimental.hashCode,
      ]);
}

/// Builder class for [DittoConfig]

@external
final class DittoConfigBuilder {
  String? databaseID;
  DittoConfigConnectBuilder connect;
  String? persistenceDirectory;
  DittoConfigExperimentalBuilder experimental;

  DittoConfigBuilder({
    required this.databaseID,
    required this.connect,
    required this.persistenceDirectory,
    required this.experimental,
  });

  DittoConfig build() => DittoConfig(
        databaseID: databaseID == null ? null : (databaseID as String),
        connect: connect.build(),
        persistenceDirectory: persistenceDirectory == null
            ? null
            : (persistenceDirectory as String),
        experimental: experimental.build(),
      );
}

/// Experimental configuration options for [DittoConfig].
///
/// This class allows you to enable or configure features that are not yet part of
/// the stable API. Use with caution, as experimental features may change or be
/// removed in future releases.
///
/// Warning: Experimental functionality should not be used in production
/// applications as it may be changed or removed at any time, and may not have the
/// same security features.

@immutable
@external
final class DittoConfigExperimental {
  /// The passphrase used to encrypt & decrypt the data of a Ditto instance, if
  /// provided.  This feature is undocumented and for internal use only.
  final String? passphrase;

  const DittoConfigExperimental({this.passphrase});

  static DittoConfigExperimentalBuilder builder({String? passphrase}) =>
      DittoConfigExperimentalBuilder(
        passphrase: passphrase == null ? null : (passphrase as String),
      );
  DittoConfigExperimentalBuilder toBuilder() => DittoConfigExperimentalBuilder(
        passphrase: passphrase == null ? null : (passphrase as String),
      );

  Map<String, dynamic> toJson() => {"passphrase": passphrase};
  factory DittoConfigExperimental.fromJson(Map<String, dynamic> json) =>
      DittoConfigExperimental(
        passphrase: json["passphrase"] == null
            ? null
            : json["passphrase"] == null
                ? null
                : json["passphrase"] as String,
      );

  @override
  String toString() => "DittoConfigExperimental("
      "passphrase: $passphrase"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! DittoConfigExperimental) {
      return false;
    }
    if (passphrase != other.passphrase) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([passphrase?.hashCode]);
}

/// Builder class for [DittoConfigExperimental]

@external
final class DittoConfigExperimentalBuilder {
  String? passphrase;

  DittoConfigExperimentalBuilder({required this.passphrase});

  DittoConfigExperimental build() => DittoConfigExperimental(
        passphrase: passphrase == null ? null : (passphrase as String),
      );
}

/// Specifies how this instance discovers and connects to peers, including network
/// settings and authentication options. This is a substructure of [DittoConfig].

@immutable
@external
abstract final class DittoConfigConnect {
  const DittoConfigConnect();

  DittoConfigConnectBuilder toBuilder();

  Map<String, dynamic> toJson();
  factory DittoConfigConnect.fromJson(Map<String, dynamic> json) =>
      switch (json["type"]) {
        "server" => DittoConfigConnectServer.fromJson(json),
        "small_peers_only" => DittoConfigConnectSmallPeersOnly.fromJson(json),
        final other => throw ArgumentError("unknown discriminant: $other"),
      };
}

@external
abstract final class DittoConfigConnectBuilder {
  DittoConfigConnect build();
}

/// Connects this Ditto instance to a Big Peer at the specified URL.
///
/// Important: For sync to work with server connections, Ditto requires both: - an
/// [AuthenticationExpirationHandler] to be set via
/// [Authenticator.expirationHandler] - that handler to properly authenticate when
/// requested. [Sync.start] will throw if the expiration handler is `null`.

@immutable
@external
final class DittoConfigConnectServer extends DittoConfigConnect {
  final String url;

  const DittoConfigConnectServer({required this.url}) : super();

  static DittoConfigConnectServerBuilder builder({required String url}) =>
      DittoConfigConnectServerBuilder(url: url);
  DittoConfigConnectServerBuilder toBuilder() =>
      DittoConfigConnectServerBuilder(url: url);

  @override
  Map<String, dynamic> toJson() => {"url": url, "type": "server"};
  factory DittoConfigConnectServer.fromJson(Map<String, dynamic> json) =>
      DittoConfigConnectServer(url: json["url"] as String);

  @override
  String toString() => "DittoConfigConnectServer("
      "url: $url"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! DittoConfigConnectServer) {
      return false;
    }
    if (url != other.url) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([url.hashCode]);
}

/// Builder class for [DittoConfigConnectServer]

@external
final class DittoConfigConnectServerBuilder extends DittoConfigConnectBuilder {
  String url;

  DittoConfigConnectServerBuilder({required this.url}) : super();

  DittoConfigConnectServer build() => DittoConfigConnectServer(url: url);
}

@immutable
@external
final class DittoConfigConnectSmallPeersOnly extends DittoConfigConnect {
  /// Restricts connectivity to small peers only, optionally using a shared secret
  /// (in the form of a private key) for authentication.
  ///
  /// If a [privateKey] is provided, it will be used as a shared secret for
  /// authenticating peer-to-peer connections. The default value is `null`, which
  /// means no encryption is used in transit.
  final String? privateKey;

  const DittoConfigConnectSmallPeersOnly({this.privateKey}) : super();

  static DittoConfigConnectSmallPeersOnlyBuilder builder({
    String? privateKey,
  }) =>
      DittoConfigConnectSmallPeersOnlyBuilder(
        privateKey: privateKey == null ? null : (privateKey as String),
      );
  DittoConfigConnectSmallPeersOnlyBuilder toBuilder() =>
      DittoConfigConnectSmallPeersOnlyBuilder(
        privateKey: privateKey == null ? null : (privateKey as String),
      );

  @override
  Map<String, dynamic> toJson() => {
        "private_key": privateKey,
        "type": "small_peers_only",
      };
  factory DittoConfigConnectSmallPeersOnly.fromJson(
    Map<String, dynamic> json,
  ) =>
      DittoConfigConnectSmallPeersOnly(
        privateKey: json["private_key"] == null
            ? null
            : json["private_key"] == null
                ? null
                : json["private_key"] as String,
      );

  @override
  String toString() => "DittoConfigConnectSmallPeersOnly("
      "privateKey: $privateKey"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! DittoConfigConnectSmallPeersOnly) {
      return false;
    }
    if (privateKey != other.privateKey) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([privateKey?.hashCode]);
}

/// Builder class for [DittoConfigConnectSmallPeersOnly]

@external
final class DittoConfigConnectSmallPeersOnlyBuilder
    extends DittoConfigConnectBuilder {
  String? privateKey;

  DittoConfigConnectSmallPeersOnlyBuilder({required this.privateKey}) : super();

  DittoConfigConnectSmallPeersOnly build() => DittoConfigConnectSmallPeersOnly(
        privateKey: privateKey == null ? null : (privateKey as String),
      );
}
