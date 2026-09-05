import os

path = "lib/presentation/widgets/voice_picker_widget.dart"
os.makedirs(os.path.dirname(path), exist_ok=True)

code = """import 'package:flutter/material.dart';

class VoicePickerWidget extends StatelessWidget {
  final String selectedVoice;
  final ValueChanged<String> onVoiceChanged;

  const VoicePickerWidget({
    super.key,
    required this.selectedVoice,
    required this.onVoiceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final voices = {
      'تامر (الصوت الأساسي)': 'tamer',
      'سيف': 'saif',
      'سلمى': 'salma',
      'سما': 'sama',
      'سارة': 'sara',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF163836),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: voices.containsValue(selectedVoice) ? selectedVoice : 'tamer',
          dropdownColor: const Color(0xFF0F2C2A),
          icon: const Icon(Icons.mic, color: Colors.amber),
          style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
          items: voices.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Text(entry.key, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onVoiceChanged(val);
            }
          },
        ),
      ),
    );
  }
}
"""

with open(path, "w", encoding="utf-8") as f:
    f.write(code)
print("✅ تم تحديث نظام الأصوات والمايك بنجاح جذري.")
