import "package:equatable/equatable.dart";

import "../analysis/annotations.dart";

/// Represents metadata for an attachment, defined as a key-value map.
@external
final class AttachmentMetadata with EquatableMixin {
  final Map<String, String> metadata;

  AttachmentMetadata(this.metadata);

  factory AttachmentMetadata.fromJson(Map<String, dynamic> json) =>
      AttachmentMetadata(
        json.map((key, value) => MapEntry(key, value as String)),
      );

  @override
  List<Object?> get props => [metadata];
}
