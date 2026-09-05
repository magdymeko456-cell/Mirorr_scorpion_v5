import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/platform/android_overlay_service.dart';

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('does not attempt an overlay outside Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final service = AndroidOverlayService();

    expect(service.isSupported, isFalse);
    final result = await service.showBubble();

    expect(result.state, AndroidOverlayState.unsupported);
    expect(service.isVisible, isFalse);
    service.dispose();
  });
}
