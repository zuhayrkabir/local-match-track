import "dart:convert";
import "dart:typed_data";

import "package:meta/meta.dart";

import "analysis/annotations.dart";
import "shared/attachment_metadata.dart";
import "shared/attachment_token.dart";

import "bridge/bridge.dart" as core;
import "ditto.dart";
import "store/store.dart";

@internal
Attachment privateMakeAttachment(
  core.CPPointer<core.CPAttachmentHandle> ptr,
  Ditto ditto,
  AttachmentToken token,
) =>
    Attachment._(ptr, ditto, token);

/// An attachment which can be used to insert the associated data into a
/// document at a specific key-path. Instances of this class cannot not be
/// created directly, instead use the [Store.newAttachment] and
/// [Store.fetchAttachment] methods.
@external
interface class Attachment {
  Attachment._(this._ptr, this._ditto, this.token);

  final core.CPPointer<core.CPAttachmentHandle> _ptr;

  final Ditto _ditto;

  final AttachmentToken token;

  /// The unique identifier for the attachment.
  String get id => token.id;

  /// The size of the attachment in bytes.
  int get len => token.len;

  /// The user-defined metadata associated with the attachment.
  AttachmentMetadata get metadata => token.metadata;

  /// Returns the binary data of the attachment as a [Uint8List].
  Future<Uint8List> get data async =>
      core.dittoGetCompleteAttachmentData(_ditto.ptr, _ptr).extract();

  /// Copies the attachment to a specified file path.
  ///
  /// This method is platform-specific and may throw if the operation is unsupported on the current platform.
  Future<void> copyToPath(String destination) async {
    final source = core.dittoGetCompleteAttachmentPath(_ditto.ptr, _ptr);
    await core.utilFileCopy(source, destination);
  }

  /// @nodoc
  Map<String, dynamic> toJson() => attachmentToJson(token);

  /// @nodoc
  Map<String, dynamic> toCbor() => toJson();
}

/// Use the special internal representation to serialize an attachment to json here.
///
/// Also used by [AttachmentToken.toJson]
@internal
Map<String, dynamic> attachmentToJson(
  AttachmentToken a,
) {
  // Hack: we don't have access to ffi headers here, so we hardcode
  // the value of this enum
  const dittoCrdtTypeAttachmentDiscriminant = 2;
  return {
    "_ditto_internal_type_jkb12973t4b": dittoCrdtTypeAttachmentDiscriminant,
    "_id": _prepareId(a.id),
    "_len": a.len,
    "_meta": a.metadata.metadata,
  };
}

Uint8List _prepareId(String id) {
  final paddingLength = (4 - (id.length % 4)) % 4;
  final paddedInput = id.padRight(id.length + paddingLength, "=");
  return base64Url.decode(paddedInput);
}
