import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../core/speech/elevenlabs_voice_service.dart';
import '../core/speech/system_tts_service.dart';

/// شريط الأصوات الخمسة الموحّد: سلمى/سيف/سما/سارة + «صوتي».
/// كل كارت يمرر خدمته الخاصة فيُحفظ الاختيار بمفتاحه المستقل.
class VoiceProfileBar extends StatefulWidget {
  const VoiceProfileBar({super.key, required this.ttsService});

  final SystemTtsService ttsService;

  @override
  State<VoiceProfileBar> createState() => _VoiceProfileBarState();
}

class _VoiceProfileBarState extends State<VoiceProfileBar> {
  final ElevenLabsVoiceService _cloud = ElevenLabsVoiceService();

  @override
  void initState() {
    super.initState();
    _cloud.restore();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.ttsService,
      builder: (context, _) {
        final selected = widget.ttsService.selectedProfile;
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final profile in SystemVoiceProfile.values)
                ChoiceChip(
                  label: Text(profile.label),
                  selected: selected == profile,
                  tooltip: profile.styleDescription,
                  onSelected: (_) => widget.ttsService.selectProfile(profile),
                ),
              ActionChip(
                avatar: Icon(
                  _cloud.hasClonedVoice
                      ? Icons.record_voice_over
                      : Icons.mic_none,
                  size: 18,
                ),
                label: const Text('صوتي'),
                onPressed: _openUserVoiceSheet,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openUserVoiceSheet() async {
    await _cloud.restore();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _UserVoiceSheet(service: _cloud),
    );
    if (mounted) setState(() {});
  }
}

class _UserVoiceSheet extends StatefulWidget {
  const _UserVoiceSheet({required this.service});

  final ElevenLabsVoiceService service;

  @override
  State<_UserVoiceSheet> createState() => _UserVoiceSheetState();
}

class _UserVoiceSheetState extends State<_UserVoiceSheet> {
  final TextEditingController _keyController = TextEditingController();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isRecording = false;
  String? _samplePath;

  @override
  void initState() {
    super.initState();
    widget.service.restore();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _recorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted || message.isEmpty) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveKey() async {
    final ok = await widget.service.saveRuntimeKey(_keyController.text);
    _toast(widget.service.message ??
        (ok ? 'حُفظ المفتاح محلياً على جهازك فقط.' : 'تعذر حفظ المفتاح.'));
    if (ok && mounted) _keyController.clear();
  }

  Future<void> _toggleRecord() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _samplePath = path;
      });
      _toast('توقف التسجيل. راجع العينة ثم ارفعها.');
      return;
    }
    if (!await _recorder.hasPermission()) {
      _toast('امنح إذن الميكروفون للتطبيق من إعدادات النظام.');
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      await Directory('${dir.path}/mirror_scorpion').create(recursive: true);
      final path =
          '${dir.path}/mirror_scorpion/voice_sample_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      setState(() {
        _isRecording = true;
        _samplePath = path;
      });
      _toast('جارٍ التسجيل… تحدث بوضوح من 10 إلى 30 ثانية.');
    } catch (_) {
      _toast('تعذر بدء التسجيل. تحقق من إذن المايك.');
    }
  }

  Future<void> _uploadSample() async {
    final path = _samplePath;
    if (path == null) {
      _toast('سجّل عينة صوتك أولاً (10–30 ثانية).');
      return;
    }
    final attempt = await widget.service.uploadVoiceSample(filePath: path);
    _toast(attempt.message);
  }

  Future<void> _previewClone() async {
    final attempt = await widget.service.requestCloudReading(
      text: 'هذه قراءة تجريبية بصوت المالك المستنسخ.',
      languageCode: 'ar',
    );
    if (attempt.isSuccess && attempt.audioPath != null) {
      try {
        await _previewPlayer.stop();
      } catch (_) {}
      await _previewPlayer.play(DeviceFileSource(attempt.audioPath!));
    } else {
      _toast(attempt.message);
    }
  }

  Future<void> _deleteClone() async {
    final ok = await widget.service.deleteClonedVoice();
    _toast(ok ? 'حُذفت النسخة من الخدمة ومن جهازك.' : 'تعذر الحذف.');
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.service,
      builder: (context, _) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text('صوتي — نسخ صوت حقيقي عبر ElevenLabs',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(widget.service.statusMessage),
                const SizedBox(height: 12),
                TextField(
                  controller: _keyController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'مفتاح ElevenLabs (يُحفظ على جهازك فقط)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: <Widget>[
                  Expanded(
                    child: FilledButton(
                      onPressed: _saveKey,
                      child: const Text('حفظ المفتاح'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: widget.service.clearRuntimeKey,
                    child: const Text('إزالة المفتاح'),
                  ),
                ]),
                const Divider(height: 24),
                Text(_isRecording
                    ? 'جارٍ التسجيل… اضغط لإيقافه'
                    : 'سجّل عينة صوتك (10–30 ثانية)'),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: _toggleRecord,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic),
                  label: Text(_isRecording ? 'إيقاف التسجيل' : 'بدء التسجيل'),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: widget.service.isBusy ? null : _uploadSample,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text(widget.service.hasClonedVoice
                      ? 'إعادة إنشاء النسخة الصوتية'
                      : 'رفع العينة وإنشاء نسخة صوتي'),
                ),
                if (widget.service.hasClonedVoice) ...<Widget>[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: widget.service.isBusy ? null : _previewClone,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('استمع لقراءة تجريبية بصوتي'),
                  ),
                  TextButton.icon(
                    onPressed: widget.service.isBusy ? null : _deleteClone,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('حذف صوتي المستنسخ'),
                  ),
                ],
                if (widget.service.message != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(widget.service.message!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
