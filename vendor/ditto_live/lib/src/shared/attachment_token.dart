import "dart:typed_data";

import "package:meta/meta.dart";

import "../../ditto_live.dart";
import "package:equatable/equatable.dart";

import "package:json_annotation/json_annotation.dart";

import "../analysis/annotations.dart";
import "../attachment.dart";
import "../bridge/bridge.dart" as core;

part "attachment_token.g.dart";

@internal
const privateMakeAttachmentToken = AttachmentToken._;

/// An [AttachmentToken] can be passed in the `arguments` field of
/// [Store.execute] to insert an attachment into a document, or used with
/// [Store.fetchAttachment] to retrieve the attachment data.
@JsonSerializable(constructor: "_")
@external
final class AttachmentToken with EquatableMixin {
  late final Uint8List _idBytes;

  /// The unique identifier for the attachment.
  final String id;

  /// The size of the attachment in bytes.
  final int len;

  /// The user-defined metadata associated with the attachment.
  @JsonKey(
    fromJson: AttachmentMetadata.fromJson,
    toJson: _attachmentMetadataToJson,
  )
  final AttachmentMetadata metadata;

  AttachmentToken._({
    required this.id,
    required this.len,
    required this.metadata,
  }) {
    _idBytes = _ffiDecodeId(id);
  }

  /// @nodoc
  Map<String, dynamic> toJson() => attachmentToJson(this);

  /// @nodoc
  Map<String, dynamic> toCbor() => toJson();

  /// @nodoc
  factory AttachmentToken.fromJson(Map<String, dynamic> json) =>
      _$AttachmentTokenFromJson(json);

  /// @nodoc
  @override
  List<Object?> get props => [id, len, metadata];
}

Map<String, dynamic> _attachmentMetadataToJson(AttachmentMetadata metadata) =>
    metadata.metadata;

@internal
extension PrivateAttachmentTokenBytesExt on AttachmentToken {
  Uint8List get idBytes => _idBytes;
}

Uint8List _ffiDecodeId(String base64UnpaddedId) => core
    .dittoFfiTryBase64Decode(
      base64UnpaddedId,
      core.CPBase64PaddingMode.unpadded,
    )
    .extract();
