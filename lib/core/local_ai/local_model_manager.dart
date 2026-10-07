import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'local_model_pack.dart';

enum LocalModelPackState { missing, incomplete, verified, invalid }

class LocalModelPackStatus {
  const LocalModelPackStatus({
    required this.state,
    required this.directory,
    this.manifest,
    this.message,
  });

  final LocalModelPackState state;
  final Directory directory;
  final LocalModelPackManifest? manifest;
  final String? message;

  bool get isReady => state == LocalModelPackState.verified;
}

/// Central storage and integrity gate for all on-device model families.
///
/// A model is never considered usable merely because its directory exists:
/// every file declared by manifest.json must exist with the expected size and
/// SHA-256. Installation code can therefore share the same gate for Whisper,
/// TTS, translation, OCR, and Story AI packs.
class LocalModelManager {
  const LocalModelManager();

  Future<Directory> rootDirectory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/mirror_scorpion/local_models');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<Directory> packDirectory(String id) async {
    if (!RegExp(r'^[a-z0-9-]+$').hasMatch(id)) {
      throw ArgumentError.value(id, 'id', 'Invalid local model pack id.');
    }
    return Directory('${(await rootDirectory()).path}/$id');
  }

  Future<LocalModelPackStatus> inspect(String id) async {
    final directory = await packDirectory(id);
    if (!await directory.exists()) {
      return LocalModelPackStatus(
        state: LocalModelPackState.missing,
        directory: directory,
      );
    }
    final manifestFile = File('${directory.path}/manifest.json');
    if (!await manifestFile.exists()) {
      return LocalModelPackStatus(
        state: LocalModelPackState.incomplete,
        directory: directory,
        message: 'manifest.json is missing.',
      );
    }
    try {
      final manifest = LocalModelPackManifest.fromJsonString(
        await manifestFile.readAsString(),
      );
      if (manifest.id != id) {
        return LocalModelPackStatus(
          state: LocalModelPackState.invalid,
          directory: directory,
          manifest: manifest,
          message: 'Manifest id does not match its directory.',
        );
      }
      for (final entry in manifest.files) {
        final file = File('${directory.path}/${entry.relativePath}');
        if (!await file.exists() || await file.length() != entry.bytes) {
          return LocalModelPackStatus(
            state: LocalModelPackState.incomplete,
            directory: directory,
            manifest: manifest,
            message: 'A declared model file is missing or incomplete.',
          );
        }
        if (!await _matchesSha256(file, entry.sha256)) {
          return LocalModelPackStatus(
            state: LocalModelPackState.invalid,
            directory: directory,
            manifest: manifest,
            message: 'A declared model file failed SHA-256 verification.',
          );
        }
      }
      return LocalModelPackStatus(
        state: LocalModelPackState.verified,
        directory: directory,
        manifest: manifest,
      );
    } on FormatException catch (error) {
      return LocalModelPackStatus(
        state: LocalModelPackState.invalid,
        directory: directory,
        message: error.message,
      );
    } on FileSystemException catch (error) {
      return LocalModelPackStatus(
        state: LocalModelPackState.invalid,
        directory: directory,
        message: error.message,
      );
    }
  }

  Future<bool> deletePack(String id) async {
    final directory = await packDirectory(id);
    if (!await directory.exists()) return false;
    final deleting = Directory('${directory.path}.deleting');
    if (await deleting.exists()) await deleting.delete(recursive: true);
    await directory.rename(deleting.path);
    try {
      await deleting.delete(recursive: true);
      return true;
    } catch (_) {
      if (!await directory.exists() && await deleting.exists()) {
        await deleting.rename(directory.path);
      }
      rethrow;
    }
  }

  static Future<bool> _matchesSha256(File file, String expected) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString() == expected.toLowerCase();
  }
}
