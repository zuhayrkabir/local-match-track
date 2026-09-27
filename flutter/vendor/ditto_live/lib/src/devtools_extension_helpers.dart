// ignore_for_file: only_throw_errors

import "dart:convert";
import "dart:developer";

import "package:meta/meta.dart";

import "../ditto_live.dart";
import "registry.dart";

extension type _RequestArgs(Map<String, dynamic> inner) {
  dynamic operator [](String key) => inner[key];

  String get action => inner["action"] as String;

  // All methods from here onwards are fallible - the properties in question may not exist

  Ditto get ditto {
    final keyInt = int.parse(inner["ditto"] as String);
    return Registry.instance.allDittos[keyInt]!;
  }

  String get query => inner["query"] as String;
  String get args => inner["args"] as String;
}

var _registered = false;
@internal
void registerDittoServiceExtensionIfNeeded() {
  if (_registered) return;

  registerExtension("ext.ditto_live.invoke", (method, args) async {
    try {
      final result = await _handleServiceExtensionRequest(_RequestArgs(args));
      return ServiceExtensionResponse.result(jsonEncode(result));
    } on ServiceExtensionResponse catch (e) {
      return e;
      // ignore: avoid_catching_errors
    } on DittoError catch (e) {
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.invalidParams,
        e.toString(),
      );
    } on DittoException catch (e) {
      return ServiceExtensionResponse.error(
        ServiceExtensionResponse.invalidParams,
        e.toString(),
      );
    }
  });

  _registered = true;
}

Future<Map<String, dynamic>> _handleServiceExtensionRequest(
  _RequestArgs args,
) async =>
    switch (args.action) {
      "get_ditto_keys" => await _getAllDittos(),
      "set_sync" => await _setSync(args.ditto, args["enabled"] as bool),
      "get_sync" => await _getSync(args.ditto),
      "execute" => await _execute(args.ditto, args.query, args.args),
      "get_log_level" => {
          "value": switch (DittoLogger.minimumLogLevel) {
            LogLevel.error => 0,
            LogLevel.warning => 1,
            LogLevel.info => 2,
            LogLevel.debug => 3,
            LogLevel.verbose => 4,
          },
        },
      "set_log_level" => await _setLogLevel(int.parse(args["value"] as String)),
      final other => throw ServiceExtensionResponse.error(
          ServiceExtensionResponse.invalidParams,
          "unknown method $other",
        ),
    };

Future<Map<String, dynamic>> _setLogLevel(int levelInt) async {
  DittoLogger.minimumLogLevel = switch (levelInt) {
    0 => LogLevel.error,
    1 => LogLevel.warning,
    2 => LogLevel.info,
    3 => LogLevel.debug,
    4 => LogLevel.verbose,
    final other => throw Exception("unknown int: $other"),
  };
  return {};
}

Future<Map<String, dynamic>> _getSync(Ditto ditto) async =>
    {"enabled": ditto.sync.isActive};

Future<Map<String, dynamic>> _setSync(Ditto ditto, bool enabled) async {
  if (enabled) {
    ditto.sync.start();
  } else {
    ditto.sync.stop();
  }

  return {};
}

Future<Map<String, dynamic>> _execute(
  Ditto ditto,
  String query,
  String queryArgs,
) async {
  final Map<String, dynamic> args;
  try {
    args = jsonDecode(queryArgs) as Map<String, dynamic>;
  } catch (e) {
    log("invalid json arguments", error: e);
    return {"error": "invalid_json"};
  }
  final queryResult = await ditto.store.execute(query, arguments: args);

  final items = queryResult.items.map((item) => item.value).toList();
  final mutatedIds = queryResult.mutatedDocumentIDs();

  return {
    "items": items,
    "mutatedIds": mutatedIds,
  };
}

Future<Map<String, dynamic>> _getAllDittos() async {
  final futures = Registry.instance.allDittos.entries.map(
    (entry) async => {
      "key": entry.key,
      "peerKeyString": entry.value.presence.graph.localPeer.peerKey,
    },
  );

  return {"dittos": await Future.wait(futures)};
}
