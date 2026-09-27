import 'dart:async';

import 'package:ditto_live/ditto_live.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class DittoManager {
  static const databaseId = String.fromEnvironment(
    'DITTO_DATABASE_ID',
    defaultValue: '11111111-1111-4111-8111-111111111111',
  );

  static const serverUrl = String.fromEnvironment('DITTO_SERVER_URL');
  static const playgroundToken = String.fromEnvironment(
    'DITTO_PLAYGROUND_TOKEN',
  );
  static const offlineLicenseToken = String.fromEnvironment(
    'DITTO_OFFLINE_LICENSE_TOKEN',
  );

  Ditto? _ditto;
  SyncSubscription? _matchesSubscription;
  SyncSubscription? _matchEventsSubscription;
  SyncSubscription? _matchReviewProposalsSubscription;
  SyncSubscription? _matchParticipantsSubscription;
  PresenceObserver? _presenceObserver;
  bool _dataAccessReady = false;

  Ditto get ditto {
    final value = _ditto;
    if (value == null) {
      throw StateError('Ditto has not been opened yet.');
    }
    return value;
  }

  bool get isServerMode => serverUrl.isNotEmpty;

  bool get dataAccessReady => _dataAccessReady;

  String get modeLabel {
    return isServerMode
        ? 'Ditto Server / Playground mode'
        : 'Small Peers Only mode';
  }

  String get activationMessage {
    if (dataAccessReady) {
      return 'Ditto is activated, subscribed to matches, match_events, review proposals, and participants, and syncing.';
    }
    if (isServerMode && playgroundToken.isEmpty) {
      return 'DITTO_SERVER_URL was provided, but DITTO_PLAYGROUND_TOKEN is missing.';
    }
    return 'Small Peers Only mode needs DITTO_OFFLINE_LICENSE_TOKEN before Ditto can run store queries or sync.';
  }

  Future<void> open() async {
    if (_ditto != null) return;

    await _requestAndroidMeshPermissions();
    await Ditto.init();

    final config = DittoConfig(
      databaseID: databaseId,
      connect: isServerMode
          ? const DittoConfigConnectServer(url: serverUrl)
          : const DittoConfigConnectSmallPeersOnly(),
    );

    final openedDitto = await Ditto.open(config);
    openedDitto.deviceName = 'Soccer Tracker';
    _ditto = openedDitto;

    if (isServerMode) {
      if (playgroundToken.isEmpty) {
        return;
      }
      await openedDitto.auth.setExpirationHandler((ditto, _) async {
        final response = await ditto.auth.login(
          token: playgroundToken,
          provider: Authenticator.developmentProvider,
        );
        if (response.exception != null) {
          throw response.exception!;
        }
      });
    } else if (offlineLicenseToken.isNotEmpty) {
      openedDitto.setOfflineOnlyLicenseToken(offlineLicenseToken);
    } else {
      return;
    }

    await openedDitto.store.execute('ALTER SYSTEM SET DQL_STRICT_MODE = false');

    _matchesSubscription = openedDitto.sync.registerSubscription(
      'SELECT * FROM matches',
    );
    _matchEventsSubscription = openedDitto.sync.registerSubscription(
      'SELECT * FROM match_events',
    );
    _matchReviewProposalsSubscription = openedDitto.sync.registerSubscription(
      'SELECT * FROM match_review_proposals',
    );
    _matchParticipantsSubscription = openedDitto.sync.registerSubscription(
      'SELECT * FROM match_participants',
    );

    openedDitto.sync.start();
    _dataAccessReady = true;
  }

  Stream<DittoPresenceSummary> watchPresence() {
    final controller = StreamController<DittoPresenceSummary>();

    void emit(PresenceGraph graph) {
      controller.add(
        DittoPresenceSummary(
          localPeerName: graph.localPeer.deviceName,
          remotePeerCount: graph.remotePeers.length,
          connectedToDittoServer: graph.localPeer.isConnectedToDittoServer,
        ),
      );
    }

    _presenceObserver = ditto.presence.observe(emit);
    emit(ditto.presence.graph);

    controller.onCancel = () {
      _presenceObserver?.stop();
      _presenceObserver = null;
    };

    return controller.stream;
  }

  Future<void> close() async {
    _presenceObserver?.stop();
    _presenceObserver = null;
    _matchesSubscription?.cancel();
    _matchesSubscription = null;
    _matchEventsSubscription?.cancel();
    _matchEventsSubscription = null;
    _matchReviewProposalsSubscription?.cancel();
    _matchReviewProposalsSubscription = null;
    _matchParticipantsSubscription?.cancel();
    _matchParticipantsSubscription = null;

    final value = _ditto;
    _ditto = null;
    _dataAccessReady = false;
    await value?.close();
  }

  Future<void> _requestAndroidMeshPermissions() async {
    if (kIsWeb || Ditto.currentPlatform != SupportedPlatform.android) {
      return;
    }

    await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
      Permission.locationWhenInUse,
    ].request();
  }
}

class DittoPresenceSummary {
  const DittoPresenceSummary({
    required this.localPeerName,
    required this.remotePeerCount,
    required this.connectedToDittoServer,
  });

  final String localPeerName;
  final int remotePeerCount;
  final bool connectedToDittoServer;
}
