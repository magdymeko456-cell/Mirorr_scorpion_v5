import 'package:flutter/material.dart';

import '../core/speech/system_tts_service.dart';

/// شريط اختيار ملف الأداء الصوتي لكل كارت على حدة. كل كارت يملك نسخة
/// SystemTtsService بمفتاح تخزين مستقل، لذا الاختيار هنا لا يمس بقية الكروت.
class VoiceProfileSelector extends StatelessWidget {
  const VoiceProfileSelector({
    required this.service,
    required this.onPreview,
    super.key,
  });

  final SystemTtsService service;
  final Future<void> Function(SystemVoiceProfile profile) onPreview;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final profile in SystemVoiceProfile.values)
              ChoiceChip(
                label: Text('${profile.label} — ${profile.styleDescription}'),
                selected: service.selectedProfile == profile,
                onSelected: (_) async {
                  await service.selectProfile(profile);
                  await onPreview(profile);
                },
              ),
          ],
        );
      },
    );
  }
}
