/// يتحقق من غلاف حزمة المحتوى قبل الحفظ المحلي. لا يثبت هذا صحة النص أو
/// حقوقه بذاته؛ لكنه يمنع عرض أو حفظ حزمة ناقصة المصدر أو الترخيص أو الهوية.
class ContentPackageValidator {
  const ContentPackageValidator._();

  static const _allowedKinds = <String>{
    'stories',
    'inspiration',
    'language-data',
  };
  static final _packageId = RegExp(r'^[a-z0-9-]+$');
  static final _semanticVersion = RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$');

  static void validate(
    Map<String, dynamic> package, {
    String? expectedId,
    String? expectedVersion,
  }) {
    if (package['schemaVersion'] != 1) {
      throw const FormatException('Unsupported content package schema.');
    }
    final packageId = _requiredString(package, 'packageId');
    if (!_packageId.hasMatch(packageId)) {
      throw const FormatException('Invalid content package ID.');
    }
    if (expectedId != null && packageId != expectedId) {
      throw const FormatException('Content package ID does not match its catalog.');
    }
    final version = _requiredString(package, 'version');
    if (!_semanticVersion.hasMatch(version)) {
      throw const FormatException('Invalid content package version.');
    }
    if (expectedVersion != null && version != expectedVersion) {
      throw const FormatException('Content package version does not match its catalog.');
    }
    final title = _requiredString(package, 'title');
    if (title.length > 120) {
      throw const FormatException('Content package title is too long.');
    }
    final kind = _requiredString(package, 'kind');
    if (!_allowedKinds.contains(kind)) {
      throw const FormatException('Unsupported content package kind.');
    }
    _validateCitation(package['sourceCitation']);
    _validateLicense(package['license']);
    final createdAt = _requiredString(package, 'createdAt');
    if (DateTime.tryParse(createdAt) == null) {
      throw const FormatException('Invalid content package creation time.');
    }
    final payload = package['stories'] ?? package['items'];
    if (payload is! List || payload.isEmpty) {
      throw const FormatException('Content package has no items.');
    }
    for (final item in payload) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Content package item is invalid.');
      }
      _requiredString(item, 'id');
      _requiredString(item, 'title');
      if (item['body'] is! String && item['summary'] is! String) {
        throw const FormatException('Content package item has no readable text.');
      }
    }
  }

  static String _requiredString(Map<String, dynamic> value, String key) {
    final field = value[key];
    if (field is! String || field.trim().isEmpty) {
      throw FormatException('Missing $key.');
    }
    return field.trim();
  }

  static void _validateCitation(Object? value) {
    if (value is! Map<String, dynamic> ||
        _requiredString(value, 'name').isEmpty ||
        (value['reference'] is! String &&
            value['url'] is! String &&
            value['identifier'] is! String)) {
      throw const FormatException('Content package source citation is incomplete.');
    }
  }

  static void _validateLicense(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Content package license is incomplete.');
    }
    _requiredString(value, 'usage');
    final hasRightsHolder = value['rightsHolder'] is String &&
        (value['rightsHolder'] as String).trim().isNotEmpty;
    final hasAttribution = value['attribution'] is String &&
        (value['attribution'] as String).trim().isNotEmpty;
    if (!hasRightsHolder && !hasAttribution) {
      throw const FormatException('Content package license is incomplete.');
    }
  }
}
