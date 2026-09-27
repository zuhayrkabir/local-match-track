// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttachmentToken _$AttachmentTokenFromJson(Map<String, dynamic> json) =>
    AttachmentToken._(
      id: json['id'] as String,
      len: (json['len'] as num).toInt(),
      metadata:
          AttachmentMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AttachmentTokenToJson(AttachmentToken instance) =>
    <String, dynamic>{
      'id': instance.id,
      'len': instance.len,
      'metadata': _attachmentMetadataToJson(instance.metadata),
    };
