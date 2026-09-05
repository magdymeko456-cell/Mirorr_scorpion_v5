import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WhisperModelDescriptor {
  const WhisperModelDescriptor({
    required this.fileName,
    required this.uri,
    required this.expectedBytes,
    required this.sha256,
  });

  static final baseMultilingual = WhisperModelDescriptor(
    fileName: 'ggml-base.bin',
    uri: Uri.parse('https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin'),
    expectedBytes: 147951465,
    sha256: '60ed5bc3dd14eea856493d334349b405782ddcaf0028d4b5df4088345fba2efe',
  );

  final String fileName;
  final Uri uri;
  final int expectedBytes;
  final String sha256;
}

class WhisperModelInstallResult {
  const WhisperModelInstallResult._({required this.message, this.file});
  const WhisperModelInstallResult.success(File file)
      : this._(message: 'تم تنزيل نموذج التفريغ والتحقق من SHA-256 وحفظه محلياً.', file: file);
  const WhisperModelInstallResult.existing(File file)
      : this._(message: 'نموذج التفريغ المحلي موجود وتم التحقق من بصمته.', file: file);
  const WhisperModelInstallResult.failure(String message) : this._(message: message);

  final String message;
  final File? file;
  bool get isSuccess => file != null;
}

typedef WhisperModelDownloadProgress = void Function(int received, int expected);

/// لا تستدعى دالة التنزيل هذه إلا بعد موافقة ظاهرة من المستخدم في واجهة اختيار
/// الملف. لا تقبل ملفاً نهائياً قبل مطابقة الحجم وSHA-256.
class WhisperModelInstaller {
  WhisperModelInstaller({http.Client? client})
      : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  Future<Directory> _directory() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/mirror_scorpion/whisper_models');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> modelFile(WhisperModelDescriptor descriptor) async =>
      File('${(await _directory()).path}/${descriptor.fileName}');

  Future<File?> verifiedInstalledModel(WhisperModelDescriptor descriptor) async {
    final file = await modelFile(descriptor);
    if (!await file.exists() || await file.length() != descriptor.expectedBytes) return null;
    return await _matchesSha256(file, descriptor.sha256) ? file : null;
  }

  Future<WhisperModelInstallResult> downloadAfterUserApproval({
    required WhisperModelDescriptor descriptor,
    WhisperModelDownloadProgress? onProgress,
  }) async {
    final present = await verifiedInstalledModel(descriptor);
    if (present != null) return WhisperModelInstallResult.existing(present);
    File? partial;
    try {
      final target = await modelFile(descriptor);
      final downloadFile = File('${target.path}.part');
      partial = downloadFile;
      if (await downloadFile.exists()) await downloadFile.delete();
      final response = await _client.send(http.Request('GET', descriptor.uri));
      if (response.statusCode != HttpStatus.ok) {
        return WhisperModelInstallResult.failure('تعذر تنزيل نموذج التفريغ (HTTP ${response.statusCode}).');
      }
      var received = 0;
      final sink = downloadFile.openWrite();
      try {
        await for (final chunk in response.stream) {
          received += chunk.length;
          if (received > descriptor.expectedBytes) throw const FileSystemException('Oversized model.');
          sink.add(chunk);
          onProgress?.call(received, descriptor.expectedBytes);
        }
      } finally {
        await sink.close();
      }
      if (received != descriptor.expectedBytes || !await _matchesSha256(downloadFile, descriptor.sha256)) {
        return const WhisperModelInstallResult.failure('رُفض نموذج التفريغ لأن الحجم أو SHA-256 لا يطابق المصدر المعلن.');
      }
      if (await target.exists()) await target.delete();
      await downloadFile.rename(target.path);
      partial = null;
      return WhisperModelInstallResult.success(target);
    } on SocketException {
      return const WhisperModelInstallResult.failure('تعذر تنزيل نموذج التفريغ. تحقق من اتصال الإنترنت ثم أعد المحاولة.');
    } on FileSystemException {
      return const WhisperModelInstallResult.failure('تعذر حفظ نموذج التفريغ. تحقق من المساحة الحرة ثم أعد المحاولة.');
    } catch (_) {
      return const WhisperModelInstallResult.failure('تعذر تنزيل نموذج التفريغ أو التحقق من سلامته.');
    } finally {
      if (partial != null && await partial.exists()) await partial.delete();
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }

  static bool isSha256(String value) => RegExp(r'^[a-f0-9]{64}$').hasMatch(value);

  static Future<bool> _matchesSha256(File file, String expected) async =>
      (await sha256.bind(file.openRead()).first).toString() == expected.toLowerCase();
}
