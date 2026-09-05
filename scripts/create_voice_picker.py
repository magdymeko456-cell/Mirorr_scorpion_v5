import os

widget_code = """
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/voices/voice_manager.dart';

class VoicePickerWidget extends StatelessWidget {
  const VoicePickerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final voiceManager = context.watch<VoiceManager>();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'اختر صوت السرد والمساعد (ميرور)',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...VoiceManager.profiles.values.map((profile) {
            final isSelected = voiceManager.currentPersona == profile.persona;
            final isLocked = profile.isPaidOnly && !voiceManager.isPaidUnlocked;

            return ListTile(
              onTap: () {
                if (isLocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🔒 صوت المستخدم الخاص متاح حصرياً في النسخة المدفوعة.'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }
                voiceManager.setPersona(profile.persona);
              },
              leading: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isSelected ? Colors.amber : Colors.white54,
              ),
              title: Text(
                profile.nameAr,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isLocked
                  ? const Icon(Icons.lock, color: Colors.amberAccent, size: 20)
                  : (profile.isPaidOnly ? const Icon(Icons.star, color: Colors.amber, size: 20) : null),
            );
          }).toList(),
        ],
      ),
    );
  }
}
"""

os.makedirs("lib/presentation/widgets", exist_ok=True)
with open("lib/presentation/widgets/voice_picker_widget.dart", "w", encoding="utf-8") as f:
    f.write(widget_code)

print("✅ تم إنشاء واجهة اختيار الأصوات (VoicePickerWidget) في مسارها بنجاح تام!")
