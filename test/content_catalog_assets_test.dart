import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/content/github_content_catalog_service.dart';

void main() {
  test('the published Fawaid package matches its catalog SHA-256', () async {
    final catalogFile = File('content_catalog/v1/index.json');
    final catalogJson = jsonDecode(await catalogFile.readAsString())
        as Map<String, dynamic>;
    final catalog = ContentCatalog.fromJson(catalogJson);
    final package = catalog.packages.singleWhere(
      (item) => item.id == 'ibn-al-qayyim-al-fawaid-ar',
    );
    final packageFile = File(package.contentPath!);

    expect(package.canDownload, isTrue);
    expect(await packageFile.exists(), isTrue);
    expect(
      ContentHash.matchesSha256(
        await packageFile.readAsBytes(),
        package.contentSha256!,
      ),
      isTrue,
    );
  });
}
