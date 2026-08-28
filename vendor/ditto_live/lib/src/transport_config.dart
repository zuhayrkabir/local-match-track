// ignore_for_file: unnecessary_cast

// ignore_for_file: avoid_bool_literals_in_conditional_expressions, ditto_missing_visibility, require_trailing_commas, cast_nullable_to_non_nullable
// WARNING: DO NOT EDIT - generated from `types/transport-config.kdl`
// TODO(dart-typegen): regenerate from types/transport-config.kdl when the generator is available.

import "package:meta/meta.dart";
import "analysis/annotations.dart";

import "ditto.dart";
import "supported_platform.dart";

/// A configuration object specifying which network transports Ditto should use to
/// sync data.
///
/// A Ditto object comes with a default transport configuration where the stable
/// peer-to-peer transports supported on the current platform are enabled. Reliable
/// UDP multicast is excluded from this default and must be enabled explicitly. You
/// can customize the configuration by initializing a [TransportConfig], adjusting
/// its properties, and supplying it to [Ditto.transportConfig], or by calling
/// [Ditto.updateTransportConfig].
///
/// When you initialize a [TransportConfig] yourself it starts with all transports
/// disabled. You must enable each one directly.
///
/// Peer-to-peer transports will automatically discover peers in the vicinity and
/// create connections without any configuration. These are configured inside the
/// [peerToPeer] property. To turn each one on, set its `isEnabled` property to
/// true.
///
/// To connect to a peer at a known location, such as a Ditto Big Peer, add its
/// address inside the connect configuration. These are either "host:port" strings
/// for raw TCP sync, or a "wss://…" URL for WebSockets.
///
/// The listen configurations are for specific less common data sync scenarios.
/// Please read the documentation on the Ditto website for examples. Incorrect use
/// of listen can result in insecure configurations.

@immutable
@external
final class TransportConfig {
  /// Configuration relating to peer-to-peer transports, which create connections automatically.
  final PeerToPeer peerToPeer;

  /// Configuration for connections to specific remote peers.
  final Connect connect;

  /// Configuration for receiving incoming connections.
  final Listen listen;

  /// Settings not associated with any specific type of transport.
  final GlobalConfig global;

  const TransportConfig({
    this.peerToPeer = const PeerToPeer(),
    this.connect = const Connect(),
    this.listen = const Listen(),
    this.global = const GlobalConfig(),
  });

  static TransportConfigBuilder builder({
    PeerToPeer peerToPeer = const PeerToPeer(),
    Connect connect = const Connect(),
    Listen listen = const Listen(),
    GlobalConfig global = const GlobalConfig(),
  }) =>
      TransportConfigBuilder(
        peerToPeer: peerToPeer.toBuilder(),
        connect: connect.toBuilder(),
        listen: listen.toBuilder(),
        global: global.toBuilder(),
      );
  TransportConfigBuilder toBuilder() => TransportConfigBuilder(
        peerToPeer: peerToPeer.toBuilder(),
        connect: connect.toBuilder(),
        listen: listen.toBuilder(),
        global: global.toBuilder(),
      );

  Map<String, dynamic> toJson() => {
        "peer_to_peer": peerToPeer.toJson(),
        "connect": connect.toJson(),
        "listen": listen.toJson(),
        "global": global.toJson(),
      };
  factory TransportConfig.fromJson(Map<String, dynamic> json) =>
      TransportConfig(
        peerToPeer: json["peer_to_peer"] == null
            ? const PeerToPeer()
            : PeerToPeer.fromJson(json["peer_to_peer"] as Map<String, dynamic>),
        connect: json["connect"] == null
            ? const Connect()
            : Connect.fromJson(json["connect"] as Map<String, dynamic>),
        listen: json["listen"] == null
            ? const Listen()
            : Listen.fromJson(json["listen"] as Map<String, dynamic>),
        global: json["global"] == null
            ? const GlobalConfig()
            : GlobalConfig.fromJson(json["global"] as Map<String, dynamic>),
      );

  @override
  String toString() => "TransportConfig("
      "peerToPeer: $peerToPeer, "
      "connect: $connect, "
      "listen: $listen, "
      "global: $global"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TransportConfig) {
      return false;
    }
    if (peerToPeer != other.peerToPeer) {
      return false;
    }
    if (connect != other.connect) {
      return false;
    }
    if (listen != other.listen) {
      return false;
    }
    if (global != other.global) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
        peerToPeer.hashCode,
        connect.hashCode,
        listen.hashCode,
        global.hashCode,
      ]);

  /// Enables/disables stable transports available on the current platform.
  ///
  /// This method does not affect the reliable UDP multicast transport.
  /// Configure [PeerToPeer.multicastBeta] separately.
  // ignore: avoid_positional_boolean_parameters
  TransportConfig withAllPeerToPeerEnabled(bool enabled) {
    final builder = toBuilder()..setAllPeerToPeerEnabled(enabled);
    return builder.build();
  }
}

/// Builder class for [TransportConfig]

@external
final class TransportConfigBuilder {
  PeerToPeerBuilder peerToPeer;
  ConnectBuilder connect;
  ListenBuilder listen;
  GlobalConfigBuilder global;

  TransportConfigBuilder({
    required this.peerToPeer,
    required this.connect,
    required this.listen,
    required this.global,
  });

  TransportConfig build() => TransportConfig(
        peerToPeer: peerToPeer.build(),
        connect: connect.build(),
        listen: listen.build(),
        global: global.build(),
      );

  /// Enables/disables stable transports available on the current platform.
  ///
  /// This method does not affect the reliable UDP multicast transport.
  /// Configure [PeerToPeer.multicastBeta] separately.
  // ignore: avoid_positional_boolean_parameters
  void setAllPeerToPeerEnabled(bool enabled) {
    switch (Ditto.currentPlatform) {
      case SupportedPlatform.web:
        return;
      case SupportedPlatform.android:
        peerToPeer.wifiAware.isEnabled = enabled;
      case SupportedPlatform.ios || SupportedPlatform.macos:
        peerToPeer.awdl.isEnabled = enabled;
      case SupportedPlatform.linux:
      case SupportedPlatform.windows:
    }

    peerToPeer.bluetoothLE.isEnabled = enabled;
    peerToPeer.lan.isEnabled = enabled;
  }
}

/// Configuration of peer-to-peer transports, which are able to discover and
/// connect to peers on their own.
///
/// Part of [TransportConfig].

@immutable
@external
final class PeerToPeer {
  /// P2P Bluetooth LE configuration.
  final BluetoothLEConfig bluetoothLE;

  /// P2P AWDL configuration.
  final AwdlConfig awdl;

  /// P2P Wi-Fi Aware configuration.
  final WifiAwareConfig wifiAware;

  /// P2P LAN configuration.
  final LanConfig lan;

  /// Private beta configuration for reliable UDP multicast transport. See
  /// [MulticastBetaConfig].
  final MulticastBetaConfig multicastBeta;

  const PeerToPeer({
    this.bluetoothLE = const BluetoothLEConfig(),
    this.awdl = const AwdlConfig(),
    this.wifiAware = const WifiAwareConfig(),
    this.lan = const LanConfig(),
    this.multicastBeta = const MulticastBetaConfig(),
  });

  static PeerToPeerBuilder builder({
    BluetoothLEConfig bluetoothLE = const BluetoothLEConfig(),
    AwdlConfig awdl = const AwdlConfig(),
    WifiAwareConfig wifiAware = const WifiAwareConfig(),
    LanConfig lan = const LanConfig(),
    MulticastBetaConfig multicastBeta = const MulticastBetaConfig(),
  }) =>
      PeerToPeerBuilder(
        bluetoothLE: bluetoothLE.toBuilder(),
        awdl: awdl.toBuilder(),
        wifiAware: wifiAware.toBuilder(),
        lan: lan.toBuilder(),
        multicastBeta: multicastBeta.toBuilder(),
      );
  PeerToPeerBuilder toBuilder() => PeerToPeerBuilder(
        bluetoothLE: bluetoothLE.toBuilder(),
        awdl: awdl.toBuilder(),
        wifiAware: wifiAware.toBuilder(),
        lan: lan.toBuilder(),
        multicastBeta: multicastBeta.toBuilder(),
      );

  Map<String, dynamic> toJson() => {
        "bluetooth_le": bluetoothLE.toJson(),
        "awdl": awdl.toJson(),
        "wifi_aware": wifiAware.toJson(),
        "lan": lan.toJson(),
        "multicast": multicastBeta.toJson(),
      };
  factory PeerToPeer.fromJson(Map<String, dynamic> json) => PeerToPeer(
        bluetoothLE: json["bluetooth_le"] == null
            ? const BluetoothLEConfig()
            : BluetoothLEConfig.fromJson(
                json["bluetooth_le"] as Map<String, dynamic>,
              ),
        awdl: json["awdl"] == null
            ? const AwdlConfig()
            : AwdlConfig.fromJson(json["awdl"] as Map<String, dynamic>),
        wifiAware: json["wifi_aware"] == null
            ? const WifiAwareConfig()
            : WifiAwareConfig.fromJson(
                json["wifi_aware"] as Map<String, dynamic>),
        lan: json["lan"] == null
            ? const LanConfig()
            : LanConfig.fromJson(json["lan"] as Map<String, dynamic>),
        multicastBeta: json["multicast"] == null
            ? const MulticastBetaConfig()
            : MulticastBetaConfig.fromJson(
                json["multicast"] as Map<String, dynamic>),
      );

  @override
  String toString() => "PeerToPeer("
      "bluetoothLE: $bluetoothLE, "
      "awdl: $awdl, "
      "wifiAware: $wifiAware, "
      "lan: $lan, "
      "multicastBeta: $multicastBeta"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! PeerToPeer) {
      return false;
    }
    if (bluetoothLE != other.bluetoothLE) {
      return false;
    }
    if (awdl != other.awdl) {
      return false;
    }
    if (wifiAware != other.wifiAware) {
      return false;
    }
    if (lan != other.lan) {
      return false;
    }
    if (multicastBeta != other.multicastBeta) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
        bluetoothLE.hashCode,
        awdl.hashCode,
        wifiAware.hashCode,
        lan.hashCode,
        multicastBeta.hashCode,
      ]);
}

/// Builder class for [PeerToPeer]

@external
final class PeerToPeerBuilder {
  BluetoothLEConfigBuilder bluetoothLE;
  AwdlConfigBuilder awdl;
  WifiAwareConfigBuilder wifiAware;
  LanConfigBuilder lan;
  MulticastBetaConfigBuilder multicastBeta;

  PeerToPeerBuilder({
    required this.bluetoothLE,
    required this.awdl,
    required this.wifiAware,
    required this.lan,
    required this.multicastBeta,
  });

  PeerToPeer build() => PeerToPeer(
        bluetoothLE: bluetoothLE.build(),
        awdl: awdl.build(),
        wifiAware: wifiAware.build(),
        lan: lan.build(),
        multicastBeta: multicastBeta.build(),
      );
}

/// P2P BluetoothLE configuration. Part of [PeerToPeer].

@immutable
@external
final class BluetoothLEConfig {
  /// Indicates whether P2P Bluetooth LE transport is enabled or not.
  final bool isEnabled;

  const BluetoothLEConfig({this.isEnabled = false});

  static BluetoothLEConfigBuilder builder({bool isEnabled = false}) =>
      BluetoothLEConfigBuilder(isEnabled: isEnabled);
  BluetoothLEConfigBuilder toBuilder() =>
      BluetoothLEConfigBuilder(isEnabled: isEnabled);

  Map<String, dynamic> toJson() => {"enabled": isEnabled};
  factory BluetoothLEConfig.fromJson(Map<String, dynamic> json) =>
      BluetoothLEConfig(
        isEnabled: json["enabled"] == null ? false : json["enabled"] as bool,
      );

  @override
  String toString() => "BluetoothLEConfig("
      "isEnabled: $isEnabled"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! BluetoothLEConfig) {
      return false;
    }
    if (isEnabled != other.isEnabled) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([isEnabled.hashCode]);
}

/// Builder class for [BluetoothLEConfig]

@external
final class BluetoothLEConfigBuilder {
  bool isEnabled;

  BluetoothLEConfigBuilder({required this.isEnabled});

  BluetoothLEConfig build() => BluetoothLEConfig(isEnabled: isEnabled);
}

/// P2P AWDL configuration. Part of [PeerToPeer].

@immutable
@external
final class AwdlConfig {
  final bool isEnabled;

  const AwdlConfig({this.isEnabled = false});

  static AwdlConfigBuilder builder({bool isEnabled = false}) =>
      AwdlConfigBuilder(isEnabled: isEnabled);
  AwdlConfigBuilder toBuilder() => AwdlConfigBuilder(isEnabled: isEnabled);

  Map<String, dynamic> toJson() => {"enabled": isEnabled};
  factory AwdlConfig.fromJson(Map<String, dynamic> json) => AwdlConfig(
        isEnabled: json["enabled"] == null ? false : json["enabled"] as bool,
      );

  @override
  String toString() => "AwdlConfig("
      "isEnabled: $isEnabled"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! AwdlConfig) {
      return false;
    }
    if (isEnabled != other.isEnabled) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([isEnabled.hashCode]);
}

/// Builder class for [AwdlConfig]

@external
final class AwdlConfigBuilder {
  bool isEnabled;

  AwdlConfigBuilder({required this.isEnabled});

  AwdlConfig build() => AwdlConfig(isEnabled: isEnabled);
}

/// P2P Wi-Fi Aware configuration. Part of [PeerToPeer].

@immutable
@external
final class WifiAwareConfig {
  final bool isEnabled;

  const WifiAwareConfig({this.isEnabled = false});

  static WifiAwareConfigBuilder builder({bool isEnabled = false}) =>
      WifiAwareConfigBuilder(isEnabled: isEnabled);
  WifiAwareConfigBuilder toBuilder() =>
      WifiAwareConfigBuilder(isEnabled: isEnabled);

  Map<String, dynamic> toJson() => {"enabled": isEnabled};
  factory WifiAwareConfig.fromJson(Map<String, dynamic> json) =>
      WifiAwareConfig(
        isEnabled: json["enabled"] == null ? false : json["enabled"] as bool,
      );

  @override
  String toString() => "WifiAwareConfig("
      "isEnabled: $isEnabled"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! WifiAwareConfig) {
      return false;
    }
    if (isEnabled != other.isEnabled) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([isEnabled.hashCode]);
}

/// Builder class for [WifiAwareConfig]

@external
final class WifiAwareConfigBuilder {
  bool isEnabled;

  WifiAwareConfigBuilder({required this.isEnabled});

  WifiAwareConfig build() => WifiAwareConfig(isEnabled: isEnabled);
}

/// P2P LAN configuration to configure peer discovery via mDNS or multicast. Part of [PeerToPeer].

@immutable
@external
final class LanConfig {
  /// Indicates whether P2P LAN transport is enabled or not.
  final bool isEnabled;

  /// Indicates whether mDNS is enabled or not.
  final bool isMdnsEnabled;

  const LanConfig({this.isEnabled = false, this.isMdnsEnabled = true});

  static LanConfigBuilder builder({
    bool isEnabled = false,
    bool isMdnsEnabled = true,
  }) =>
      LanConfigBuilder(isEnabled: isEnabled, isMdnsEnabled: isMdnsEnabled);
  LanConfigBuilder toBuilder() =>
      LanConfigBuilder(isEnabled: isEnabled, isMdnsEnabled: isMdnsEnabled);

  Map<String, dynamic> toJson() => {
        "enabled": isEnabled,
        "mdns_enabled": isMdnsEnabled,
      };
  factory LanConfig.fromJson(Map<String, dynamic> json) => LanConfig(
        isEnabled: json["enabled"] == null ? false : json["enabled"] as bool,
        isMdnsEnabled:
            json["mdns_enabled"] == null ? true : json["mdns_enabled"] as bool,
      );

  @override
  String toString() => "LanConfig("
      "isEnabled: $isEnabled, "
      "isMdnsEnabled: $isMdnsEnabled"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! LanConfig) {
      return false;
    }
    if (isEnabled != other.isEnabled) {
      return false;
    }
    if (isMdnsEnabled != other.isMdnsEnabled) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([isEnabled.hashCode, isMdnsEnabled.hashCode]);
}

/// Builder class for [LanConfig]

@external
final class LanConfigBuilder {
  bool isEnabled;
  bool isMdnsEnabled;

  LanConfigBuilder({required this.isEnabled, required this.isMdnsEnabled});

  LanConfig build() =>
      LanConfig(isEnabled: isEnabled, isMdnsEnabled: isMdnsEnabled);
}

/// Configuration for reliable UDP multicast transport.
///
/// Use this configuration to enable peer-to-peer data synchronization over a
/// multicast group.
///
/// Reliable UDP multicast is supported on Android, iOS, Linux, and macOS. It
/// is not supported on Web or Windows.
///
/// This does not configure multicast-based LAN discovery. Use [LanConfig] for
/// that setting.
///
/// On iOS, the host app must include `NSLocalNetworkUsageDescription`, have Local
/// Network access, and be signed with the
/// `com.apple.developer.networking.multicast` entitlement. When sync starts,
/// Ditto validates the Info.plist entry. In Simulator, it also validates the
/// entitlement; the entitlement cannot be validated on physical iOS devices.
///
/// On Android, the host app must declare
/// `android.permission.CHANGE_WIFI_MULTICAST_STATE`. The SDK acquires and
/// releases a `WifiManager.MulticastLock` while this transport is enabled.
/// On Android 17 (API 37) or newer, apps targeting API 37 or newer must also
/// declare and obtain `android.permission.ACCESS_LOCAL_NETWORK`. `Ditto.sync.start()`
/// throws if a required permission is missing or the multicast lock cannot be
/// acquired.
///
/// On iOS and Android, configure this transport while sync is stopped. Changes
/// requested while sync is active take effect after `Ditto.sync.stop()` and the
/// next successful `Ditto.sync.start()`, when Ditto validates these prerequisites.
///
/// This feature is in private beta and should only be used in coordination with
/// Ditto support.

@immutable
@external
final class MulticastBetaConfig {
  /// Whether reliable UDP multicast transport is enabled. This private beta
  /// feature should only be enabled in coordination with Ditto support.
  final bool isEnabled;
  final String groupAddress;
  final int port;
  final String? interfaceName;

  const MulticastBetaConfig({
    this.isEnabled = false,
    this.groupAddress = "224.1.2.3",
    this.port = 6003,
    this.interfaceName,
  });

  static MulticastBetaConfigBuilder builder({
    bool isEnabled = false,
    String groupAddress = "224.1.2.3",
    int port = 6003,
    String? interfaceName,
  }) =>
      MulticastBetaConfigBuilder(
        isEnabled: isEnabled,
        groupAddress: groupAddress,
        port: port,
        interfaceName: interfaceName == null ? null : (interfaceName as String),
      );
  MulticastBetaConfigBuilder toBuilder() => MulticastBetaConfigBuilder(
        isEnabled: isEnabled,
        groupAddress: groupAddress,
        port: port,
        interfaceName: interfaceName == null ? null : (interfaceName as String),
      );

  Map<String, dynamic> toJson() => {
        "enabled": isEnabled,
        "group_address": groupAddress,
        "port": port,
        "interface": interfaceName,
      };
  factory MulticastBetaConfig.fromJson(Map<String, dynamic> json) =>
      MulticastBetaConfig(
        isEnabled: json["enabled"] == null ? false : json["enabled"] as bool,
        groupAddress: json["group_address"] == null
            ? "224.1.2.3"
            : json["group_address"] as String,
        port: json["port"] == null ? 6003 : json["port"] as int,
        interfaceName: json["interface"] == null
            ? null
            : json["interface"] == null
                ? null
                : json["interface"] as String,
      );

  @override
  String toString() => "MulticastBetaConfig("
      "isEnabled: $isEnabled, "
      "groupAddress: $groupAddress, "
      "port: $port, "
      "interfaceName: $interfaceName"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! MulticastBetaConfig) {
      return false;
    }
    if (isEnabled != other.isEnabled) {
      return false;
    }
    if (groupAddress != other.groupAddress) {
      return false;
    }
    if (port != other.port) {
      return false;
    }
    if (interfaceName != other.interfaceName) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
        isEnabled.hashCode,
        groupAddress.hashCode,
        port.hashCode,
        interfaceName?.hashCode,
      ]);
}

/// Builder class for [MulticastBetaConfig]

@external
final class MulticastBetaConfigBuilder {
  /// Whether reliable UDP multicast transport is enabled. This private beta
  /// feature should only be enabled in coordination with Ditto support.
  bool isEnabled;
  String groupAddress;
  int port;
  String? interfaceName;

  MulticastBetaConfigBuilder({
    required this.isEnabled,
    required this.groupAddress,
    required this.port,
    required this.interfaceName,
  });

  MulticastBetaConfig build() => MulticastBetaConfig(
        isEnabled: isEnabled,
        groupAddress: groupAddress,
        port: port,
        interfaceName: interfaceName == null ? null : (interfaceName as String),
      );
}

@immutable
@external
final class Connect {
  /// A set of TCP servers specified as strings of the form `"host:port"`.
  final Set<String> tcpServers;

  /// A set of WebSocket URLs specified as strings of the form `wss://some.example.com`.
  final Set<String> webSocketUrls;

  /// The amount of time to wait until trying to reconnect if a connection fails.
  final Duration retryInterval;

  const Connect({
    this.tcpServers = const {},
    this.webSocketUrls = const {},
    this.retryInterval = const Duration(seconds: 5),
  });

  static ConnectBuilder builder({
    Set<String> tcpServers = const {},
    Set<String> webSocketUrls = const {},
    Duration retryInterval = const Duration(seconds: 5),
  }) =>
      ConnectBuilder(
        tcpServers: tcpServers.map((elem) => elem).toSet(),
        webSocketUrls: webSocketUrls.map((elem) => elem).toSet(),
        retryInterval: retryInterval,
      );
  ConnectBuilder toBuilder() => ConnectBuilder(
        tcpServers: tcpServers.map((elem) => elem).toSet(),
        webSocketUrls: webSocketUrls.map((elem) => elem).toSet(),
        retryInterval: retryInterval,
      );

  Map<String, dynamic> toJson() => {
        "tcp_servers": tcpServers.map((inner) => inner).toList(),
        "websocket_urls": webSocketUrls.map((inner) => inner).toList(),
        "retry_interval":
            // ignore: unnecessary_parenthesis
            (_durationToJson)(retryInterval),
      };
  factory Connect.fromJson(Map<String, dynamic> json) => Connect(
        tcpServers: json["tcp_servers"] == null
            ? const {}
            : (json["tcp_servers"] as List<dynamic>)
                .map<String>((inner) => inner as String)
                .toSet(),
        webSocketUrls: json["websocket_urls"] == null
            ? const {}
            : (json["websocket_urls"] as List<dynamic>)
                .map<String>((inner) => inner as String)
                .toSet(),
        retryInterval: json["retry_interval"] == null
            ? const Duration(seconds: 5)
            :
            // ignore: unnecessary_parenthesis
            (_durationFromJson)(json["retry_interval"]),
      );

  @override
  String toString() => "Connect("
      "tcpServers: $tcpServers, "
      "webSocketUrls: $webSocketUrls, "
      "retryInterval: $retryInterval"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Connect) {
      return false;
    }
    if (tcpServers.length != other.tcpServers.length) {
      return false;
    }
    for (final elem in tcpServers) {
      if (!other.tcpServers.contains(elem)) {
        return false;
      }
    }
    if (webSocketUrls.length != other.webSocketUrls.length) {
      return false;
    }
    for (final elem in webSocketUrls) {
      if (!other.webSocketUrls.contains(elem)) {
        return false;
      }
    }
    if (retryInterval != other.retryInterval) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
        Object.hashAll(tcpServers.map((elem) => elem.hashCode)),
        Object.hashAll(webSocketUrls.map((elem) => elem.hashCode)),
        retryInterval.hashCode,
      ]);
}

/// Builder class for [Connect]

@external
final class ConnectBuilder {
  Set<String> tcpServers;
  Set<String> webSocketUrls;
  Duration retryInterval;

  ConnectBuilder({
    required this.tcpServers,
    required this.webSocketUrls,
    required this.retryInterval,
  });

  Connect build() => Connect(
        tcpServers: tcpServers.map((elem) => elem).toSet(),
        webSocketUrls: webSocketUrls.map((elem) => elem).toSet(),
        retryInterval: retryInterval,
      );
}

/// Configure this device as a Ditto server. Disabled by default.
///
/// This is advanced usage that is not needed in most situations. Please refer to
/// the documentation on Ditto’s website for scenarios and example configurations.
///
/// Part of [TransportConfig].

@immutable
@external
final class Listen {
  /// TCP listening configuration.
  final TcpListenConfig tcp;

  /// HTTP listening configuration.
  final HttpListenConfig http;

  const Listen({
    this.tcp = const TcpListenConfig(),
    this.http = const HttpListenConfig(),
  });

  static ListenBuilder builder({
    TcpListenConfig tcp = const TcpListenConfig(),
    HttpListenConfig http = const HttpListenConfig(),
  }) =>
      ListenBuilder(tcp: tcp.toBuilder(), http: http.toBuilder());
  ListenBuilder toBuilder() =>
      ListenBuilder(tcp: tcp.toBuilder(), http: http.toBuilder());

  Map<String, dynamic> toJson() => {"tcp": tcp.toJson(), "http": http.toJson()};
  factory Listen.fromJson(Map<String, dynamic> json) => Listen(
        tcp: json["tcp"] == null
            ? const TcpListenConfig()
            : TcpListenConfig.fromJson(json["tcp"] as Map<String, dynamic>),
        http: json["http"] == null
            ? const HttpListenConfig()
            : HttpListenConfig.fromJson(json["http"] as Map<String, dynamic>),
      );

  @override
  String toString() => "Listen("
      "tcp: $tcp, "
      "http: $http"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! Listen) {
      return false;
    }
    if (tcp != other.tcp) {
      return false;
    }
    if (http != other.http) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([tcp.hashCode, http.hashCode]);
}

/// Builder class for [Listen]

@external
final class ListenBuilder {
  TcpListenConfigBuilder tcp;
  HttpListenConfigBuilder http;

  ListenBuilder({required this.tcp, required this.http});

  Listen build() => Listen(tcp: tcp.build(), http: http.build());
}

/// TCP listening configuration. Part of [Listen].

@immutable
@external
final class TcpListenConfig {
  /// Indicates whether TCP listening is enabled.
  final bool isEnabled;

  /// IP interface to bind to.
  final String interfaceIP;

  /// Listening port.
  final int port;

  const TcpListenConfig({
    this.isEnabled = false,
    this.interfaceIP = "[::]",
    this.port = 4040,
  });

  static TcpListenConfigBuilder builder({
    bool isEnabled = false,
    String interfaceIP = "[::]",
    int port = 4040,
  }) =>
      TcpListenConfigBuilder(
        isEnabled: isEnabled,
        interfaceIP: interfaceIP,
        port: port,
      );
  TcpListenConfigBuilder toBuilder() => TcpListenConfigBuilder(
        isEnabled: isEnabled,
        interfaceIP: interfaceIP,
        port: port,
      );

  Map<String, dynamic> toJson() => {
        "enabled": isEnabled,
        "interface_ip": interfaceIP,
        "port": port,
      };
  factory TcpListenConfig.fromJson(Map<String, dynamic> json) =>
      TcpListenConfig(
        isEnabled: json["enabled"] == null ? false : json["enabled"] as bool,
        interfaceIP: json["interface_ip"] == null
            ? "[::]"
            : json["interface_ip"] as String,
        port: json["port"] == null ? 4040 : json["port"] as int,
      );

  @override
  String toString() => "TcpListenConfig("
      "isEnabled: $isEnabled, "
      "interfaceIP: $interfaceIP, "
      "port: $port"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! TcpListenConfig) {
      return false;
    }
    if (isEnabled != other.isEnabled) {
      return false;
    }
    if (interfaceIP != other.interfaceIP) {
      return false;
    }
    if (port != other.port) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([isEnabled.hashCode, interfaceIP.hashCode, port.hashCode]);
}

/// Builder class for [TcpListenConfig]

@external
final class TcpListenConfigBuilder {
  bool isEnabled;
  String interfaceIP;
  int port;

  TcpListenConfigBuilder({
    required this.isEnabled,
    required this.interfaceIP,
    required this.port,
  });

  TcpListenConfig build() => TcpListenConfig(
        isEnabled: isEnabled,
        interfaceIP: interfaceIP,
        port: port,
      );
}

/// HTTP & WebSocket listening configuration. Part of [Listen].

@immutable
@external
final class HttpListenConfig {
  /// Indicates whether HTTP listening is enabled.
  final bool isEnabled;

  /// IP interface to bind to.
  final String interfaceIP;

  /// Listening port.
  final int port;

  /// If `true`, peers can connect over WebSocket to sync with this peer. Disabled by
  /// default.
  ///
  /// This feature has security implications and should only be used together with
  /// documentation on Ditto's website.
  final bool websocketSync;

  /// An absolute path to the PEM-formatted private key for HTTPS. Must be set
  /// together with [tlsCertificatePath].
  ///
  /// If `null`, the server runs as unencrypted HTTP.
  final String? tlsKeyPath;

  /// An absolute path to the PEM-formatted certificate for HTTPS. Must be set
  /// together with [tlsKeyPath].
  ///
  /// If `null`, the server runs as unencrypted HTTP.
  final String? tlsCertificatePath;

  const HttpListenConfig({
    this.isEnabled = false,
    this.interfaceIP = "[::]",
    this.port = 80,
    this.websocketSync = false,
    this.tlsKeyPath,
    this.tlsCertificatePath,
  });

  static HttpListenConfigBuilder builder({
    bool isEnabled = false,
    String interfaceIP = "[::]",
    int port = 80,
    bool websocketSync = false,
    String? tlsKeyPath,
    String? tlsCertificatePath,
  }) =>
      HttpListenConfigBuilder(
        isEnabled: isEnabled,
        interfaceIP: interfaceIP,
        port: port,
        websocketSync: websocketSync,
        tlsKeyPath: tlsKeyPath == null ? null : (tlsKeyPath as String),
        tlsCertificatePath:
            tlsCertificatePath == null ? null : (tlsCertificatePath as String),
      );
  HttpListenConfigBuilder toBuilder() => HttpListenConfigBuilder(
        isEnabled: isEnabled,
        interfaceIP: interfaceIP,
        port: port,
        websocketSync: websocketSync,
        tlsKeyPath: tlsKeyPath == null ? null : (tlsKeyPath as String),
        tlsCertificatePath:
            tlsCertificatePath == null ? null : (tlsCertificatePath as String),
      );

  Map<String, dynamic> toJson() => {
        "enabled": isEnabled,
        "interface_ip": interfaceIP,
        "port": port,
        "websocket_sync": websocketSync,
        "tls_key_path": tlsKeyPath,
        "tls_certificate_path": tlsCertificatePath,
      };
  factory HttpListenConfig.fromJson(Map<String, dynamic> json) =>
      HttpListenConfig(
        isEnabled: json["enabled"] == null ? false : json["enabled"] as bool,
        interfaceIP: json["interface_ip"] == null
            ? "[::]"
            : json["interface_ip"] as String,
        port: json["port"] == null ? 80 : json["port"] as int,
        websocketSync: json["websocket_sync"] == null
            ? false
            : json["websocket_sync"] as bool,
        tlsKeyPath: json["tls_key_path"] == null
            ? null
            : json["tls_key_path"] == null
                ? null
                : json["tls_key_path"] as String,
        tlsCertificatePath: json["tls_certificate_path"] == null
            ? null
            : json["tls_certificate_path"] == null
                ? null
                : json["tls_certificate_path"] as String,
      );

  @override
  String toString() => "HttpListenConfig("
      "isEnabled: $isEnabled, "
      "interfaceIP: $interfaceIP, "
      "port: $port, "
      "websocketSync: $websocketSync, "
      "tlsKeyPath: $tlsKeyPath, "
      "tlsCertificatePath: $tlsCertificatePath"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! HttpListenConfig) {
      return false;
    }
    if (isEnabled != other.isEnabled) {
      return false;
    }
    if (interfaceIP != other.interfaceIP) {
      return false;
    }
    if (port != other.port) {
      return false;
    }
    if (websocketSync != other.websocketSync) {
      return false;
    }
    if (tlsKeyPath != other.tlsKeyPath) {
      return false;
    }
    if (tlsCertificatePath != other.tlsCertificatePath) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([
        isEnabled.hashCode,
        interfaceIP.hashCode,
        port.hashCode,
        websocketSync.hashCode,
        tlsKeyPath?.hashCode,
        tlsCertificatePath?.hashCode,
      ]);
}

/// Builder class for [HttpListenConfig]

@external
final class HttpListenConfigBuilder {
  bool isEnabled;
  String interfaceIP;
  int port;
  bool websocketSync;
  String? tlsKeyPath;
  String? tlsCertificatePath;

  HttpListenConfigBuilder({
    required this.isEnabled,
    required this.interfaceIP,
    required this.port,
    required this.websocketSync,
    required this.tlsKeyPath,
    required this.tlsCertificatePath,
  });

  HttpListenConfig build() => HttpListenConfig(
        isEnabled: isEnabled,
        interfaceIP: interfaceIP,
        port: port,
        websocketSync: websocketSync,
        tlsKeyPath: tlsKeyPath == null ? null : (tlsKeyPath as String),
        tlsCertificatePath:
            tlsCertificatePath == null ? null : (tlsCertificatePath as String),
      );
}

/// Settings not associated with any specific type of transport. Part of
/// [TransportConfig].

@immutable
@external
final class GlobalConfig {
  /// The sync group for this device.
  ///
  /// When peer-to-peer transports are enabled, all devices with the same App ID will
  /// normally form an interconnected mesh network. In some situations it may be
  /// desirable to have distinct groups of devices within the same app, so that
  /// connections will only be formed within each group. The [syncGroup] parameter
  /// changes that group membership. A device can only ever be in one sync group,
  /// which by default is group 0. Up to 2^32 distinct group numbers can be used in
  /// an app.
  ///
  /// This is an optimization, not a security control. If a connection is created
  /// manually, such as by specifying a [Connect] transport, then devices from
  /// different sync groups will still sync as normal. If two groups of devices are
  /// intended to have access to different data sets, this must be enforced using
  /// Ditto's permissions system.
  final int syncGroup;

  /// The routing hint for this device.
  ///
  /// A routing hint is a performance tuning option which can improve the performance of
  /// applications that use large collections. Ditto will make a best effort to co-locate data for
  /// the same routing key. In most circumstances, this should substantially improve responsiveness
  /// of the Ditto Cloud.
  ///
  /// The value of the routing hint is application specific - you are free to chose any value.
  /// Devices which you expect to operate on much the same data should be configured to
  /// use the same value.
  ///
  /// A routing hint does not partition data. The value of the routing hint will not affect the data
  /// returned for a query. The routing hint only improves the efficiency of the Cloud's
  /// ability to satisfy the query.
  final int routingHint;

  const GlobalConfig({this.syncGroup = 0, this.routingHint = 0});

  static GlobalConfigBuilder builder({
    int syncGroup = 0,
    int routingHint = 0,
  }) =>
      GlobalConfigBuilder(syncGroup: syncGroup, routingHint: routingHint);
  GlobalConfigBuilder toBuilder() =>
      GlobalConfigBuilder(syncGroup: syncGroup, routingHint: routingHint);

  Map<String, dynamic> toJson() => {
        "sync_group": syncGroup,
        "routing_hint": routingHint,
      };
  factory GlobalConfig.fromJson(Map<String, dynamic> json) => GlobalConfig(
        syncGroup: json["sync_group"] == null ? 0 : json["sync_group"] as int,
        routingHint:
            json["routing_hint"] == null ? 0 : json["routing_hint"] as int,
      );

  @override
  String toString() => "GlobalConfig("
      "syncGroup: $syncGroup, "
      "routingHint: $routingHint"
      ")";
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! GlobalConfig) {
      return false;
    }
    if (syncGroup != other.syncGroup) {
      return false;
    }
    if (routingHint != other.routingHint) {
      return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hashAll([syncGroup.hashCode, routingHint.hashCode]);
}

/// Builder class for [GlobalConfig]

@external
final class GlobalConfigBuilder {
  int syncGroup;
  int routingHint;

  GlobalConfigBuilder({required this.syncGroup, required this.routingHint});

  GlobalConfig build() =>
      GlobalConfig(syncGroup: syncGroup, routingHint: routingHint);
}

Duration _durationFromJson(dynamic json) =>
    Duration(milliseconds: (json as num).toInt());
dynamic _durationToJson(Duration duration) => duration.inMilliseconds;
