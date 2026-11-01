import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/platform/shared_text_inbox.dart';

void main() {
  test('shared text is consumed from memory', () {
    final inbox = SharedTextInbox();
    inbox.acceptUserSharedText('Hello from Android Share');
    expect(inbox.takePendingText(), 'Hello from Android Share');
    expect(inbox.pendingText, isNull);
  });

  test('shared audio is consumed from memory', () {
    final inbox = SharedTextInbox();
    inbox.acceptUserSharedAudio('/cache/voice-note.m4a', fileName: 'voice-note.m4a');
    expect(inbox.pendingAudio?.fileName, 'voice-note.m4a');
    expect(inbox.takePendingAudio()?.path, '/cache/voice-note.m4a');
    expect(inbox.pendingAudio, isNull);
  });
}
