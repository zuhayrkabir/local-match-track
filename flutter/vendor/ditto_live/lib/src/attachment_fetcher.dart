import "dart:async";

import "package:meta/meta.dart";

import "analysis/annotations.dart";
import "shared/attachment_token.dart";
import "attachment.dart";

import "ditto.dart";

import "bridge/bridge.dart" as core;
import "store/store.dart";

@internal
const makeAttachmentFetcher = AttachmentFetcher._;

/// These objects are returned by calls to [Store.fetchAttachment].
@external
interface class AttachmentFetcher {
  final Ditto _ditto;

  int? _cancelToken;
  var _isStopped = false;

  final AttachmentToken _token;

  /// Returns a [Future] for the [Attachment] that can be awaited.
  final Future<Attachment?> attachment;

  core.CPFreeable? _freeable;

  AttachmentFetcher._(
    this.attachment,
    this._ditto,
    this._token,
    void Function(AttachmentFetchEvent)? eventHandler,
  ) {
    _initiateAttachmentFetch(_token, eventHandler ?? (_) {});
  }

  Future<void> _initiateAttachmentFetch(
    AttachmentToken token,
    void Function(AttachmentFetchEvent) eventHandler,
  ) async {
    final (cancelToken, freeable) = await core
        .dittoResolveAttachment(
          _ditto.ptr,
          token.idBytes,
          (pointer) {
            _endAttachmentFetch();
            return eventHandler(
              AttachmentFetchEventCompleted(
                attachment: privateMakeAttachment(pointer, _ditto, token),
              ),
            );
          },
          (downloadedBytes, totalBytes) => eventHandler(
            AttachmentFetchEventProgress(
              totalBytes: totalBytes,
              downloadedBytes: downloadedBytes,
            ),
          ),
          () {
            _endAttachmentFetch();
            return eventHandler(AttachmentFetchEventDeleted());
          },
        )
        .extract();

    _freeable = freeable;

    _cancelToken = cancelToken;
  }

  /// Marks the attachment fetcher as stopped and cleans up any associated
  /// resources without cancelling the fetch operation.
  void _endAttachmentFetch() {
    _cancelToken = null;
    stop();
  }

  /// Indicates whether the fetch operation has been stopped or has completed.
  bool get isStopped => _isStopped;

  /// Stops fetching the associated attachment and cleans up any associated resources.
  ///
  /// Note that you are *not* required to call [stop] once your attachment fetch operation finishes.
  /// This method primarily exists to allow cancellation of an attachment fetch request
  /// while it is ongoing if the attachment is no longer needed locally on the device.
  void stop() {
    if (isStopped) return;
    _isStopped = true;

    _freeable?.free();

    if (_cancelToken != null) {
      core.dittoCancelResolveAttachment(
        _ditto.ptr,
        _token.idBytes,
        _cancelToken!,
      );
    }

    _ditto.store.removeAttachmentFetcher(this);
  }
}

/// The types of attachment fetch events that can be delivered to an attachment
/// fetcher's callback.
@external
enum AttachmentFetchEventType { completed, progress, deleted }

/// A representation of the events that can occur in relation to an attachment fetch.
///
/// There will be at most one [AttachmentFetchEventCompleted] or [AttachmentFetchEventDeleted] per attachment fetch.
/// There can be many [AttachmentFetchEventProgress] delivered for each attachment fetch.
///
/// [AttachmentFetchEvent]s are delivered to [AttachmentFetcher]s registered via [Store.fetchAttachment].
@external
abstract final class AttachmentFetchEvent {
  final AttachmentFetchEventType type;

  AttachmentFetchEvent._(this.type);
}

/// An attachment fetch event for when the download has completed.
@external
final class AttachmentFetchEventCompleted extends AttachmentFetchEvent {
  final Attachment attachment;

  AttachmentFetchEventCompleted({required this.attachment})
      : super._(AttachmentFetchEventType.completed);
}

/// An attachment fetch event for when the download has progressed but is not yet complete.
@external
final class AttachmentFetchEventProgress extends AttachmentFetchEvent {
  final int totalBytes;
  final int downloadedBytes;

  AttachmentFetchEventProgress({
    required this.totalBytes,
    required this.downloadedBytes,
  }) : super._(AttachmentFetchEventType.progress);
}

/// An attachment fetch event for when the attachment is deleted.
@external
final class AttachmentFetchEventDeleted extends AttachmentFetchEvent {
  AttachmentFetchEventDeleted() : super._(AttachmentFetchEventType.deleted);
}
