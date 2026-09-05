import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'content_package_validator.dart';

/// مساحة دائمة لحزم المحتوى التي يختار المستخدم تنزيلها أو استيرادها.
/// لا تقوم هذه الخدمة بتنزيل أي شيء في الخلفية، ولا تُخزّن محتوى دينياً
/// أو صوتياً من دون إجراء صريح من المستخدم.
class OfflineContentStorage {
  const OfflineContentStorage();

  Future<Directory> packagesDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/mirror_scorpion/content_packs');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<List<OfflinePackageRecord>> listPackages() async {
    final directory = await packagesDirectory();
    final files = directory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList();
    final records = <OfflinePackageRecord>[];
    for (final file in files) {
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is! Map<String, dynamic>) continue;
        ContentPackageValidator.validate(decoded);
        records.add(OfflinePackageRecord.fromJson(decoded, path: file.path));
      } on FormatException {
        // ملف غير متوافق لا يُعرض كحزمة صالحة.
      }
    }
    records.sort((left, right) => left.title.compareTo(right.title));
    return records;
  }

  Future<OfflinePackageRecord?> packageById(String id) async {
    final packages = await listPackages();
    for (final package in packages) {
      if (package.id == id) return package;
    }
    return null;
  }

  Future<File> savePackage({
    required String id,
    required Map<String, dynamic> content,
  }) => savePackageBytes(
        id: id,
        bytes: Uint8List.fromList(utf8.encode(jsonEncode(content))),
      );

  Future<File> savePackageBytes({
    required String id,
    required Uint8List bytes,
  }) async {
    _validateId(id);
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Content package must be a JSON object.');
    }
    ContentPackageValidator.validate(decoded, expectedId: id);
    final directory = await packagesDirectory();
    final target = File('${directory.path}/$id.json');
    final temporary = File('${target.path}.tmp');
    await temporary.writeAsBytes(bytes, flush: true);
    try {
      await temporary.rename(target.path);
    } on FileSystemException {
      final backup = File('${target.path}.backup');
      if (await backup.exists()) await backup.delete();
      if (await target.exists()) await target.rename(backup.path);
      try {
        await temporary.rename(target.path);
      } on FileSystemException {
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(target.path);
        }
        rethrow;
      } finally {
        if (await target.exists() && await backup.exists()) {
          await backup.delete();
        }
      }
    }
    return target;
  }

  Future<bool> deletePackage(String id) async {
    _validateId(id);
    final directory = await packagesDirectory();
    final target = File('${directory.path}/$id.json');
    if (!await target.exists()) return false;
    final pendingDeletion = File('${target.path}.deleting');
    if (await pendingDeletion.exists()) await pendingDeletion.delete();
    await target.rename(pendingDeletion.path);
    try {
      await pendingDeletion.delete();
      return true;
    } on FileSystemException {
      if (await pendingDeletion.exists() && !await target.exists()) {
        await pendingDeletion.rename(target.path);
      }
      rethrow;
    }
  }

  void _validateId(String id) {
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
      throw ArgumentError.value(
        id,
        'id',
        'Package ID must be lowercase letters, digits, and hyphens only.',
      );
    }
  }
}

class OfflinePackageRecord {
  const OfflinePackageRecord({
    required this.id,
    required this.title,
    required this.version,
    required this.sourceName,
    required this.licenseUsage,
    required this.path,
  });

  final String id;
  final String title;
  final String? version;
  final String? sourceName;
  final String? licenseUsage;
  final String path;

  factory OfflinePackageRecord.fromJson(
    Map<String, dynamic> json, {
    required String path,
  }) {
    final sourceCitation = json['sourceCitation'] as Map<String, dynamic>?;
    final license = json['license'];
    return OfflinePackageRecord(
      id: json['packageId'] as String? ?? json['id'] as String? ?? 'unknown',
      title: json['title'] as String? ??
          json['packageId'] as String? ??
          'حزمة محتوى',
      version: json['version'] as String?,
      sourceName: sourceCitation?['name'] as String? ?? json['source'] as String?,
      licenseUsage: license is Map<String, dynamic>
          ? license['usage'] as String?
          : license as String?,
      path: path,
    );
  }
}
