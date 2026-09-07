import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/speech/whisper_model_installer.dart';

/// كارت إعدادات "تنزيل اللغات (أوفلاين)": يعرض حالة نموذج التفريغ متعدد
/// اللغات، ويتيح تنزيله بموافقة صريحة مع مؤشر تقدم، أو حذفه لتحرير المساحة.
/// النموذج الواحد يخدم جميع اللغات المدعومة لذلك لا تُعرض قائمة لغات هنا.
class LanguageDownloadsCard extends StatefulWidget {
  const LanguageDownloadsCard({super.key, this.installer});

  final WhisperModelInstaller? installer;

  @override
  State<LanguageDownloadsCard> createState() => _LanguageDownloadsCardState();
}

class _LanguageDownloadsCardState extends State<LanguageDownloadsCard> {
  late final WhisperModelInstaller _installer =
      widget.installer ?? WhisperModelInstaller();

  bool _checking = true;
  bool _downloading = false;
  bool _installed = false;
  double? _progress;
  String? _notice;

  static final _descriptor = WhisperModelDescriptor.baseMultilingual;

  @override
  void initState() {
    super.initState();
    _refreshInstallState();
  }

  @override
  void dispose() {
    _installer.dispose();
    super.dispose();
  }

  Future<void> _refreshInstallState() async {
    setState(() => _checking = true);
    try {
      final file = await _installer.verifiedInstalledModel(_descriptor);
      if (!mounted) return;
      setState(() {
        _installed = file != null;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _installed = false;
        _checking = false;
      });
    }
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _progress = null;
      _notice = null;
    });
    final result = await _installer.downloadAfterUserApproval(
      descriptor: _descriptor,
      onProgress: (received, expected) {
        if (!mounted) return;
        setState(() => _progress = expected <= 0 ? null : received / expected);
      },
    );
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _progress = null;
      _notice = result.message;
      _installed = result.isSuccess;
    });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف نموذج الأوفلاين؟'),
        content: const Text(
          'سيُحذف نموذج التفريغ المحلي وستعود حاجة ترجمة الصوت إلى خدمة '
          'الجهاز عبر الإنترنت. المساحة المستعادة: ~141 ميجابايت.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final file = await _installer.modelFile(_descriptor);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      if (!mounted) return;
      setState(() => _notice = 'تعذر حذف النموذج. أغلق المايك وأعد المحاولة.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _installed = false;
      _notice = 'تم حذف النموذج وتحرير المساحة.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _installed ? Icons.download_done : Icons.cloud_download_outlined,
                  color: _installed ? Colors.green : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('تنزيل اللغات (أوفلاين)', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        _checking
                            ? 'جارٍ فحص الحالة...'
                            : _installed
                                ? 'النموذج المحلي مثبّت — المايك يعمل بلا إنترنت بكل اللغات المدعومة.'
                                : 'النموذج غير مثبّت — المايك يستخدم خدمة الجهاز عبر الإنترنت.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_downloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text(
                _progress == null
                    ? 'جارٍ التنزيل...'
                    : 'جارٍ التنزيل: ${(_progress! * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (_notice != null) ...[
              const SizedBox(height: 12),
              Text(_notice!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_installed)
                  TextButton(
                    onPressed: _downloading ? null : _delete,
                    child: const Text('حذف النموذج'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _checking || _downloading ? null : _download,
                    icon: const Icon(Icons.download),
                    label: const Text('تنزيل (~141 ميجابايت)'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
