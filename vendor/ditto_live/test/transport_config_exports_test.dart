import "package:ditto_live/ditto_live.dart"
    show
        MulticastBetaConfig,
        MulticastBetaConfigBuilder,
        PeerToPeer,
        TransportConfig;
import "package:flutter_test/flutter_test.dart";

void main() {
  test("exports the multicast beta configuration API", () {
    final builder = MulticastBetaConfig.builder();

    expect(builder, isA<MulticastBetaConfigBuilder>());
    expect(builder.build(), const MulticastBetaConfig());
  });

  test("bulk peer-to-peer helpers do not affect multicast", () {
    for (final multicastEnabled in [false, true]) {
      final config = TransportConfig(
        peerToPeer: PeerToPeer(
          multicastBeta: MulticastBetaConfig(isEnabled: multicastEnabled),
        ),
      );

      final updated = config.withAllPeerToPeerEnabled(!multicastEnabled);
      expect(
        updated.peerToPeer.multicastBeta.isEnabled,
        multicastEnabled,
      );

      final builder = config.toBuilder()
        ..setAllPeerToPeerEnabled(!multicastEnabled);
      expect(
        builder.build().peerToPeer.multicastBeta.isEnabled,
        multicastEnabled,
      );
    }
  });
}
