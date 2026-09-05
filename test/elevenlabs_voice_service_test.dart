import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/speech/elevenlabs_voice_service.dart';

void main() {
  test('ElevenLabs service stays disabled without any client-side configuration', () async {
    final service = ElevenLabsVoiceService();

    expect(service.isGatewayEnabled, isFalse);
    expect(
      service.state,
      ElevenLabsGatewayState.disabledPendingServerApproval,
    );
    expect(service.statusMessage, contains('لا يُرسل التطبيق نصاً أو تسجيلاً'));

    final attempt = await service.requestCloudReading(
      text: 'نص اختبار',
      languageCode: 'ar',
    );

    expect(attempt.allowed, isFalse);
    expect(attempt.message, contains('لم يُرسل النص'));
  });

  test('voice cloning stays blocked before a server and explicit consent exist', () async {
    final service = ElevenLabsVoiceService();

    final attempt = await service.requestInstantVoiceClone();

    expect(attempt.allowed, isFalse);
    expect(attempt.message, contains('لن يُرفع أي تسجيل'));
    expect(
      ElevenLabsVoiceService.consentDocumentPath,
      contains('elevenlabs-voice-consent-and-deletion-contract'),
    );
  });
}
