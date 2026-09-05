import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/content/content_package_validator.dart';

void main() {
  Map<String, dynamic> validPackage() => <String, dynamic>{
        'schemaVersion': 1,
        'packageId': 'owner-inspiration-ar',
        'version': '1.0.0',
        'title': 'تأملات موثقة',
        'kind': 'inspiration',
        'sourceCitation': <String, dynamic>{
          'name': 'مالك التطبيق',
          'reference': 'owner-submission-2026-08-27',
        },
        'license': <String, dynamic>{
          'usage': 'owner-authorized',
          'rightsHolder': 'مالك التطبيق',
        },
        'createdAt': '2026-08-27T00:00:00Z',
        'stories': <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'kindness',
            'title': 'الرفق',
            'body': 'نص مقدم من مالك التطبيق.',
          },
        ],
      };

  test('accepts a complete compatible stories package', () {
    expect(() => ContentPackageValidator.validate(validPackage()), returnsNormally);
  });

  test('accepts a licensed package with visible attribution in place of a separate rights holder', () {
    final package = validPackage();
    package['license'] = <String, dynamic>{
      'usage': 'CC-BY-SA-4.0',
      'attribution': 'المؤلف والعمل ومساهمو المصدر، CC BY-SA 4.0.',
    };

    expect(() => ContentPackageValidator.validate(package), returnsNormally);
  });

  test('rejects a package with missing visible rights metadata', () {
    final package = validPackage()..remove('license');
    expect(() => ContentPackageValidator.validate(package), throwsFormatException);
  });

  test('rejects a package whose catalog identity does not match', () {
    expect(
      () => ContentPackageValidator.validate(
        validPackage(),
        expectedId: 'different-package',
        expectedVersion: '1.0.0',
      ),
      throwsFormatException,
    );
  });

  test('rejects an empty content payload', () {
    final package = validPackage()..['stories'] = <Map<String, dynamic>>[];
    expect(() => ContentPackageValidator.validate(package), throwsFormatException);
  });
}
