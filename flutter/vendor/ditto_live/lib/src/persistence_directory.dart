import "package:flutter/foundation.dart";
import "package:meta/meta.dart";
import "package:path/path.dart" as p;

import "globals.dart";

@internal
String makePersistenceDirectoryPath(String path) {
  if (kIsWeb) return path;
  if (p.isAbsolute(path)) return path;

  return switch (Globals.instance.documentsDirectory) {
    null => path,
    final dir => "$dir/$path",
  };
}
