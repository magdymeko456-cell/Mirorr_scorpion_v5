import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/content/github_content_catalog_service.dart';

void main() {
  final packageBytes = Uint8List.fromList(<int>[109, 105, 114, 114, 111, 114]);
  const packageHash = '00154761637ca746c354a6d9cfbf1da1a92e79afa6bb127bb8a1c434e9c73170';

  Map<String, dynamic> availablePackage({String? hash}) => <String, dynamic>{
        'packageId': 'owner-inspiration-ar',
        'version': '1.0.0',
        'order': 10,
        'status': 'available',
        'title': 'تأملات',
        'scope': 'inspiration',
        'language': 'ar',
        'sourceCitation': <String, dynamic>{'name': 'مالك التطبيق'},
        'license': <String, dynamic>{'usage': 'owner-provided-content'},
        'contentPath': 'content_catalog/packages/owner-inspiration-ar-1.0.0.json',
        'contentSha256': hash ?? packageHash,
      };

  test('parses and orders a catalog with an available package', () {
    final catalog = ContentCatalog.fromJson(<String, dynamic>{
      'catalogVersion': 1,
      'releaseRef': 'content-v1.0.0',
      'packages': <Map<String, dynamic>>[
        <String, dynamic>{
          'packageId': 'waiting',
          'order': 20,
          'status': 'requires_review',
          'title': 'قيد المراجعة',
          'scope': 'quran_narratives',
          'language': 'ar',
        },
        availablePackage(),
      ],
    });

    expect(catalog.packages.first.id, 'owner-inspiration-ar');
    expect(catalog.packages.first.canDownload, isTrue);
    expect(catalog.packages.last.canDownload, isFalse);
  });

  test('rejects an available package without a valid SHA-256', () {
    expect(
      () => ContentCatalogPackage.fromJson(availablePackage(hash: 'not-a-hash')),
      throwsFormatException,
    );
  });

  test('rejects an available package without visible source and license metadata', () {
    final missingSource = availablePackage()..remove('sourceCitation');
    final missingLicense = availablePackage()..remove('license');

    expect(
      () => ContentCatalogPackage.fromJson(missingSource),
      throwsFormatException,
    );
    expect(
      () => ContentCatalogPackage.fromJson(missingLicense),
      throwsFormatException,
    );
  });

  test('checks raw package bytes against the catalog hash', () {
    expect(ContentHash.matchesSha256(packageBytes, packageHash), isTrue);
    expect(ContentHash.matchesSha256(packageBytes, '0' * 64), isFalse);
  });

  test('prevents replacing a newer local semantic version', () {
    expect(ContentVersion.compare('1.1.0', '1.0.0'), greaterThan(0));
    expect(ContentVersion.compare('1.0.0', '1.0.0'), 0);
    expect(ContentVersion.compare(null, '1.0.0'), lessThan(0));
  });

  test('uses main for the changing catalog and a release ref for package bytes', () {
    final catalog = ContentCatalog.fromJson(<String, dynamic>{
      'catalogVersion': 1,
      'releaseRef': 'content-v1.0.0',
      'packages': <Map<String, dynamic>>[availablePackage()],
    });
    final service = GitHubContentCatalogService(
      repositoryRawUri: Uri.parse('https://raw.example.test/owner/repository/'),
    );

    expect(service.catalogUri.path, '/owner/repository/main/content_catalog/v1/index.json');
    expect(
      service.packageUriFor(catalog, catalog.packages.single).path,
      '/owner/repository/content-v1.0.0/content_catalog/packages/owner-inspiration-ar-1.0.0.json',
    );
    service.dispose();
  });

  test('catalog payload remains JSON encodable for remote delivery', () {
    expect(jsonEncode(availablePackage()), contains('owner-inspiration-ar'));
  });
}
