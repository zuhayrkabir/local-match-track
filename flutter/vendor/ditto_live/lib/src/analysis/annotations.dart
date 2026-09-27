/// Annotations used by our internal tooling
library;

import "package:meta/meta.dart";

final class _External {
  const _External();
}

/// An annotation used to complement [internal]. If neither [internal] nor
/// [external] are present on a public member, a diagnostic is issued. A
/// different diagnostic is issued if both are present.
///
/// The intention of this rule is to force people working on the SDK to consider
/// carefully whether a particular item is intended to be public, since Dart's
/// limited language-level privacy tooling makes it easy to accidentally leak
/// API details.
///
/// Perhaps this is a good place to put SDK catalog things 🤔 hmmmmmmm
const external = _External();

/// Marks a particular API as a piece of syntax sugar specific to Dart/Flutter
///
/// Customers should not expect to find an equivalent API in other SDKs
///
/// The message shows the equivalent Dart API that is considered "standard" in other SDKs
@internal
final class DartSpecific {
  final String? message;
  const DartSpecific([this.message]);
}

/// Marks a function as an entrypoint into Ditto functionality
///
/// Useful for grepping when trying to find places to insert checks (e.g. was
/// `Ditto.init()` called before calling this function)
@internal
final class DittoEntrypoint {
  const DittoEntrypoint();
}

/// Marks an item as having a name and path that is relied upon by the internal
/// linter
///
/// Several types in the SDK are known to the linter and are specially handled.
/// In order to do this, the linter needs to know how to check whether an
/// expression has a particular type. Some of these checks use the URL of an
/// item, for example `package:ditto_live/src/foo/bar.dart#Baz`, which refers to
/// a class/enum/etc. called `Baz` inside the file `src/foo/bar.dart`.
///
/// If the underlying item is renamed or moved to a new file, the linter will
/// break, so we need to be careful with these types. If you *need* to move or
/// rename, update `<monorepo>/sdks/flutter/lint_internal/src/util/types.dart` as
/// well to keep them in sync.
@internal
final class DoNotMoveOrRename {
  const DoNotMoveOrRename();
}

/// Marks a type as needing to be converted to a local variable. The [wasm] and
/// [native] parameters indicate method names that must be used to convert to
/// the local variable type.
@internal
final class NeedsLocal {
  final String? wasm;
  final String? native;
  const NeedsLocal({this.wasm, this.native});
}

/// Marks a library as having native FFI wrapper functions
@internal
final class NativeFfiLibrary {
  const NativeFfiLibrary();
}
