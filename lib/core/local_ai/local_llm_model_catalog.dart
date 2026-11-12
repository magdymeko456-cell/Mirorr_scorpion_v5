import 'dart:convert';

import 'local_model_pack.dart';

class LocalLlmModelCatalog {
  const LocalLlmModelCatalog({required this.version, required this.models});

  final int version;
  final List<LocalLlmModelCatalogEntry> models;

  factory LocalLlmModelCatalog.fromJson(Map<String, dynamic> json) {
    final version = json['catalogVersion'];
    final rawModels = json['models'];
    if (version is! int || version != 1 || rawModels is! List) {
      throw const FormatException('Invalid local LLM catalog.');
    }
    final models = rawModels
        .whereType<Map<String, dynamic>>()
        .map(LocalLlmModelCatalogEntry.fromJson)
        .toList(growable: false);
    if (models.length != rawModels.length) {
      throw const FormatException('Every local LLM catalog entry must be an object.');
    }
    return LocalLlmModelCatalog(version: version, models: models);
  }

  factory LocalLlmModelCatalog.fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Local LLM catalog must be an object.');
    }
    return LocalLlmModelCatalog.fromJson(decoded);
  }
}

class LocalLlmModelCatalogEntry {
  const LocalLlmModelCatalogEntry({
    required this.id,
    required this.displayName,
    required this.kind,
    required this.languageCode,
    required this.version,
    required this.status,
    required this.manifestUri,
    required this.manifestSha256,
    required this.totalBytes,
    required this.sourceName,
    required this.license,
    this.description = '',
  });

  final String id;
  final String displayName;
  final LocalModelKind kind;
  final String languageCode;
  final String version;
  final String status;
  final Uri manifestUri;
  final String manifestSha256;
  final int totalBytes;
  final String sourceName;
  final String license;
  final String description;

  bool get canDownload =>
      status == 'available' &&
      kind == LocalModelKind.storyAi &&
      manifestUri.scheme == 'https';

  factory LocalLlmModelCatalogEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final displayName = json['displayName'];
    final kindValue = json['kind'];
    final languageCode = json['languageCode'];
    final version = json['version'];
    final status = json['status'];
    final manifest = json['manifestUri'];
    final manifestSha256 = json['manifestSha256'];
    final totalBytes = json['totalBytes'];
    final sourceName = json['sourceName'];
    final license = json['license'];
    if (id is! String || !RegExp(r'^[a-z0-9-]+$').hasMatch(id) ||
        displayName is! String || displayName.isEmpty ||
        kindValue is! String || languageCode is! String || languageCode.isEmpty ||
        version is! String || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        status is! String || !const <String>{'available', 'requires_review', 'retired'}.contains(status) ||
        manifest is! String ||
        manifestSha256 is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(manifestSha256) ||
        totalBytes is! int || totalBytes <= 0 ||
        sourceName is! String || sourceName.isEmpty ||
        license is! String || license.isEmpty) {
      throw const FormatException('Invalid local LLM catalog entry.');
    }
    final uri = Uri.tryParse(manifest);
    final kind = LocalModelKind.values.firstWhere(
      (value) => value.name == kindValue,
      orElse: () => throw const FormatException('Unknown local LLM model kind.'),
    );
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Local LLM manifest URI must use HTTPS.');
    }
    return LocalLlmModelCatalogEntry(
      id: id,
      displayName: displayName,
      kind: kind,
      languageCode: languageCode,
      version: version,
      status: status,
      manifestUri: uri,
      manifestSha256: manifestSha256,
      totalBytes: totalBytes,
      sourceName: sourceName,
      license: license,
      description: json['description'] as String? ?? '',
    );
  }
}
