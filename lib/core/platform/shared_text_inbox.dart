import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يستقبل فقط نصاً أرسله المستخدم إلى التطبيق عبر Android Share.
/// لا يراقب الحافظة، ولا يرسل النص إلى الشبكة، ولا يكتب النص على القرص.
class SharedTextInbox extends ChangeNotifier {
  static const _consentKey = 'shared_text_translation_consent_v1';
  static const maxTextLength = 6000;

  StreamSubscription<List<SharedMediaFile>>? _subscription;
  String? _pendingText;
  bool _translationConsent = false;
  bool _initialized = false;

  bool get hasTranslationConsent => _translationConsent;
  String? get pendingText => _pendingText;

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

  void _receiveMedia(List<SharedMediaFile> media) {
    final textItem = media.where(
      (item) =>
          item.type == SharedMediaType.text ||
          (item.mimeType?.toLowerCase().startsWith('text/') ?? false),
    );
    if (textItem.isEmpty) return;
    acceptUserSharedText(textItem.first.path);
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

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
