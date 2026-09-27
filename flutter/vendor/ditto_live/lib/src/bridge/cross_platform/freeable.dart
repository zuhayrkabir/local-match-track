import "package:meta/meta.dart";

/// Interface to abstract over things that need to be freed
///
/// This replaces an old `CPKeepAliveGuard` abstraction, which tried to achieve
/// the same goals:
/// - create a cross-platform interface for freeing native resources
/// - express it in the type system
/// - make it the responsibility of the SDK outside `core/` to handle cleanup
///
/// However, [CPFreeable] must be explicitly called, whereas `CPKeepAliveGuard`
/// was implemented using [Finalizer]s and would free resources whenever they
/// went out of scope.
///
/// There are a few reasons for preferring the explicit approach:
/// - [Finalizer]s are not guaranteed to be called at all
/// - if they are called, the time at which they are called is not predictable
/// - it's surprising to many Flutter developers to have behaviour change when
///   something is GC-ed. Flutter developers are used to dealing with objects
///   that will leak if not manually disposed. We should not try to emulate
///   Swift/Rust here
/// - it's hard to implement this pattern correctly in Dart
@internal
// ignore: one_member_abstracts
abstract interface class CPFreeable {
  void free();
  factory CPFreeable.noop() => CPDartFnFreeable(() {});
}

@internal
final class CPDartFnFreeable implements CPFreeable {
  final void Function() _free;

  CPDartFnFreeable(this._free);

  @override
  void free() => _free();
}

@internal
final class CPMultiFreeable implements CPFreeable {
  CPMultiFreeable(this.freeables);
  final Iterable<CPFreeable> freeables;
  @override
  void free() {
    for (final freeable in freeables) {
      freeable.free();
    }
  }
}

/// Free a [CPFreeable] using the drain-then-close pattern:
///
/// - For [CPMultiFreeable]: free the first member (typically the
///   native-unregister step) immediately, then wait long enough for any
///   in-flight native callbacks to arrive and be safely ignored, then free the
///   rest (typically the `NativeCallable` close).
/// - For other [CPFreeable]s: wait the same drain window, then free.
///
/// The 500ms drain mitigates SDKS-3134-class SIGABRTs where a native callback
/// arrives after its `NativeCallable` has been closed during isolate teardown.
/// Callers should set their own `_isShuttingDown` flag before invoking this so
/// callbacks that do arrive in the window become no-ops.
///
/// This helper centralises a pattern that previously lived in
/// `transport_conditions.dart`, `presence/presence.dart`, and `auth.dart`.
/// Other callers can migrate incrementally.
@internal
Future<void> drainThenClose(CPFreeable freeable) async {
  // 500ms margin chosen to mirror the existing presence/auth drain windows.
  // Slower CI hosts have historically needed >100ms; see SDKS-3134.
  const drain = Duration(milliseconds: 500);

  if (freeable is CPMultiFreeable) {
    final freeables = freeable.freeables.toList();
    if (freeables.isEmpty) return;
    freeables[0].free();
    await Future<void>.delayed(drain);
    for (var i = 1; i < freeables.length; i++) {
      freeables[i].free();
    }
  } else {
    await Future<void>.delayed(drain);
    freeable.free();
  }
}
