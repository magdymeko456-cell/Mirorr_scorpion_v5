import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android share intent accepts text and audio MIME types', () {
    final workflow = File('.github/workflows/build_apk.yml').readAsStringSync();
    expect(workflow, contains('android:mimeType=\\"text/*\\"'));
    expect(workflow, contains('android:mimeType=\\"audio/*\\"'));
  });
}
