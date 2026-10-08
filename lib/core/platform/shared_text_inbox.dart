import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يستقبل نصاً أو ملفاً صوتياً أرسله المستخدم صراحة عبر Android Share.
/// لا يراقب الحافظة، ولا يرسل البيانات إلى الشبكة، ولا يكتب المشاركة في
/// تخزين دائم.
class SharedTextInbox extends ChangeNotifier {
  static const _consentKey = 'shared_text_translation_consent_v1';
  static const maxTextLength = 6000;

  StreamSubscription<List<SharedMediaFile>>? _subscription;
  String? _pendingText;
  SharedAudioShare? _pendingAudio;
  bool _translationConsent = false;
  bool _initialized = false;

  bool get hasTranslationConsent => _translationConsent;
  String? get pendingText => _pendingText;
  SharedAudioShare? get pendingAudio => _pendingAudio;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final preferences = await SharedPreferences.getInstance();
    _translationConsent = preferences.getBool(_consentKey) ?? false;
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _receiveMedia,
      onError: (_) {},
    );
    try {
      final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
      _receiveMedia(initialMedia);
      if (initialMedia.isNotEmpty) {
        await ReceiveSharingIntent.instance.reset();
      }
    } catch (_) {
      // يفشل استقبال Share بصمت؛ لا توجد بيانات بديلة ولا إعادة محاولة خفية.
    }
  }

  Future<void> setTranslationConsent(bool value) async {
    _translationConsent = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_consentKey, value);
    notifyListeners();
  }

  String? takePendingText() {
    final text = _pendingText;
    _pendingText = null;
    if (text != null) notifyListeners();
    return text;
  }

  SharedAudioShare? takePendingAudio() {
    final audio = _pendingAudio;
    _pendingAudio = null;
    if (audio != null) notifyListeners();
    return audio;
  }

  void _receiveMedia(List<SharedMediaFile> media) {
    final textItem = media.where(
      (item) =>
          item.type == SharedMediaType.text ||
          (item.mimeType?.toLowerCase().startsWith('text/') ?? false),
    );
    if (textItem.isNotEmpty) {
      acceptUserSharedText(textItem.first.path);
    }
    final audioItems = media.where(
      (item) => item.mimeType?.toLowerCase().startsWith('audio/') ?? false,
    );
    if (audioItems.isNotEmpty && audioItems.first.path.trim().isNotEmpty) {
      final audio = audioItems.first;
      acceptUserSharedAudio(
        audio.path,
        fileName: audio.path.split('/').last,
      );
    }
  }

  /// يقبل نصاً وصل فقط عبر فعل Share صريح من المستخدم أو عبر اختبار محلي.
  /// لا يستدعي ClipboardManager ولا يسجل النص في تخزين دائم.
  void acceptUserSharedText(String rawText) {
    final text = rawText.trim();
    if (text.length < 3) return;
    _pendingText = text.length > maxTextLength
        ? text.substring(0, maxTextLength)
        : text;
    notifyListeners();
  }

  /// Accepts only an explicit Android Share result; no background file scan.
  void acceptUserSharedAudio(String path, {String? fileName}) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return;
    _pendingAudio = SharedAudioShare(
      path: trimmed,
      fileName: fileName?.trim().isNotEmpty == true
          ? fileName!.trim()
          : trimmed.split('/').last,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

class SharedAudioShare {
  const SharedAudioShare({required this.path, required this.fileName});

  final String path;
  final String fileName;
}
