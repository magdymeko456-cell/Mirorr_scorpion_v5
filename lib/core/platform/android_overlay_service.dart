import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import '../mlkit/on_device_translation_service.dart';

enum AndroidOverlayState {
  started,
  stopped,
  unsupported,
  permissionDenied,
  failed,
}

class AndroidOverlayResult {
  const AndroidOverlayResult(this.state, this.message);

  final AndroidOverlayState state;
  final String message;

  bool get isStarted => state == AndroidOverlayState.started;
}

/// طبقة Android فقط لفقاعة ظاهرة يطلبها المستخدم صراحة. لا تطلب
/// Accessibility أو Notification Listener، ولا تقرأ نصوص تطبيقات أخرى.
class AndroidOverlayService extends ChangeNotifier {
  bool _isVisible = false;
  StreamSubscription<dynamic>? _overlayEvents;

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool get isVisible => _isVisible;

  Future<void> initialize() async {
    if (!isSupported) return;
    _overlayEvents ??= FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map && event['event'] == 'closed') {
        _setVisible(false);
      }
    });
    await refreshStatus();
  }

  Future<void> refreshStatus() async {
    if (!isSupported) {
      _setVisible(false);
      return;
    }
    try {
      _setVisible(await FlutterOverlayWindow.isActive());
    } catch (_) {
      _setVisible(false);
    }
  }

  Future<AndroidOverlayResult> showBubble() async {
    if (!isSupported) {
      return const AndroidOverlayResult(
        AndroidOverlayState.unsupported,
        'الفقاعة فوق التطبيقات متاحة على Android فقط.',
      );
    }
    try {
      var permitted = await FlutterOverlayWindow.isPermissionGranted();
      if (!permitted) {
        permitted = await FlutterOverlayWindow.requestPermission() ?? false;
      }
      if (!permitted) {
        return const AndroidOverlayResult(
          AndroidOverlayState.permissionDenied,
          'لم يُمنح إذن الظهور فوق التطبيقات؛ لم تبدأ الفقاعة.',
        );
      }
      if (!await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.showOverlay(
          height: 84,
          width: 84,
          alignment: OverlayAlignment.centerRight,
          enableDrag: true,
          flag: OverlayFlag.defaultFlag,
          positionGravity: PositionGravity.auto,
          startPosition: OverlayPosition(0, 156),
          overlayTitle: 'Mirror Scorpion',
          overlayContent: 'فقاعة ترجمة محلية يفعّلها المستخدم',
        );
      }
      await refreshStatus();
      if (!_isVisible) {
        return const AndroidOverlayResult(
          AndroidOverlayState.failed,
          'لم تبدأ الفقاعة رغم منح الإذن. أعد فتح التطبيق وحاول مرة أخرى.',
        );
      }
      return const AndroidOverlayResult(
        AndroidOverlayState.started,
        'ظهرت الفقاعة القابلة للسحب مع إشعار foreground. تترجم فقط النص الذي تكتبه أو تلصقه بنفسك.',
      );
    } catch (_) {
      return const AndroidOverlayResult(
        AndroidOverlayState.failed,
        'تعذر بدء الفقاعة. تحقق من إذن الظهور فوق التطبيقات ثم أعد المحاولة.',
      );
    }
  }

  Future<AndroidOverlayResult> closeBubble() async {
    if (!isSupported) {
      return const AndroidOverlayResult(
        AndroidOverlayState.unsupported,
        'الفقاعة فوق التطبيقات متاحة على Android فقط.',
      );
    }
    try {
      await FlutterOverlayWindow.closeOverlay();
      _setVisible(false);
      return const AndroidOverlayResult(
        AndroidOverlayState.stopped,
        'تم إيقاف الفقاعة وإزالة إشعار foreground.',
      );
    } catch (_) {
      return const AndroidOverlayResult(
        AndroidOverlayState.failed,
        'تعذر إيقاف الفقاعة من هذه الجلسة. أوقفها من الإشعار أو أعد فتح التطبيق.',
      );
    }
  }

  void _setVisible(bool visible) {
    if (_isVisible == visible) return;
    _isVisible = visible;
    notifyListeners();
  }

  @override
  void dispose() {
    _overlayEvents?.cancel();
    super.dispose();
  }
}

class MirrorScorpionOverlayApp extends StatelessWidget {
  const MirrorScorpionOverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const _MirrorScorpionOverlayScreen(),
    );
  }
}

class _MirrorScorpionOverlayScreen extends StatefulWidget {
  const _MirrorScorpionOverlayScreen();

  @override
  State<_MirrorScorpionOverlayScreen> createState() =>
      _MirrorScorpionOverlayScreenState();
}

class _MirrorScorpionOverlayScreenState
    extends State<_MirrorScorpionOverlayScreen> {
  static const _overlayLanguages = <String, String>{
    'ar': 'العربية',
    'en': 'English',
    'hi': 'हिन्दी',
    'fr': 'Français',
    'es': 'Español',
    'de': 'Deutsch',
    'tr': 'Türkçe',
    'ur': 'اردو',
    'ru': 'Русский',
    'zh': '中文',
  };
  String? _selectedFrom;
  String? _selectedTo;

  static const _clipboardBridge = MethodChannel(
    'mirror_scorpion/overlay_clipboard',
  );
  final _input = TextEditingController();
  final _translationService = const OnDeviceTranslationService();
  bool _expanded = false;
  bool _isTranslating = false;
  String? _translatedText;
  String? _notice;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _expand() async {
    await FlutterOverlayWindow.updateFlag(OverlayFlag.focusPointer);
    await FlutterOverlayWindow.resizeOverlay(344, 350, false);
    if (mounted) setState(() => _expanded = true);

    unawaited(_centerExpandedPanel());
  }

  Future<void> _collapse() async {
    await FlutterOverlayWindow.updateFlag(OverlayFlag.defaultFlag);
    await FlutterOverlayWindow.resizeOverlay(84, 84, true);
    if (mounted) {
      setState(() {
        _expanded = false;
        _notice = null;
      });
    }

    unawaited(_restoreBubbleCorner());
  }

  Future<void> _close() async {
    await FlutterOverlayWindow.shareData(<String, String>{'event': 'closed'});
    await FlutterOverlayWindow.closeOverlay();
  }

  Future<void> _pasteText() async {
    String text = '';
    try {
      text =
          (await _clipboardBridge.invokeMethod<String>(
            'readUserRequestedText',
          ))?.trim() ??
          '';
    } catch (_) {
      // محرك Overlay مستقل عن Activity؛ لا نعيد الوصول إلى الحافظة تلقائياً.
    }
    if (!mounted) return;
    setState(() {
      if (text.isEmpty) {
        _notice =
            'تعذر الوصول إلى نص الحافظة. انسخ نصاً عادياً ثم اضغط «الصق النص»؛ '
            'إن قيّد Android الحافظة، ضع المؤشر في الحقل واختر «لصق» من لوحة المفاتيح.';
      } else {
        final boundedText = text.length > 1800 ? text.substring(0, 1800) : text;
        _input.value = TextEditingValue(
          text: boundedText,
          selection: TextSelection.collapsed(offset: boundedText.length),
        );
        _notice = 'لُصق النص بطلبك. لن يُحتفظ به بعد إغلاق الفقاعة.';
      }
    });
  }

  Future<void> _translate() async {
    final text = _input.text.trim();
    if (text.length < 3) {
      setState(() => _notice = 'اكتب أو الصق نصاً أطول قليلاً للترجمة.');
      return;
    }
    setState(() {
      _isTranslating = true;
      _notice = 'جارٍ تحديد اللغة وترجمتها محلياً…';
      _translatedText = null;
    });
    final targetLanguage =
        _selectedTo ?? PlatformDispatcher.instance.locale.languageCode;
    final result = await _translationService.translate(
      text: text,
      sourceLanguageCode: _selectedFrom,
      targetLanguageCode: targetLanguage,
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _notice = switch (progress) {
            OnDeviceTranslationProgress.identifyingLanguage =>
              'جارٍ تحديد لغة النص محلياً…',
            OnDeviceTranslationProgress.checkingModels =>
              'جارٍ فحص نماذج الترجمة…',
            OnDeviceTranslationProgress.downloadingModels =>
              'يُنزّل نموذج اللغة محلياً للمرة الأولى…',
            OnDeviceTranslationProgress.translating =>
              'جارٍ إجراء الترجمة داخل الجهاز…',
          };
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _isTranslating = false;
      _translatedText = result.isSuccess ? result.text : null;
      _notice = result.message ?? 'انتهت محاولة الترجمة.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: Center(child: _expanded ? _expandedBubble() : _compactBubble()),
      ),
    );
  }

  // ---- overlay fix: center panel, draggable bubble ----

  static const double _kPanelWidth = 320;
  static const double _kPanelHeight = 326;
  static const double _kBubbleSize = 76;

  (double, double, double)? _physicalScreenMetrics() {
    try {
      final views = PlatformDispatcher.instance.views;
      if (views.isEmpty) return null;
      final view = views.first;
      final size = view.display.size;
      if (size.width <= 0 || size.height <= 0) return null;
      final dpr = view.devicePixelRatio > 0 ? view.devicePixelRatio : 2.0;
      return (size.width, size.height, dpr);
    } catch (_) {
      return null;
    }
  }

  Future<void> _centerExpandedPanel() async {
    try {
      final metrics = _physicalScreenMetrics();
      if (metrics == null) return;
      final (screenW, screenH, dpr) = metrics;
      final panelW = (_kPanelWidth * dpr).round();
      final panelH = (_kPanelHeight * dpr).round();
      final left = ((screenW - panelW) / 2).floor().clamp(0, screenW.round()).toDouble();
      final top = ((screenH - panelH) / 2).floor().clamp(0, screenH.round()).toDouble();
      await FlutterOverlayWindow.resizeOverlay(panelW, panelH, false);
      await FlutterOverlayWindow.moveOverlay(OverlayPosition(left, top));
    } catch (_) {}
  }

  Future<void> _restoreBubbleCorner() async {
    try {
      final metrics = _physicalScreenMetrics();
      if (metrics == null) return;
      final (screenW, screenH, dpr) = metrics;
      final bubblePx = (_kBubbleSize * dpr).round();
      final left = (screenW.round() - bubblePx - (16 * dpr).round()).clamp(
        0,
        screenW.round(),
      ).toDouble();
      final top = (screenH * 0.12).round().toDouble();
      await FlutterOverlayWindow.resizeOverlay(bubblePx, bubblePx, false);
      await FlutterOverlayWindow.moveOverlay(OverlayPosition(left, top));
    } catch (_) {}
  }

  Widget _compactBubble() => Container(
    width: 76,
    height: 76,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFF102840),
      border: Border.all(color: Colors.cyanAccent, width: 2),
      boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
    ),
    child: IconButton(
      tooltip: 'فتح مترجم ميرور سكربيون',
      onPressed: _expand,
      icon: const Icon(Icons.translate, color: Colors.cyanAccent, size: 34),
    ),
  );

  Widget _expandedBubble() => Container(
    width: 320,
    height: 326,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFF102840),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.cyanAccent, width: 1.5),
      boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 16)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.translate, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'ترجمة محلية',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'تصغير الفقاعة',
              onPressed: _collapse,
              icon: const Icon(Icons.minimize),
            ),
            IconButton(
              tooltip: 'إيقاف الفقاعة',
              onPressed: _close,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        TextField(
          controller: _input,
          minLines: 2,
          maxLines: 3,
          maxLength: 1800,
          textInputAction: TextInputAction.newline,
          decoration: const InputDecoration(
            hintText: 'اكتب النص الذي تريد ترجمته…',
            counterText: '',
            isDense: true,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedFrom,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'من لغة',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(child: Text('اكتشاف تلقائي')),
                  ..._overlayLanguages.entries.map(
                    (e) => DropdownMenuItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedFrom = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _selectedTo,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'إلى لغة',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                items: _overlayLanguages.entries
                    .map(
                      (e) => DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedTo = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isTranslating ? null : _pasteText,
                icon: const Icon(Icons.content_paste_go_outlined),
                label: const Text('الصق النص'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isTranslating ? null : _translate,
                icon: _isTranslating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.translate),
                label: const Text('ترجم'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SingleChildScrollView(
              child: Text(
                _translatedText ??
                    _notice ??
                    'تعمل الفقاعة للنص الذي تكتبه أو تلصقه بنفسك فقط.',
                style: TextStyle(
                  color: _translatedText == null
                      ? Colors.white70
                      : Colors.cyanAccent,
                  height: 1.35,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
