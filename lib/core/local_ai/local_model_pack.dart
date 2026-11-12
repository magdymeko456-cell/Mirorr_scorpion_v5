import 'dart:convert';

/// Supported local model families. Each family is installed and verified
/// independently so a user can keep only the languages they need.
enum LocalModelKind {
  speechRecognition,
  voiceTts,
  translation,
  ocr,
  storyAi,
}

class LocalModelFile {
  const LocalModelFile({
    required this.relativePath,
    required this.sha256,
    required this.bytes,
  });

  final String relativePath;
  final String sha256;
  final int bytes;

  factory LocalModelFile.fromJson(Map<String, dynamic> json) {
    final path = json['path'];
    final sha = json['sha256'];
    final bytes = json['bytes'];
    if (path is! String || path.isEmpty ||
        sha is! String || !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha) ||
        bytes is! int || bytes <= 0 || path.startsWith('/') || path.contains('..')) {
      throw const FormatException('Invalid local model file manifest.');
    }
    return LocalModelFile(relativePath: path, sha256: sha, bytes: bytes);
  }

  Map<String, dynamic> toJson() => {
        'path': relativePath,
        'sha256': sha256,
        'bytes': bytes,
      };
}

class LocalModelPackManifest {
  const LocalModelPackManifest({
    required this.id,
    required this.kind,
    required this.languageCode,
    required this.version,
    required this.engine,
    required this.files,
    this.displayName = '',
    this.minimumRamBytes = 0,
    this.minimumFreeStorageBytes = 0,
    this.supportedAbis = const <String>[],
    this.entryPoint,
    this.contextTokens = 0,
  });

  final String id;
  final LocalModelKind kind;
  final String languageCode;
  final String version;
  final String engine;
  final List<LocalModelFile> files;
  final String displayName;
  final int minimumRamBytes;
  final int minimumFreeStorageBytes;
  final List<String> supportedAbis;
  final String? entryPoint;
  final int contextTokens;

  factory LocalModelPackManifest.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final kindValue = json['kind'];
    final language = json['languageCode'];
    final version = json['version'];
    final engine = json['engine'];
    final rawFiles = json['files'];
    final minimumRamBytes = json['minimumRamBytes'] ?? 0;
    final minimumFreeStorageBytes = json['minimumFreeStorageBytes'] ?? 0;
    final rawAbis = json['supportedAbis'] ?? const <dynamic>[];
    final entryPoint = json['entryPoint'];
    final contextTokens = json['contextTokens'] ?? 0;
    if (id is! String || !RegExp(r'^[a-z0-9-]+$').hasMatch(id) ||
        kindValue is! String || language is! String || language.isEmpty ||
        version is! String || engine is! String || rawFiles is! List ||
        rawFiles.isEmpty || minimumRamBytes is! int || minimumRamBytes < 0 ||
        minimumFreeStorageBytes is! int || minimumFreeStorageBytes < 0 ||
        rawAbis is! List || !rawAbis.every((value) => value is String && value.isNotEmpty) ||
        (entryPoint != null && (entryPoint is! String || entryPoint.isEmpty)) ||
        contextTokens is! int || contextTokens < 0) {
      throw const FormatException('Invalid local model pack manifest.');
    }
    final kind = LocalModelKind.values.firstWhere(
      (value) => value.name == kindValue,
      orElse: () => throw const FormatException('Unknown local model kind.'),
    );
    final files = rawFiles
        .whereType<Map<String, dynamic>>()
        .map(LocalModelFile.fromJson)
        .toList(growable: false);
    if (files.length != rawFiles.length) {
      throw const FormatException('Every local model file must be an object.');
    }
    return LocalModelPackManifest(
      id: id,
      kind: kind,
      languageCode: language,
      version: version,
      engine: engine,
      displayName: json['displayName'] as String? ?? '',
      minimumRamBytes: minimumRamBytes,
      minimumFreeStorageBytes: minimumFreeStorageBytes,
      supportedAbis: rawAbis.cast<String>().toList(growable: false),
      entryPoint: entryPoint as String?,
      contextTokens: contextTokens,
      files: files,
    );
  }

  factory LocalModelPackManifest.fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Local model manifest must be an object.');
    }
    return LocalModelPackManifest.fromJson(decoded);
  }
}
