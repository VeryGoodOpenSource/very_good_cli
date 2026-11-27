// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'license_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$LicensePayloadToJson(LicensePayload instance) =>
    <String, dynamic>{
      'banned': instance.banned,
      'bannedDependencies': instance.bannedDependencies
          .map((e) => e.toJson())
          .toList(),
    };

Map<String, dynamic> _$BannedDependencyPayloadToJson(
  BannedDependencyPayload instance,
) => <String, dynamic>{
  'package': instance.package,
  'licenses': instance.licenses,
};
