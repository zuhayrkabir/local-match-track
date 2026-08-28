/// The Flutter SDK for Ditto
///
/// ## Subclassing and SemVer
///
/// This package respects SemVer.
///
/// However, we reserve the right to add methods/fields/etc. to classes
/// *in a minor version release*. In other words, adding a new API to a class
/// *does not constitute a breaking change*.
library;

// WARNING: this file should not export anything with "private" in the name
//
// Note: most of the following comment is checked automatically by our linter.
// I've left it here because the reasoning is still relevant. We just don't have
// to do so much manual checking now.
//
// Every export should be of the format:
// ```dart
// export 'some/file.dart' show Foo, Bar;
// ```
// Rather than just a plain `export`.
//
// The reason for this is that we extensively use *public* identifiers prefixed with `private`
// to simulate package-private functionality (`pub(crate)` in Rust terms).
//
// `export 'foo.dart';` will export ALL public items in that file (i.e. anything that doesn't start with _),
// but this could accidentally include `Private...`.
//
// By forcing us to explicitly choose what to export, we are free to add `Private...` items throughout the
// codebase without worrying about accidentally exposing implementation details

export "src/ditto.dart" show Ditto;
export "src/ditto_config.dart"
    show
        DittoConfig,
        DittoConfigBuilder,
        DittoConfigConnect,
        DittoConfigConnectBuilder,
        DittoConfigConnectServer,
        DittoConfigConnectServerBuilder,
        DittoConfigExperimental,
        DittoConfigExperimentalBuilder,
        DittoConfigConnectSmallPeersOnly,
        DittoConfigConnectSmallPeersOnlyBuilder;
export "src/small_peer_info.dart" show SmallPeerInfo;
export "src/store/store.dart" show Store, StoreObserver, StoreObserverV2;
export "src/store/execute.dart" show QueryResult, QueryResultItem;
export "src/store/transaction.dart"
    show TransactionCompletionAction, TransactionInfo, Transaction;
export "src/sync.dart" show Sync, SyncSubscription;
export "src/differ.dart" show Differ, Diff, DiffMove;
export "src/presence/presence.dart"
    show
        PresenceObserver,
        Presence,
        ConnectionRequest,
        ConnectionRequestHandler,
        ConnectionRequestAuthorization;
export "src/auth.dart"
    show Authenticator, AuthenticationStatus, AuthenticationExpirationHandler;
export "src/attachment.dart" show Attachment;
export "src/attachment_fetcher.dart"
    show
        AttachmentFetcher,
        AttachmentFetchEvent,
        AttachmentFetchEventDeleted,
        AttachmentFetchEventProgress,
        AttachmentFetchEventCompleted,
        AttachmentFetchEventType;
export "src/exception.dart"
    show DittoError, DittoException, DittoClosedException;
export "src/transport_conditions.dart"
    show
        TransportCondition,
        TransportConditionSource,
        TransportConditionEvent,
        TransportConditionsObserver;
export "src/transport_config.dart"
    show
        TransportConfigBuilder,
        PeerToPeerBuilder,
        ListenBuilder,
        ConnectBuilder,
        LanConfigBuilder,
        AwdlConfigBuilder,
        GlobalConfigBuilder,
        TcpListenConfigBuilder,
        HttpListenConfigBuilder,
        BluetoothLEConfigBuilder,
        WifiAwareConfigBuilder,
        MulticastBetaConfigBuilder,
        TransportConfig,
        PeerToPeer,
        Listen,
        Connect,
        LanConfig,
        AwdlConfig,
        GlobalConfig,
        TcpListenConfig,
        HttpListenConfig,
        BluetoothLEConfig,
        WifiAwareConfig,
        MulticastBetaConfig;

export "src/presence/presence_graph.dart"
    show
        PresenceGraph,
        Peer,
        ConnectionType,
        Connection,
        PresenceGraphBuilder,
        PeerBuilder,
        ConnectionBuilder;
export "src/shared/attachment_token.dart" show AttachmentToken;
export "src/shared/attachment_metadata.dart" show AttachmentMetadata;
export "src/supported_platform.dart" show SupportedPlatform;

export "src/logger.dart" show DittoLogger;

export "src/bridge/bridge.dart" show LogLevel, AuthResponse;

export "src/sync_permissions.dart" show DittoSyncPermissions;
