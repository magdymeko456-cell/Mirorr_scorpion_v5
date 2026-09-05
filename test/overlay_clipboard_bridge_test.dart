import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('overlay clipboard bridge is explicit and user-triggered', () {
    final overlaySource = File(
      'lib/core/platform/android_overlay_service.dart',
    ).readAsStringSync();
    final bridgeScript = File(
      'scripts/patch_overlay_clipboard_bridge.sh',
    ).readAsStringSync();

    expect(overlaySource, contains('mirror_scorpion/overlay_clipboard'));
    expect(overlaySource, contains('readUserRequestedText'));
    expect(bridgeScript, contains('readUserRequestedText'));
    expect(bridgeScript, contains('ClipboardManager'));
  });
}
