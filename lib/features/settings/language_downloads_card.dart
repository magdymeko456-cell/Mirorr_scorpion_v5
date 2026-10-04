import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/speech/whisper_model_installer.dart';

/// مدير حزم النماذج المحلية. يعرض ما هو متاح فعلياً للتنزيل وما سيُربط
/// بمحركاته لاحقاً، حتى لا تظهر للمستخدم أزرار تنزيل لا تعمل بعد.
class LanguageDownloadsCard extends StatefulWidget {
  const LanguageDownloadsCard({super.key, this.installer});

  final WhisperModelInstaller? installer;

  @override
  State<LanguageDownloadsCard> createState() => _LanguageDownloadsCardState();
}

class _LanguageDownloadsCardState extends State<LanguageDownloadsCard> {
  late final WhisperModelInstaller _installer = widget.installer ?? WhisperModelInstaller();
  static final _whisperDescriptor = WhisperModelDescriptor.baseMultilingual;

  bool _checking = true;
  bool _whisperInstalled = false;
  bool _downloadingWhisper = false;
  double? _whisperProgress;
  String? _notice;

  static const _packages = <_PackageSpec>[
    _PackageSpec(
      title: 'التعرف على الكلام — Whisper',
      subtitle: 'يسجل ويفرغ الكلام محلياً بالعربية والإنجليزية ولغات متعددة.',
      size: '~141 MB',
      icon: Icons.mic_none,
      available: true,
    ),
    _PackageSpec(
      title: 'أصوات النطق المحلية',
      subtitle: 'حزم TTS مستقلة لكل لغة، بدلاً من الاعتماد على صوت النظام.',
      size: 'حسب اللغة',
      icon: Icons.record_voice_over_outlined,
      available: false,
    ),
    _PackageSpec(
      title: 'الترجمة العصبية المحلية',
      subtitle: 'نموذج ترجمة محلي يُنزّل فقط لزوج اللغات الذي تختاره.',
      size: 'حسب زوج اللغات',
      icon: Icons.translate,
      available: false,
    ),
    _PackageSpec(
      title: 'ذكاء القصص المحلي',
      subtitle: 'نموذج قصص اختياري كبير، يُثبّت عند طلب ميزة القصص فقط.',
      size: 'سيظهر لاحقاً',
      icon: Icons.auto_stories_outlined,
      available: false,
    ),
  ];

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
    try {
      final file = await _installer.verifiedInstalledModel(_whisperDescriptor);
      if (!mounted) return;
      setState(() {
        _whisperInstalled = file != null;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _whisperInstalled = false;
        _checking = false;
      });
    }
  }

  Future<void> _downloadWhisper() async {
    setState(() {
      _downloadingWhisper = true;
      _whisperProgress = null;
      _notice = null;
    });
    final result = await _installer.downloadAfterUserApproval(
      descriptor: _whisperDescriptor,
      onProgress: (received, expected) {
        if (!mounted) return;
        setState(() => _whisperProgress = expected <= 0 ? null : received / expected);
      },
    );
    if (!mounted) return;
    setState(() {
      _downloadingWhisper = false;
      _whisperProgress = null;
      _notice = result.message;
      _whisperInstalled = result.isSuccess;
    });
  }

  Future<void> _deleteWhisper() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف حزمة Whisper؟'),
        content: const Text('سيُحذف نموذج التعرف على الكلام وتتحرر مساحة تقارب 141 ميجابايت.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final file = await _installer.modelFile(_whisperDescriptor);
      if (await file.exists()) await file.delete();
      if (!mounted) return;
      setState(() {
        _whisperInstalled = false;
        _notice = 'تم حذف حزمة Whisper وتحرير المساحة.';
      });
    } on FileSystemException {
      if (mounted) setState(() => _notice = 'تعذر حذف الحزمة. أغلق أي جلسة صوتية ثم أعد المحاولة.');
    }
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.language, color: Colors.cyanAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('حزم اللغات والصوت عند الطلب', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'نزّل الوظيفة واللغة التي تحتاجها فقط. كل حزمة تتحقق من الحجم وSHA-256 قبل تفعيلها.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ..._packages.map((package) => _PackageTile(
                  spec: package,
                  installed: package.available && _whisperInstalled,
                  checking: package.available && _checking,
                  downloading: package.available && _downloadingWhisper,
                  progress: package.available ? _whisperProgress : null,
                  onDownload: package.available ? _downloadWhisper : null,
                  onDelete: package.available && _whisperInstalled ? _deleteWhisper : null,
                )),
            if (_notice != null) ...[
              const SizedBox(height: 8),
              Text(_notice!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Text(
              'المساحة المطلوبة تُحسب قبل التفعيل، ويمكن حذف أي حزمة لاحقاً من هذه الشاشة.',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.spec,
    required this.installed,
    required this.checking,
    required this.downloading,
    required this.progress,
    required this.onDownload,
    required this.onDelete,
  });

  final _PackageSpec spec;
  final bool installed;
  final bool checking;
  final bool downloading;
  final double? progress;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = spec.available;
    final status = checking
        ? 'جارٍ فحص الحزمة…'
        : downloading
            ? 'جارٍ التنزيل…'
            : installed
                ? 'مثبّتة ومتحقق منها'
                : enabled
                    ? 'غير مثبّتة'
                    : 'متاحة قريباً';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        border: Border.all(color: installed ? Colors.green.withValues(alpha: 0.55) : Colors.white12),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(spec.icon, color: installed ? Colors.greenAccent : enabled ? Colors.cyanAccent : Colors.white38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(spec.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(spec.subtitle, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 10,
                      children: [
                        Text('المساحة: ${spec.size}', style: theme.textTheme.labelSmall),
                        Text(status, style: TextStyle(color: installed ? Colors.greenAccent : enabled ? Colors.amberAccent : Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              if (installed)
                IconButton(tooltip: 'حذف الحزمة', onPressed: onDelete, icon: const Icon(Icons.delete_outline))
              else if (enabled)
                FilledButton.tonalIcon(
                  onPressed: checking || downloading ? null : onDownload,
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('تنزيل'),
                )
              else
                const Chip(label: Text('قريباً')),
            ],
          ),
          if (downloading) ...[
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(progress == null ? 'جارٍ تجهيز التنزيل…' : '${(progress! * 100).toStringAsFixed(0)}%', style: theme.textTheme.labelSmall),
            ),
          ],
        ],
      ),
    );
  }
}

class _PackageSpec {
  const _PackageSpec({required this.title, required this.subtitle, required this.size, required this.icon, required this.available});

  final String title;
  final String subtitle;
  final String size;
  final IconData icon;
  final bool available;
}
