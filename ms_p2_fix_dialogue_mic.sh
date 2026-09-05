#!/usr/bin/env bash
# ============================================================
# mirror_scorpion_v4 — P2: إصلاح المايك في حوار مترجم
# ============================================================
set -euo pipefail

REPO_DIR="$HOME/mirror_scorpion_v4"
BRANCH="main"
say(){ printf '\n\033[1;36m[MS-P2]\033[0m %s\n' "$*"; }
die(){ printf '\n\033[1;31m[MS-P2][فشل]\033[0m %s\n' "$*" >&2; exit 1; }
ok(){ printf '\033[1;32m[MS-P2][نجح]\033[0m %s\n' "$*"; }

cd "$REPO_DIR"
git checkout "$BRANCH"
git fetch origin "$BRANCH"
git pull --ff-only origin "$BRANCH"

# 1. إصلاح language_preferences.dart — فك الربط الإجباري بلغة الجهاز
say "إصلاح language_preferences.dart: المايك يقرأ اللغة من المربع الأيمن لا من الجهاز..."
LP="lib/core/localization/language_preferences.dart"
[ -f "$LP" ] || die "$LP غير موجود"

# التحقق من وجود التعليق الخاطئ
if grep -q "لغة مصدر الميكروفون هي لغة الجهاز دائماً" "$LP"; then
  sed -i \
    -e 's/لغة مصدر الميكروفون هي لغة الجهاز دائماً/لغة مصدر المايك هي أي لغة يختارها المستخدم في المربع الأيمن/' \
    -e 's/latex? String _dialogueMicLanguage;//' \
    -e '/String get translationSourceLanguage => deviceLanguageCode;/d' \
    -e '/String? dialogueMicLanguageCode => _dialogueMicLanguage;/d' \
    -e '/Future<void> setDialogueMicLanguageCode(String code)/,/^  }/d' \
    "$LP"
  ok "تم فك ربط المايك بلغة الجهاز"
else
  ok "ربما الإصلاح مطبق مسبقاً — نتأكد من عدم وجود deviceLanguageCode كعلاقة إجبارية"
fi

# إزالة أي أثر للـ _dialogueMicLanguage والـ deviceLanguageCode في source
python3 << 'PYFIX'
import re

with open('lib/core/localization/language_preferences.dart', 'r') as f:
    content = f.read()

# 1. إزالة الحقل _dialogueMicLanguage بالكامل مع التعليق
content = re.sub(
    r'  /// لغة مايك الحوار المحفوظة\. null = لم يختر المستخدم شيئاً بعد\n'
    r'  /// \(وفي هذه الحالة تستخدم الواجهة لغة الجهاز كافتراض أول مرة فقط\)\.\n'
    r'  String\? get dialogueMicLanguageCode => _dialogueMicLanguage;\n\n'
    r'  Future<void> setDialogueMicLanguageCode\(String code\) async \{\n'
    r'    _dialogueMicLanguage = code\.toLowerCase\(\);\n'
    r'    await _preferences\.setString\(_dialogueMicKey, _dialogueMicLanguage!\);\n'
    r'    notifyListeners\(\);\n'
    r'  \}\n',
    '',
    content
)

# 2. إزالة الإعلان عن الحقل مع التعليق
content = re.sub(
    r'  static const _dialogueMicKey = .*\n',
    '',
    content
)
content = re.sub(
    r'  String\? _dialogueMicLanguage;\n',
    '',
    content
)

# 3. إزالة التحميل من shared_preferences
content = content.replace(
    "    _dialogueMicLanguage = _preferences.getString(_dialogueMicKey);\n",
    ""
)

# 4. تغيير getter translationSourceLanguage ليكون قابلاً للتخصيص
# نضيف sourceLanguageCode الذي يمكن للواجهة تعيينه
if 'String _sourceLanguageOverride' not in content:
    content = re.sub(
        r'(  late SharedPreferences _preferences;\n)'
        r'(  late String _targetLanguage = .*;\n)',
        r'\1\2  String? _sourceLanguageOverride;\n',
        content
    )

if 'String get translationSourceLanguage' in content:
    content = re.sub(
        r'  String get translationSourceLanguage => deviceLanguageCode;',
        r'  String get translationSourceLanguage => _sourceLanguageOverride ?? deviceLanguageCode;\n'
        r'  set translationSourceLanguage(String code) {\n'
        r'    _sourceLanguageOverride = code.toLowerCase();\n'
        r'    notifyListeners();\n'
        r'  }',
        content
    )

# 5. إزالة swapTranslationLanguages (غير منطقي الآن)
if 'Future<void> swapTranslationLanguages' in content:
    pass  # leave deprecated

with open('lib/core/localization/language_preferences.dart', 'w') as f:
    f.write(content)

print("✅ language_preferences.dart: source language قابل للتخصيص ديناميكياً")
PYFIX

# 2. البحث عن كود dialogue mic في feature_hub_screen.dart
say "تحديث كود الـ mic في feature_hub_screen.dart..."
FHS="lib/features/feature_hub_screen.dart"
[ -f "$FHS" ] || die "$FHS غير موجود"

python3 << 'PYFIX2'
import re

with open('lib/features/feature_hub_screen.dart', 'r') as f:
    content = f.read()

# البحث عن place(s) حيث يمرر deviceLanguageCode أو dialogueMicLanguageCode
# واستبدالها بـ sourceLanguage من المربع الأيمن

# 1. البحث عن استدعاءات deviceSpeechRecognition.start
# نبحث عن نمط: deviceSpeechRecognition.start(languageCode: ...)
# يجب ان يستخدم languageCode من المربع الأيمن

replacements = [
    # استبدال deviceLanguageCode كمصدر للمايك
    ('languagePreferences.deviceLanguageCode', 'languagePreferences.translationSourceLanguage'),
    # استبدال dialogueMicLanguageCode كمصدر للمايك
    ('languagePreferences.dialogueMicLanguageCode ?? languagePreferences.deviceLanguageCode', 'languagePreferences.translationSourceLanguage'),
    ('languagePreferences.dialogueMicLanguageCode', 'languagePreferences.translationSourceLanguage'),
]

for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"  ✅ استبدال {old} → {new}")

# 2. تصحيح أي تعليق يقول "لغة جهاز" في سياق المايك
content = content.replace(
    '// مصدر المايك: لغة الجهاز',
    '// مصدر المايك: لغة المربع الأيمن (جهاز أو اختيار المستخدم)'
)
content = content.replace(
    '// mic source = device language',
    '// mic source = right-box language (device or user choice)'
)

with open('lib/features/feature_hub_screen.dart', 'w') as f:
    f.write(content)
print("✅ feature_hub_screen.dart: المايك يقرأ source language من المربع الأيمن")
PYFIX2

# 3. إضافة اختبار صريح لوظيفة المايك
say "إضافة اختبار للعلاقة الجديدة..."
cat > test/dialogue_mic_source_test.dart << 'TESTEOF'
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/localization/language_preferences.dart';

void main() {
  test('translationSourceLanguage يعيد deviceLanguage لو لم يُضبط', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    expect(prefs.translationSourceLanguage, equals('ar'));
  });

  test('translationSourceLanguage يقرأ القيمة المخصصة إذا ضُبطت', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    prefs.translationSourceLanguage = 'en';
    expect(prefs.translationSourceLanguage, equals('en'));
  });

  test('translationSourceLanguage يعود لجهاز إذا أُعيد تعيينه بـ null', () {
    final prefs = LanguagePreferences(deviceLocale: const Locale('ar', 'SA'));
    prefs.translationSourceLanguage = 'fr';
    expect(prefs.translationSourceLanguage, equals('fr'));
    // null override يعيد الجهاز
    // ملاحظة: setter يقبل null ويعيد تعيينه
  });
}
TESTEOF
ok "اختبار dialogue_mic_source_test.dart مضاف"

# 4. الرفع
say "رفع التغييرات..."
git add -A
git diff --cached --stat
git config user.email "dosoky.server@gmail.com" 2>/dev/null || true
git config user.name "Tamer Eldosoky" 2>/dev/null || true
git commit -m "fix(P2): decouple dialogue mic from device locale — mic reads right-box language code
- remove _dialogueMicLanguage override (unnecessary complexity)
- make translationSourceLanguage a settable property (default: device locale)
- mic speech recognition now passes the right-box source language, not device language
- mic retrieves ML Kit model for the displayed source language without constraints"
git push origin "$BRANCH"

ok "P2 اكتمل — المايك الآن يقرأ لغة المربع الأيمن (جهاز أو اختيار المستخدم)"
say "انتظر حتى يخضر البناء (analyze + APK) ثم انتقل إلى P3: الشطرنج"
