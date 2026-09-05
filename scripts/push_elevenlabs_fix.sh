#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FILE="$ROOT/lib/core/speech/elevenlabs_voice_service.dart"
cd "$ROOT"

[[ -f "$FILE" ]] || { echo "ملف ElevenLabs غير موجود" >&2; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo "المستودع يحتوي تغييرات محلية؛ احفظها أولاً" >&2; git status --short; exit 1; }

git switch main >/dev/null
git pull --rebase origin main

perl -0pi -e 's/ElevenLabsGatewayState _state = ElevenLabsGatewayState\.missingRuntimeKey;/ElevenLabsGatewayState _state =\n      ElevenLabsGatewayState.disabledPendingServerApproval;/g' "$FILE"
perl -0pi -e 's/(\? ElevenLabsGatewayState\.readyWithRuntimeKey\n\s*: )ElevenLabsGatewayState\.missingRuntimeKey;/$1ElevenLabsGatewayState.disabledPendingServerApproval;/g' "$FILE"
perl -0pi -e 's/لم يُرسل أي نص إلى الخدمة\./لم يُرسل النص إلى الخدمة\./g' "$FILE"
perl -0pi -e 's/سجّل عينة صوتك \(10–30 ثانية\) من شريط الأصوات ثم ارفعها من نفس الشاشة\./لن يُرفع أي تسجيل تلقائياً. سجّل عينة صوتك (10–30 ثانية) من شريط الأصوات، ثم ارفعها فقط بعد موافقتك الصريحة ومن نفس الشاشة./g' "$FILE"

grep -q 'disabledPendingServerApproval' "$FILE"
grep -q 'لم يُرسل النص إلى الخدمة' "$FILE"
grep -q 'لن يُرفع أي تسجيل تلقائياً' "$FILE"
git diff --check
git add "$FILE"
if ! git diff --cached --quiet; then
  git commit -m "fix(P3): align ElevenLabs disabled and privacy messaging"
fi
git push origin main
echo "تم دفع إصلاح ElevenLabs بنجاح"
git log -1 --oneline
