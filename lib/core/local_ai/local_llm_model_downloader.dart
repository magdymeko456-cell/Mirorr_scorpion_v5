import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'local_llm_model_catalog.dart';
import 'local_model_manager.dart';
import 'local_model_pack.dart';

class LocalLlmDownloadProgress {
  const LocalLlmDownloadProgress({
    required this.modelId,
    required this.filePath,
    required this.completedBytes,
    required this.totalBytes,
  });

  final String modelId;
  final String filePath;
  final int completedBytes;
  final int totalBytes;

  double get fraction => totalBytes <= 0
      ? 0
      : (completedBytes / totalBytes).clamp(0, 1).toDouble();
}

class LocalLlmDownloadController {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

class LocalLlmDownloadResult {
  const LocalLlmDownloadResult._({
    required this.success,
    required this.cancelled,
    required this.message,
    this.manifest,
  });

  const LocalLlmDownloadResult.success(LocalModelPackManifest manifest)
      : this._(
          success: true,
          cancelled: false,
          message: 'Local model downloaded and verified.',
          manifest: manifest,
        );

  const LocalLlmDownloadResult.failure(String message)
      : this._(success: false, cancelled: false, message: message);

  const LocalLlmDownloadResult.cancelled()
      : this._(
          success: false,
          cancelled: true,
          message: 'Local model download was cancelled.',
        );

  final bool success;
  final bool cancelled;
  final String message;
  final LocalModelPackManifest? manifest;
}

/// Downloads one model into a staging directory and publishes it only after
/// every file and the manifest pass integrity checks. A failed download cannot
/// leave a half-installed model that the runtime might accidentally open.
class LocalLlmModelDownloader {
  LocalLlmModelDownloader({
    http.Client? client,
    LocalModelManager? modelManager,
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _modelManager = modelManager ?? const LocalModelManager();

  final http.Client _client;
  final bool _ownsClient;
  final LocalModelManager _modelManager;

  Future<LocalLlmDownloadResult> download({
    required LocalLlmModelCatalogEntry entry,
    LocalLlmDownloadController? controller,
    void Function(LocalLlmDownloadProgress progress)? onProgress,
  }) async {
    final token = controller ?? LocalLlmDownloadController();
    if (!entry.canDownload) {
      return const LocalLlmDownloadResult.failure(
        'This model is not approved for download yet.',
      );
    }
    Directory? staging;
    try {
      final manifestResponse = await _client.get(entry.manifestUri);
      if (manifestResponse.statusCode != 200) {
        return LocalLlmDownloadResult.failure(
          'Manifest download failed (HTTP ${manifestResponse.statusCode}).',
        );
      }
      final manifestBytes = manifestResponse.bodyBytes;
      if (!_matchesSha256(manifestBytes, entry.manifestSha256)) {
        return const LocalLlmDownloadResult.failure(
          'The model manifest failed SHA-256 verification.',
        );
      }
      final manifest = LocalModelPackManifest.fromJsonString(
        utf8.decode(manifestBytes),
      );
      if (manifest.id != entry.id || manifest.version != entry.version ||
          manifest.kind != entry.kind) {
        return const LocalLlmDownloadResult.failure(
          'The downloaded manifest does not match the catalog entry.',
        );
      }
      if (token.isCancelled) return const LocalLlmDownloadResult.cancelled();

      final target = await _modelManager.packDirectory(entry.id);
      staging = Directory('${target.path}.staging');
      if (await staging.exists()) await staging.delete(recursive: true);
      await staging.create(recursive: true);
      var completedBytes = 0;
      for (final fileEntry in manifest.files) {
        if (token.isCancelled) return const LocalLlmDownloadResult.cancelled();
        final output = File('${staging.path}/${fileEntry.relativePath}');
        await output.parent.create(recursive: true);
        final uri = entry.manifestUri.resolve(fileEntry.relativePath);
        final request = http.Request('GET', uri);
        final response = await _client.send(request);
        if (response.statusCode != 200) {
          return LocalLlmDownloadResult.failure(
            'Model file download failed (HTTP ${response.statusCode}).',
          );
        }
        final sink = output.openWrite();
        var fileBytes = 0;
        try {
          await for (final chunk in response.stream) {
            if (token.isCancelled) return const LocalLlmDownloadResult.cancelled();
            sink.add(chunk);
            fileBytes += chunk.length;
            onProgress?.call(LocalLlmDownloadProgress(
              modelId: entry.id,
              filePath: fileEntry.relativePath,
              completedBytes: completedBytes + fileBytes,
              totalBytes: manifest.files.fold<int>(
                0,
                (sum, value) => sum + value.bytes,
              ),
            ));
          }
        } finally {
          await sink.close();
        }
        if (fileBytes != fileEntry.bytes ||
            !_matchesSha256(await output.readAsBytes(), fileEntry.sha256)) {
          return LocalLlmDownloadResult.failure(
            'Model file ${fileEntry.relativePath} failed integrity verification.',
          );
        }
        completedBytes += fileBytes;
      }
      await File('${staging.path}/manifest.json').writeAsBytes(manifestBytes);
      if (token.isCancelled) return const LocalLlmDownloadResult.cancelled();

      final backup = Directory('${target.path}.backup');
      if (await backup.exists()) await backup.delete(recursive: true);
      if (await target.exists()) await target.rename(backup.path);
      try {
        await staging.rename(target.path);
        if (await backup.exists()) await backup.delete(recursive: true);
      } catch (_) {
        if (!await target.exists() && await backup.exists()) {
          await backup.rename(target.path);
        }
        rethrow;
      }
      staging = null;
      return LocalLlmDownloadResult.success(manifest);
    } on FormatException catch (error) {
      return LocalLlmDownloadResult.failure(error.message);
    } on IOException catch (error) {
      return LocalLlmDownloadResult.failure('Local model download failed: ${error.message}');
    } catch (error) {
      return LocalLlmDownloadResult.failure('Local model download failed: $error');
    } finally {
      if (staging != null && await staging.exists()) {
        await staging.delete(recursive: true);
      }
    }
  }

  static bool _matchesSha256(List<int> bytes, String expected) =>
      sha256.convert(bytes).toString() == expected.toLowerCase();

  void dispose() {
    if (_ownsClient) _client.close();
  }
}
