import "dart:async";
import "dart:collection";
import "dart:typed_data";

import "package:meta/meta.dart";

import "../../../ditto_live.dart";
import "../analysis/annotations.dart";
import "../attachment_fetcher.dart";
import "../bridge/native/ffi/cbor.dart";
import "../exception.dart";

import "../attachment.dart";
import "../ditto.dart";
import "../shared/attachment_token.dart";
import "execute.dart";
import "transaction.dart";

import "../bridge/bridge.dart" as core;

/// Either a [String] or a [Uint8List]
@external
typedef StringOrData = Object;

@internal
Store makeStore(Ditto ditto) => Store._(ditto);

/// An object that provides access to Ditto's store.
///
/// An instance of [Store] can be obtained from [Ditto.store]:
/// ```dart
/// final ditto = await Ditto.open(/* ... */);
/// final store = ditto.store;
/// ```
/// This class is not user-constructible.
///
/// This class cannot be sent between isolates.
@external
@pragma("vm:isolate-unsendable")
final class Store {
  final Ditto _ditto;

  final Set<AttachmentFetcher> _attachmentFetchers = {};

  Store._(this._ditto);

  /// When `true`, [execute] runs the FFI call inline on the calling isolate
  /// instead of dispatching to the per-[Ditto] long-lived worker isolate.
  ///
  /// Defaults to `false`. With the default, the FFI call runs on a worker
  /// isolate spawned lazily on the first [execute] call and torn down by
  /// [Ditto.close], so a long-running query does not block the calling
  /// isolate. Setting this to `true` skips the SendPort hop and runs the
  /// FFI call inline; a slow query will block the calling isolate, but a
  /// tight loop of small queries avoids the per-call dispatch cost.
  ///
  /// Recommended when query work is known-short and throughput of many small
  /// queries matters more than main-isolate responsiveness.
  ///
  /// The value applies to every [Store] in the current isolate, persists
  /// across [Ditto.open] / [Ditto.close] cycles for the lifetime of the
  /// isolate, and does not propagate to isolates you spawn yourself. Avoid
  /// toggling it while [execute] calls are in flight; concurrent calls read
  /// the value independently and may observe different dispatch modes.
  ///
  /// No effect on web.
  @experimental
  static set experimentalSkipExecuteIsolateOffload(bool value) =>
      core.experimentalSkipExecuteIsolateOffload = value;

  /// See [experimentalSkipExecuteIsolateOffload].
  @experimental
  static bool get experimentalSkipExecuteIsolateOffload =>
      core.experimentalSkipExecuteIsolateOffload;

  /// Executes a DQL query and returns matching items as a [QueryResult].
  ///
  /// Note that this method only returns results from the local store without waiting for any
  /// [SyncSubscription]s to have caught up with the latest changes.
  /// Only use this method if your program must proceed with immediate results.
  /// Use a [StoreObserver] (obtained from [Store.registerObserver]) to receive updates to
  /// query results as soon as they have been synced to this peer.
  Future<QueryResult> execute(
    String query, {
    Map<String, dynamic> arguments = const {},
  }) async =>
      privateExecuteImpl(_ditto, query, arguments);

  /// Installs and returns a [StoreObserver] for a query.
  ///
  /// Ditto will call [onChange] (if provided) with a [QueryResult] for that query whenever documents in the local
  /// store change such that the result the query changes.
  ///
  /// [onChange] is optional. If you prefer a [Stream]-based API, you can also use [StoreObserver.changes],
  /// which provides the changes as a [Stream] of [QueryResult]s.
  ///
  /// [query] must be a `SELECT` query.
  StoreObserver registerObserver(
    String query, {
    Map<String, dynamic> arguments = const {},
    void Function(QueryResult)? onChange,
  }) =>
      StoreObserver._make(_ditto, query, arguments, onChange);

  /// Variant of [registerObserverWithSignalNext] that automatically signals
  /// readiness for the next update once an update has been enqueued to the
  /// [StoreObserverV2.changes] stream and any provided [onChange] callback has
  /// returned.
  ///
  /// [query] must be a `SELECT` query, otherwise an exception will be thrown.
  ///
  /// Calling `pause` / `resume` on the [StoreObserverV2.changes] stream will
  /// automatically pause and resume the observer as needed.
  ///
  /// Calling [StoreObserverV2.signalNext] has no effect for observers
  /// registered through this method.
  ///
  /// See the documentation of [registerObserverWithSignalNext] for a variant
  /// with explicit control over when to request the next update.
  @experimental
  StoreObserverV2 registerObserverV2(
    String query, {
    Map<String, dynamic> arguments = const {},
    void Function(QueryResult)? onChange,
  }) =>
      StoreObserverV2._make(
        _ditto,
        query,
        arguments,
        _SignalMode.auto,
        onChange,
        null,
      );

  /// Registers and returns a [StoreObserverV2] for a query, configuring Ditto
  /// to trigger [onChange] and emit events on the [StoreObserverV2.changes]
  /// stream whenever results in the local store change such that the result
  /// of the query changes.
  ///
  /// [query] must be a `SELECT` query, otherwise an exception will be thrown.
  ///
  /// Providing [onChange] is optional. If you prefer a [Stream]-based API,
  /// you can use [StoreObserverV2.changes]. In that case, use
  /// [StoreObserverV2.signalNext] to signal readiness for the next update.
  ///
  /// **Warning:** Following each callback invocation or stream event, you
  /// must call either [StoreObserverV2.signalNext] or the `signalNext`
  /// callback parameter to indicate readiness to receive the next update.
  /// Failing to do so will result in the observer not receiving any further
  /// updates. It is recommended *not* to use the pause/resume mechanism of
  /// the [StoreObserverV2.changes] stream for observers registered through
  /// this method; a warning will be logged if `pause` is called.
  ///
  /// Example:
  /// ```dart
  /// ditto.store.registerObserverWithSignalNext(
  ///   'SELECT * FROM cars',
  ///   onChange: (result, signalNext) async {
  ///     await processResult(result); // Do slow async work
  ///     signalNext(); // Ready for the next update
  ///   },
  /// );
  /// ```
  ///
  /// See also:
  /// - [registerObserverV2] for a convenience variant that automatically
  ///   handles backpressure and synchronizes with the stream's pause/resume
  ///   mechanism.
  /// - [registerObserver] for the legacy API without backpressure control.
  @experimental
  StoreObserverV2 registerObserverWithSignalNext(
    String query, {
    Map<String, dynamic> arguments = const {},
    void Function(QueryResult result, void Function() signalNext)? onChange,
  }) =>
      StoreObserverV2._make(
        _ditto,
        query,
        arguments,
        _SignalMode.manual,
        null,
        onChange,
      );

  /// Provides the set of all currently active attachment fetchers.
  ///
  /// Manage attachment fetchers using [fetchAttachment] to start a new attachment fetch
  /// and [AttachmentFetcher.stop] to cancel an existing attachment fetch.
  ///
  /// This property ensures that attachment fetch operations can be tracked and managed effectively,
  /// providing insights into ongoing operations.
  Set<AttachmentFetcher> get attachmentFetchers =>
      UnmodifiableSetView(_attachmentFetchers);

  /// Creates a new [Attachment] object, which can then be inserted into a document.
  ///
  /// The file residing at the provided path will be copied into Ditto's store.
  /// The [Attachment] object returned can be used to insert an attachment into a document.
  ///
  /// **Note**: Relative paths for file sources are resolved from the Ditto persistence directory.
  ///
  /// Metadata about the attachment can be provided, which will be replicated to other peers alongside the file attachment.
  ///
  /// Example:
  /// ```dart
  /// // Copy the file into Ditto's store and create an attachment object.
  /// final attachment = await ditto.store.newAttachment(
  ///   '/path/to/my/file.pdf',
  ///   AttachmentMetadata({'my_field': 'optional metadata'}),
  /// );
  ///
  /// // Prepare the document value including the attachment.
  /// final doc = {
  ///   '_id': '123',
  ///   'my_attachment': attachment,
  ///   'other': 'some-string'
  /// };
  ///
  /// // Insert the document into the collection, marking `my_attachment` as an attachment field.
  /// await ditto.store.execute(
  ///   'INSERT INTO my_collection (my_attachment ATTACHMENT) VALUES (:doc)',
  ///   {'doc': doc}
  /// );
  /// ```
  ///
  /// [pathOrData] The path to the file that you want to create an attachment with or the raw data.
  ///
  /// [metadata] Optional metadata that will be stored alongside the attachment.
  ///
  /// Returns an [Attachment] object that can be used to insert the attachment into a document.
  ///
  /// Throws if:
  ///  - the file at the given path could not be read due to insufficient permissions.
  ///  - the file at the given path could not be found.
  ///  - the attachment could not be created for other reasons.
  ///  - trying to create an attachment from a file path in a web browser.
  Future<Attachment> newAttachment(
    StringOrData pathOrData, [
    AttachmentMetadata? metadata,
  ]) async {
    metadata ??= AttachmentMetadata({});

    final core.CPAttachment attachment;

    switch (pathOrData) {
      case final String path:
        attachment = core
            .dittoNewAttachmentFromFile(
              _ditto.ptr,
              path,
              core.CPAttachmentFileOperation.copy,
            )
            .extract();
      case final Uint8List data:
        attachment =
            await core.dittoNewAttachmentFromBytes(_ditto.ptr, data).extract();
      default:
        throw privateMakeDittoException(
          "Invalid `PathOrData`, expected `String` or `Uint8List`, but got: ${pathOrData.runtimeType}, $pathOrData",
        );
    }

    final (handle, id, len) =
        core.utilExtractAndFreeAttachment(attachment).extract();

    final token = privateMakeAttachmentToken(
      id: id,
      len: len,
      metadata: metadata,
    );
    return privateMakeAttachment(handle, _ditto, token);
  }

  bool _removeAttachmentFetcher(AttachmentFetcher attachmentFetcher) {
    if (!attachmentFetcher.isStopped) {
      throw privateMakeDittoError(
        "Internal inconsistency, can't remove attachment fetcher that has not stopped.",
      );
    }

    return _attachmentFetchers.remove(attachmentFetcher);
  }

  /// Fetches an attachment by its token and allows monitoring of the fetching
  /// process through a callback that handles [AttachmentFetchEvent]s.
  ///
  /// The method returns an instance of an [AttachmentFetcher] which can be used
  /// to manage the fetch operation (e.g., stopping the fetch).
  ///
  /// [token] - The token representing the attachment to be fetched.
  /// [onFetchEvent] - Callback to handle fetch events, including progress and
  /// completion.
  ///
  /// Returns an [AttachmentFetcher] which can be used to control and monitor
  /// the fetch process.
  AttachmentFetcher fetchAttachment(
    Map<String, dynamic> token,
    void Function(AttachmentFetchEvent event) onFetchEvent,
  ) {
    final completer = Completer<Attachment>();
    final ffiAttachmentToken = AttachmentToken.fromJson(token);
    final attachmentFetcher = makeAttachmentFetcher(
      completer.future,
      _ditto,
      ffiAttachmentToken,
      (fetchEvent) {
        switch (fetchEvent) {
          case AttachmentFetchEventCompleted():
            completer.complete(fetchEvent.attachment);
          case AttachmentFetchEventDeleted():
            completer.completeError(
              privateMakeDittoError(
                "The attachment was deleted while being fetched.",
              ),
            );
          default:
            break;
        }
        onFetchEvent(fetchEvent);
      },
    );
    _attachmentFetchers.add(attachmentFetcher);
    return attachmentFetcher;
  }

  /// Executes multiple DQL queries within a single atomic transaction.
  ///
  /// This ensures that either all statements are executed successfully, or none
  /// are executed at all, providing strong consistency guarantees. Certain mesh
  /// configurations may impose limitations on these guarantees. For more
  /// details, refer to the [Ditto
  /// documentation](https://ditto.com/link/sdk-latest-crud-transactions).
  /// Transactions are initiated as read-write transactions by default, and only
  /// a single read-write transaction is being executed at any given time. Any
  /// other read-write transaction started concurrently will wait until the
  /// current transaction has been committed or rolled back. Therefore, it is
  /// crucial to make sure a transaction finishes as early as possible so other
  /// read-write transactions aren't blocked for a long time.
  ///
  /// [Store.transaction] takes a function as its first positional argument.
  /// This callback has a single parameter, with type [Transaction]. This
  /// [Transaction] object is only usable within the scope of [callback]. It
  /// should not be stored anywhere else (such as a local variable or a class
  /// instance member). This callback can return any value, which will be the
  /// return value of the call to [Store.transaction].
  ///
  /// Optionally, if the callback returns an instance of
  /// [TransactionCompletionAction], its value will be used to determine the
  /// behaviour of the transaction. If it is
  /// [TransactionCompletionAction.commit], the transaction will be committed,
  /// but if it is [TransactionCompletionAction.rollback], the transaction will
  /// be rolled back and no changes will occur. If the value does not have the
  /// type [TransactionCompletionAction], then the transaction is implicltly
  /// committed.
  ///
  /// If [callback] throws, the transaction will be implicitly rolled-back, and
  /// the error will be propagated up to the caller.
  ///
  /// A transaction can also be configured to be read-only using the
  /// [isReadOnly] parameter. Multiple read-only transactions can be executed
  /// concurrently. However, executing a mutating DQL statement in a read-only
  /// transaction will throw a [DittoException].
  ///
  /// A transaction can also be given a [hint] string, which is logged. This is
  /// mostly useful for debugging and testing.
  ///
  /// For a complete guide on transactions, please refer to the [Ditto
  /// documentation](https://ditto.com/link/sdk-latest-crud-transactions).
  Future<T> transaction<T>(
    Future<T> Function(Transaction) callback, {
    bool isReadOnly = false,
    String? hint,
  }) =>
      privateTransactionImpl(
        _ditto,
        callback,
        isReadOnly: isReadOnly,
        hint: hint,
      );
}

/// An object that tracks when results for its query change.
///
/// Create a [StoreObserver] by calling [Store.registerObserver].
/// The store observer remains active until the owning [Ditto] object is
/// closed or [cancel] is called. Always call [cancel] (or close the owning
/// [Ditto]) when you are done with an observer; even an observer that never
/// emits or is never listened to holds resources until then.
///
/// ## When events start flowing
///
/// If you pass an `onChange` callback to [Store.registerObserver], the
/// callback may fire as soon as a matching change happens — there is no
/// need to listen to [changes].
///
/// If you do not pass `onChange`, the observer does not begin matching
/// queries against the store until something calls `.listen()` on
/// [changes]. An observer that is registered without `onChange` and never
/// listened to produces no events.
///
/// [changes] is a single-subscription stream: events emitted before the
/// first listener attaches are buffered and delivered when it does. If you
/// register an observer and then delay listening (for example, register in
/// `initState` but subscribe in a later `build` on a peer that is actively
/// syncing a large collection), that buffer can grow. Pass an `onChange`
/// callback if events must be processed as they arrive.
@external
interface class StoreObserver {
  final Ditto _ditto;
  final int _liveQueryId;

  /// The query string that was passed to [Store.registerObserver].
  final String queryString;

  /// The query arguments that were passed to [Store.registerObserver].
  final Map<String, dynamic> queryArguments;

  final core.CPFreeable _freeable;
  final StreamController<QueryResult> _controller;

  var _cancelled = false;

  /// Tracks whether `dittoLiveQueryStart` has actually been called for this
  /// observer. In the deferred-start path (no `onChange` callback, lazy start
  /// on first listen), this stays `false` until the first `.changes` listener
  /// attaches. `cancel()` skips `dittoLiveQueryStop` when this is `false`
  /// to avoid stopping a never-started live query (SDKS-3878).
  var _liveQueryStarted = false;

  /// Whether this [StoreObserver] is cancelled.
  ///
  /// An observer is cancelled when either:
  ///  - [cancel] is called
  ///  - the owning [Ditto] instance is closed
  ///
  /// The owning-[Ditto]-closed leg is consulted directly here: [Ditto.close]
  /// tears down the FFI live query but does not reach back into individual
  /// observers to flip [_cancelled], so a closed [Ditto] is treated as
  /// cancellation at read time (SDKS-3916).
  bool get isCancelled => _cancelled || _ditto.isClosed;

  /// Cancel observation. No-op if this [StoreObserver] is already cancelled.
  ///
  /// The handler that was passed in when calling [Store.registerObserver] will no longer
  /// be called, and [changes] will no longer emit any new events.
  ///
  /// A [StoreObserver] is considered cancelled when the owning [Ditto] object is closed.
  void cancel() {
    // Guard on isCancelled (not the raw _cancelled field) so a post-close
    // cancel() honors the docstring's no-op contract — `_ditto.ptr` below
    // would otherwise throw DittoClosedException. StoreObserverV2.cancel()
    // already uses this shape; SDKS-3916 brings V1 into line.
    if (isCancelled) return;

    _cancelled = true;
    // Only stop the live query if it was actually started. In the lazy-start
    // path, an observer cancelled before any listener attached has no live
    // query to stop (SDKS-3878).
    if (_liveQueryStarted) {
      core.dittoLiveQueryStop(_ditto.ptr, _liveQueryId);
    }
    // Close the stream first so no further results surface to listeners.
    _controller.close();
    // Defer freeing the native callback. `dittoLiveQueryStop` marks the live
    // query stopped but does NOT drain callbacks the Rust tokio runtime has
    // already dispatched. The freeable here closes the `NativeCallable`
    // (see `dittoffiTryExperimentalRegisterChangeObserverStr`), and closing
    // it while a dispatch is in-flight aborts the Dart VM with "Callback
    // invoked after it has been deleted" — the crash reported with active
    // sync over a large collection (SPO-1022).
    //
    // Note: SDKS-2494 / SDKS-2501 already added an `if (!controller.isClosed)`
    // guard inside the registration wrapper. That guard prevents the Dart-
    // level `Bad state: Cannot add new events after calling close` exception,
    // but only AFTER the native trampoline has been entered — closing the
    // `NativeCallable` does not prevent invocation, it makes invocation crash.
    // So the controller guard does not fix the abort; this drain does.
    //
    // Unlike the V2 observer path, the legacy FFI has no Rust-driven `free`
    // callback to signal when draining is complete (SDKS-2389), so we wait
    // for in-flight callbacks to land — they are then dropped by the existing
    // `controller.isClosed` guard — before closing the `NativeCallable`.
    // Delegates to the shared `drainThenClose` helper, which centralizes the
    // sequenced-cleanup pattern established by the presence multiplexer
    // (SDKS-3134) for retirement once SDKS-3762 lands. On web the freeable is
    // a no-op, so this is a harmless delayed no-op.
    unawaited(core.drainThenClose(_freeable));
  }

  /// A convenience API that produces a [Stream] of [QueryResult]s.
  ///
  /// [QueryResult]s emitted by this [Stream] will also be passed to the `onChange`
  /// parameter of [Store.registerObserver], if it was provided.
  @DartSpecific("Users can pass a callback to registerObserver")
  Stream<QueryResult> get changes => _controller.stream;

  factory StoreObserver._make(
    Ditto ditto,
    String query,
    Map<String, dynamic> args,
    void Function(QueryResult)? onChange,
  ) {
    final controller = StreamController<QueryResult>();

    void wrappedCallback(core.CPChangeHandlerWithQueryResult result) {
      // The controller should not really be the source of truth for isClosed,
      // but as the StoreObserver instance does not exist yet at this point it's
      // the easiest way to avoid calling the onChange callback after
      // cancellation.
      if (!controller.isClosed) {
        final queryResult = privateMakeQueryResult(result.queryResult);
        onChange?.call(queryResult);
        controller.add(queryResult);
      }
    }

    final result = core.dittoffiTryExperimentalRegisterChangeObserverStr(
      ditto.ptr,
      query,
      toCborBytes(args),
      wrappedCallback,
    );

    final (liveQueryId, freeable) = result.extract();

    final observer = StoreObserver._(
      ditto,
      liveQueryId,
      query,
      args,
      freeable,
      controller,
    );

    // Start policy: eager if the caller supplied an onChange callback (they
    // want events immediately regardless of whether they listen to
    // `changes`); otherwise defer the live-query start until something
    // actually listens to `changes` (observers registered but never consumed
    // should cost nothing — SDKS-3878). Safe under single-subscription
    // semantics: `onListen` fires exactly once on the first `.listen()`,
    // and `cancel()` skips the stop call when `_liveQueryStarted` is false,
    // so a cancel-before-listen does not call stop on a never-started query.
    if (onChange != null) {
      core.dittoLiveQueryStart(ditto.ptr, liveQueryId);
      observer._liveQueryStarted = true;
    } else {
      controller.onListen = () {
        // Guard against `.listen()` racing with `cancel()`: by the time
        // onListen fires, _cancelled may already be true (e.g., a caller
        // listened on a stream that was just cancelled). Skip the start
        // call in that case so we don't allocate a live query that will
        // never be stopped.
        if (observer._cancelled) return;
        core.dittoLiveQueryStart(ditto.ptr, liveQueryId);
        observer._liveQueryStarted = true;
      };
    }

    return observer;
  }

  StoreObserver._(
    this._ditto,
    this._liveQueryId,
    this.queryString,
    this.queryArguments,
    this._freeable,
    this._controller,
  );
}

@internal
extension PrivateRemoveAttachmentStoreExt on Store {
  bool removeAttachmentFetcher(AttachmentFetcher fetcher) =>
      _removeAttachmentFetcher(fetcher);
}

enum _SignalMode { auto, manual }

/// An object that tracks when results for its query change, with explicit
/// control over when to signal readiness for the next update.
///
/// This is an alternative to [StoreObserver] that uses a single-subscription
/// stream and provides control over backpressure via a signal-next mechanism.
///
/// Create a [StoreObserverV2] by calling [Store.registerObserverV2] (auto
/// signal-next, integrates with stream pause/resume) or
/// [Store.registerObserverWithSignalNext] (manual signal-next).
///
/// The store observer remains active until the owning [Ditto] object is
/// closed, [cancel] is called, or the subscription to [changes] is cancelled.
@experimental
@external
interface class StoreObserverV2 {
  final Ditto _ditto;
  final core.CPPointer<core.CPStoreObserver> _storeObserverPtr;
  final _SignalMode _signalMode;
  final StreamController<QueryResult> _controller;

  void Function()? _pendingSignalNext;
  bool _isPaused = false;

  /// The query string that was passed to [Store.registerObserverV2] or
  /// [Store.registerObserverWithSignalNext].
  String get queryString =>
      core.dittoFfiStoreObserverQueryString(_storeObserverPtr);

  /// The query arguments as CBOR-encoded bytes.
  Uint8List get queryArgumentsCBOR =>
      core.dittoFfiStoreObserverQueryArgumentsCbor(_storeObserverPtr);

  /// The query arguments that were passed when registering this observer.
  Map<String, dynamic> get queryArguments =>
      Map<String, dynamic>.from(fromCborBytes(queryArgumentsCBOR) as Map);

  /// Whether this [StoreObserverV2] has been cancelled.
  ///
  /// An observer is cancelled when any of the following occurs:
  /// - [cancel] is called
  /// - the owning [Ditto] instance is closed
  /// - the subscription to [changes] is cancelled
  ///
  /// The owning-[Ditto]-closed leg is short-circuited before touching the
  /// native observer handle: [Ditto.close] frees the underlying FFI
  /// machinery without flipping the per-observer cancelled flag, so reading
  /// it post-close would otherwise report `false` (and risk touching a freed
  /// handle). Treat a closed [Ditto] as cancellation (SDKS-3916).
  bool get isCancelled =>
      _ditto.isClosed ||
      core.dittoFfiStoreObserverIsCancelled(_storeObserverPtr);

  /// Cancel observation. No-op if already cancelled.
  ///
  /// The [changes] stream will be closed and no further events will be
  /// emitted.
  void cancel() {
    if (isCancelled) return;

    core.dittoFfiStoreObserverCancel(_storeObserverPtr);
    if (!_controller.isClosed) _controller.close();
    // Callback cleanup is platform-specific:
    // - On native: driven by Rust invoking our `free` callback when it
    //   drops the handler (see bridge/native/store.dart). Freeing the
    //   NativeCallable here would race with inflight callbacks and
    //   abort the Dart VM (SDKS-2389).
    // - On web: the wrapped JSFunction is held by Rust until the observer
    //   is freed; JS GC reclaims it once dittoffi drops its reference.
  }

  /// Signal that you are ready to receive the next update.
  ///
  /// This method only has an effect for observers registered through
  /// [Store.registerObserverWithSignalNext]. For observers registered
  /// through [Store.registerObserverV2], signalling is automatic and this
  /// method is a no-op.
  ///
  /// Calling this method multiple times before the next update arrives has
  /// no additional effect.
  void signalNext() {
    if (_signalMode == _SignalMode.auto) return;
    final pending = _pendingSignalNext;
    _pendingSignalNext = null;
    pending?.call();
  }

  /// A [Stream] of [QueryResult]s that emits whenever the query results
  /// change.
  ///
  /// This is a single-subscription stream. Only one listener can be attached
  /// at a time. When the subscription is cancelled, the observer is also
  /// cancelled.
  ///
  /// **Warning:** Pausing the stream has no effect for observers registered
  /// through [Store.registerObserverWithSignalNext]. Use [signalNext] to
  /// control backpressure instead in that case.
  Stream<QueryResult> get changes => _controller.stream;

  factory StoreObserverV2._make(
    Ditto ditto,
    String query,
    Map<String, dynamic> args,
    _SignalMode signalMode,
    void Function(QueryResult)? onChange,
    void Function(QueryResult, void Function())? onChangeWithSignalNext,
  ) {
    StoreObserverV2? observer;

    /// Returns true (and logs) if `observer` is unexpectedly null. We expect
    /// the first callback to always arrive after registration has completed,
    /// but this guards against bugs without crashing.
    bool observerUnexpectedlyNull() {
      if (observer != null) return false;
      const message = "Internal error, StoreObserverV2 callback invoked before "
          "observer was initialized";
      assert(false, message);
      core.dittoLog(core.LogLevel.error, message);
      return true;
    }

    final controller = StreamController<QueryResult>()
      ..onPause = () {
        if (signalMode == _SignalMode.auto) {
          if (observerUnexpectedlyNull()) return;
          observer!._isPaused = true;
        } else {
          core.dittoLog(
            core.LogLevel.warning,
            "Called pause() on StoreObserverV2.changes when it was "
            "registered through registerObserverWithSignalNext(). "
            "Use signalNext() to control backpressure instead.",
          );
        }
      }
      ..onResume = () {
        if (signalMode == _SignalMode.auto) {
          if (observerUnexpectedlyNull()) return;
          observer!._isPaused = false;
          final pending = observer._pendingSignalNext;
          observer._pendingSignalNext = null;
          pending?.call();
        }
      }
      ..onCancel = () {
        if (observerUnexpectedlyNull()) return;
        observer!.cancel();
      };

    void wrappedCallback(
      core.CPChangeHandlerWithQueryResultAndSignalNext result,
    ) {
      if (observerUnexpectedlyNull()) return;
      final queryResult = privateMakeQueryResult(result.queryResult);

      switch (signalMode) {
        case _SignalMode.auto:
          if (!controller.isClosed) onChange?.call(queryResult);
          if (!controller.isClosed) controller.add(queryResult);
          if (observer!._isPaused) {
            observer._pendingSignalNext = result.signalNext;
          } else {
            result.signalNext();
          }
        case _SignalMode.manual:
          observer!._pendingSignalNext = result.signalNext;
          if (!controller.isClosed) {
            onChangeWithSignalNext?.call(queryResult, observer.signalNext);
          }
          if (!controller.isClosed) controller.add(queryResult);
      }
    }

    final (storeObserverPtr, _) = core
        .dittoFfiStoreRegisterObserverThrows(
          ditto.ptr,
          query,
          toCborBytes(args),
          wrappedCallback,
        )
        .extract();

    // Assign to `observer` (instead of returning directly) so the callback
    // above can reference it.
    // ignore: join_return_with_assignment
    observer =
        StoreObserverV2._(ditto, storeObserverPtr, signalMode, controller);

    return observer;
  }

  StoreObserverV2._(
    this._ditto,
    this._storeObserverPtr,
    this._signalMode,
    this._controller,
  );
}
