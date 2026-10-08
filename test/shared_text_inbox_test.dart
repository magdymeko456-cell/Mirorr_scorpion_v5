import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/platform/shared_text_inbox.dart';

void main() {
  test('shared text remains in memory only until it is consumed', () {
    final inbox = SharedTextInbox();

    inbox.acceptUserSharedText('Hello from Android Share');

    expect(inbox.pendingText, 'Hello from Android Share');
    expect(inbox.takePendingText(), 'Hello from Android Share');
    expect(inbox.pendingText, isNull);
  });

  test('shared text rejects tiny values and bounds a large value', () {
    final inbox = SharedTextInbox();

    inbox.acceptUserSharedText('  x ');
    expect(inbox.pendingText, isNull);

    inbox.acceptUserSharedText('a' * (SharedTextInbox.maxTextLength + 20));
    expect(inbox.pendingText, hasLength(SharedTextInbox.maxTextLength));
  });

  test('explicitly shared audio stays in memory until the translation card consumes it', () {
    final inbox = SharedTextInbox();

    inbox.acceptUserSharedAudio('/cache/voice-note.m4a', fileName: 'voice-note.m4a');

    expect(inbox.pendingAudio?.path, '/cache/voice-note.m4a');
    expect(inbox.pendingAudio?.fileName, 'voice-note.m4a');
    expect(inbox.takePendingAudio()?.path, '/cache/voice-note.m4a');
    expect(inbox.pendingAudio, isNull);
  });
});
