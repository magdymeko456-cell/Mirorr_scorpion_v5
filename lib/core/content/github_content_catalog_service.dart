import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'content_package_validator.dart';
import 'offline_content_storage.dart';

class ContentCatalog {
  const ContentCatalog({
    required this.catalogVersion,
    required this.releaseRef,
    required this.packages,
  });

  final int catalogVersion;
  final String releaseRef;
  final List<ContentCatalogPackage> packages;

  factory ContentCatalog.fromJson(Map<String, dynamic> json) {
    final version = json['catalogVersion'];
    if (version is! int || version != 1) {
      throw const FormatException('Unsupported catalog version.');
    }
    final releaseRef = _requiredString(json, 'releaseRef');
    if (!_safeRef.hasMatch(releaseRef)) {
      throw const FormatException('Invalid release reference.');
    }
    final rawPackages = json['packages'];
    if (rawPackages is! List) {
      throw const FormatException('Catalog packages must be a list.');
    }
    return ContentCatalog(
      catalogVersion: version,
      releaseRef: releaseRef,
      packages: rawPackages
          .whereType<Map<String, dynamic>>()
          .map(ContentCatalogPackage.fromJson)
          .toList()
        ..sort((left, right) => left.order.compareTo(right.order)),
    );
  }
}

class ContentCatalogPackage {
  const ContentCatalogPackage({
    required this.id,
    required this.title,
    required this.scope,
    required this.language,
    required this.order,
    required this.status,
    required this.version,
    required this.sourceName,
    required this.licenseUsage,
    this.contentPath,
    this.contentSha256,
    this.reason,
  });

  final String id;
  final String title;
  final String scope;
  final String language;
  final int order;
  final String status;
  final String? version;
  final String? sourceName;
  final String? licenseUsage;
  final String? contentPath;
  final String? contentSha256;
  final String? reason;

  bool get canDownload =>
      status == 'available' &&
      version != null &&
      contentPath != null &&
      contentSha256 != null;

  factory ContentCatalogPackage.fromJson(Map<String, dynamic> json) {
    final status = _requiredString(json, 'status');
    if (!const <String>{'available', 'requires_review', 'retired'}
        .contains(status)) {
      throw const FormatException('Unknown package status.');
    }
    final sourceCitation = json['sourceCitation'] as Map<String, dynamic>?;
    final license = json['license'] as Map<String, dynamic>?;
    final contentPath = json['contentPath'] as String?;
    final contentSha256 = json['contentSha256'] as String?;
    final version = json['version'] as String?;
    if (status == 'available') {
      if (version == null ||
          !_semanticVersion.hasMatch(version) ||
          contentPath == null ||
          !_safePackagePath.hasMatch(contentPath) ||
          contentSha256 == null ||
          !_sha256.hasMatch(contentSha256) ||
          !_hasAttribution(sourceCitation) ||
          !_hasLicenseUsage(license)) {
        throw const FormatException('Available package is missing integrity metadata.');
      }
    }
    return ContentCatalogPackage(
      id: _requiredString(json, 'packageId'),
      title: _requiredString(json, 'title'),
      scope: _requiredString(json, 'scope'),
      language: _requiredString(json, 'language'),
      order: json['order'] is int ? json['order'] as int : 9999,
      status: status,
      version: version,
      sourceName: sourceCitation?['name'] as String? ??
          sourceCitation?['work'] as String? ??
          sourceCitation?['author'] as String?,
      licenseUsage: license?['usage'] as String?,
      contentPath: contentPath,
      contentSha256: contentSha256,
      reason: json['reason'] as String?,
    );
  }
}

class ContentCatalogLoadResult {
  const ContentCatalogLoadResult._({this.catalog, required this.message});

  const ContentCatalogLoadResult.success(ContentCatalog catalog)
      : this._(catalog: catalog, message: 'تم تحميل فهرس المصادر.');

  const ContentCatalogLoadResult.failure(String message)
      : this._(message: message);

  final ContentCatalog? catalog;
  final String message;

  bool get isSuccess => catalog != null;
}

class ContentPackageDownloadResult {
  const ContentPackageDownloadResult._({required this.success, required this.message});

  const ContentPackageDownloadResult.success(String message)
      : this._(success: true, message: message);

  const ContentPackageDownloadResult.failure(String message)
      : this._(success: false, message: message);

  final bool success;
  final String message;
}

class GitHubContentCatalogService {
  GitHubContentCatalogService({
    http.Client? client,
    Uri? repositoryRawUri,
    this.catalogRef = 'main',
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _repositoryRawUri = repositoryRawUri ?? _defaultRepositoryRawUri;

  static final Uri _defaultRepositoryRawUri = Uri.parse(
    'https://raw.githubusercontent.com/magdymeko456-cell/mirror_scorpion_v4/',
  );

  final http.Client _client;
  final bool _ownsClient;
  final Uri _repositoryRawUri;
  final String catalogRef;

  Uri get catalogUri =>
      _repositoryRawUri.resolve('$catalogRef/content_catalog/v1/index.json');

  Uri packageUriFor(ContentCatalog catalog, ContentCatalogPackage package) =>
      _repositoryRawUri.resolve('${catalog.releaseRef}/${package.contentPath}');

  Future<ContentCatalogLoadResult> fetchCatalog() async {
    try {
      final response = await _client.get(catalogUri);
      if (response.statusCode != 200) {
        return ContentCatalogLoadResult.failure(
          'تعذر الوصول إلى فهرس المصادر (HTTP ${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        return const ContentCatalogLoadResult.failure('صيغة فهرس المصادر غير صالحة.');
      }
      return ContentCatalogLoadResult.success(ContentCatalog.fromJson(decoded));
    } on FormatException {
      return const ContentCatalogLoadResult.failure(
        'تعذر التحقق من بنية فهرس المصادر.',
      );
    } catch (_) {
      return const ContentCatalogLoadResult.failure(
        'تعذر تحميل فهرس المصادر. تحقق من اتصال الإنترنت ثم أعد المحاولة.',
      );
    }
  }

  Future<ContentPackageDownloadResult> downloadPackage({
    required ContentCatalog catalog,
    required ContentCatalogPackage package,
    required OfflineContentStorage storage,
  }) async {
    if (!package.canDownload) {
      return const ContentPackageDownloadResult.failure(
        'هذه الحزمة ليست متاحة للتنزيل قبل اكتمال مراجعة المصدر والحقوق.',
      );
    }
    try {
      final response = await _client.get(packageUriFor(catalog, package));
      if (response.statusCode != 200) {
        return ContentPackageDownloadResult.failure(
          'تعذر تنزيل الحزمة (HTTP ${response.statusCode}).',
        );
      }
      final bytes = response.bodyBytes;
      if (!ContentHash.matchesSha256(bytes, package.contentSha256!)) {
        return const ContentPackageDownloadResult.failure(
          'رُفضت الحزمة لأن هاش SHA-256 لا يطابق الفهرس.',
        );
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return const ContentPackageDownloadResult.failure(
          'رُفضت الحزمة لأن ملف JSON لا يمثل حزمة محتوى.',
        );
      }
      ContentPackageValidator.validate(
        decoded,
        expectedId: package.id,
        expectedVersion: package.version,
      );
      final existing = await storage.packageById(package.id);
      if (existing != null &&
          ContentVersion.compare(existing.version, package.version!) > 0) {
        return const ContentPackageDownloadResult.failure(
          'لن يستبدل التطبيق نسخة محلية أحدث بإصدار أقدم من الفهرس.',
        );
      }
      await storage.savePackageBytes(id: package.id, bytes: bytes);
      return ContentPackageDownloadResult.success(
        'تم تنزيل «${package.title}» والتحقق من سلامتها وحفظها محلياً.',
      );
    } on FormatException {
      return const ContentPackageDownloadResult.failure(
        'رُفضت الحزمة لأن بيانات المصدر أو الترخيص أو بنية المحتوى غير مكتملة.',
      );
    } catch (_) {
      return const ContentPackageDownloadResult.failure(
        'تعذر تنزيل الحزمة أو حفظها. تحقق من الشبكة ومساحة الجهاز ثم أعد المحاولة.',
      );
    }
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class ContentHash {
  const ContentHash._();

  static bool matchesSha256(Uint8List bytes, String expected) =>
      sha256.convert(bytes).toString() == expected.toLowerCase();
}

class ContentVersion {
  const ContentVersion._();

  static int compare(String? local, String incoming) {
    if (local == null || !_semanticVersion.hasMatch(local)) return -1;
    final localParts = local.split('.').map(int.parse).toList();
    final incomingParts = incoming.split('.').map(int.parse).toList();
    for (var index = 0; index < 3; index++) {
      final difference = localParts[index].compareTo(incomingParts[index]);
      if (difference != 0) return difference;
    }
    return 0;
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $key.');
  }
  return value;
}

bool _hasAttribution(Map<String, dynamic>? citation) {
  if (citation == null) return false;
  return <String>['name', 'work', 'author']
      .any((key) => citation[key] is String && (citation[key] as String).trim().isNotEmpty);
}

bool _hasLicenseUsage(Map<String, dynamic>? license) {
  final usage = license?['usage'];
  return usage is String && usage.trim().isNotEmpty;
}

final _safeRef = RegExp(r'^[A-Za-z0-9._-]+$');
final _safePackagePath = RegExp(r'^content_catalog/packages/[a-z0-9-]+-[0-9]+\.[0-9]+\.[0-9]+\.json$');
final _sha256 = RegExp(r'^[a-f0-9]{64}$');
final _semanticVersion = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$');
