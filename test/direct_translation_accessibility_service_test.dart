import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native accessibility bridge keeps capture disabled without an allowlist', () {
    final source = File('scripts/patch_direct_translation_accessibility.sh')
        .readAsStringSync();

    expect(source, contains('allowed.isEmpty()'));
    expect(source, contains('__mirror_scorpion_no_allowlist__'));
    expect(source, contains('BIND_ACCESSIBILITY_SERVICE'));
  });
}
