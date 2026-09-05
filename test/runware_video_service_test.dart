import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/media/runware_video_service.dart';

void main() {
  test('Runware video gateway stays disabled in Flutter', () {
    final service = RunwareVideoService();

    expect(service.enabled, isFalse);
    expect(service.externalCallsAllowed, isFalse);
    expect(RunwareVideoService.providerName, 'Runware');
    expect(RunwareVideoService.deliveryMethod, 'async');
    expect(RunwareVideoService.outputFormat, 'MP4');
    expect(SubscriptionBoundaries.cloudVideoLimit, contains('0'));
  });

  test('Runware video requires a draft and explicit consent before disabled state', () {
    final service = RunwareVideoService();

    expect(
      service.prepareStoryVideo(draft: '', hasExplicitConsent: true).code,
      'STORY_REQUIRED',
    );
    expect(
      service.prepareStoryVideo(draft: 'قصة هادفة', hasExplicitConsent: false).code,
      'CONSENT_REQUIRED',
    );
    final blocked = service.prepareStoryVideo(
      draft: 'قصة هادفة',
      hasExplicitConsent: true,
    );
    expect(blocked.allowed, isFalse);
    expect(blocked.code, 'GATEWAY_DISABLED');
  });
}
