#!/usr/bin/env bash
set -Eeuo pipefail
cd "$HOME/Mirorr_scorpion_v5"

python3 - <<'PY'
import io
p = 'lib/features/feature_hub_screen.dart'
s = io.open(p, encoding='utf-8').read()

# كارت الحوار: إزالة المسح عند لمس المحرر — التعديل اليدوي يبقى ويُحدث الترجمة
old_dialogue = "          onTap: _beginFreshSessionIfNeeded,"
n1 = s.count(old_dialogue)
s = s.replace(old_dialogue, "")

# كارت الترجمة الأول: نفس المبدأ
old_translation = "          onTap: _beginFreshTranslationIfNeeded,"
n2 = s.count(old_translation)
s = s.replace(old_translation, "")

io.open(p, 'w', encoding='utf-8').write(s)
print(f'أُزيل المسح عند اللمس: {n1} في الحوار، {n2} في الترجمة.')
PY

echo "=== الفرق ==="
git diff --stat
