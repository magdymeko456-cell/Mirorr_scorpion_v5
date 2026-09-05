#!/usr/bin/env python3
"""v3.1 — نفس أهداف v3 بأنماط مرنة. تقرير لكل بند؛ لا كتابة إن فشل أي بند ينتج خطأ analyzer.
Usage: python scripts/fix_dialogue_decoupling_v31.py [--apply]"""
import pathlib, re, sys

FILE = pathlib.Path('lib/features/feature_hub_screen.dart')
APPLY = '--apply' in sys.argv
s = FILE.read_text(encoding='utf-8')
fails = []

def sub1(pat, repl, label, key=None):
    global s
    new, n = re.subn(pat, repl, s, flags=re.M)
    if n == 1:
        s = new; print(f"OK  : {label}")
    else:
        fails.append(label)
        print(f"FAIL: {label} — تطابقات {n} (المتوقع 1)")
        if key:
            for i, l in enumerate(s.splitlines()):
                if key in l:
                    print(f"      سياق {i+1}: {l.strip()}")

# --- الحذف الثلاثة المؤكدة (من dry-run v2) ---
sub1(r'^[ \t]*/// true: المايك يعمل بلغة الجهاز.*\n', '', 'حذف تعليق التوثيق اليتيم', 'المايك يعمل بلغة الجهاز')
sub1(r'^[ \t]*\?[ \t]*_rightSourceLanguage[ \t]*\n', '', 'حذف شظية ternary اليتيمة (871)', '_rightSourceLanguage')
sub1(r'^[ \t]*_rightSourceLanguage = preferences\.deviceLanguageCode;[ \t]*\n', '', 'حذف إسناد الحقل الميت (889)', '_rightSourceLanguage')

# --- التعبيران الكاملان (لا استبدال معرّف مفرد) ---
sub1(r'final expectedTargetLanguage = _sourceUsesDeviceLanguage\s*\?\s*_leftTargetLanguage\s*:\s*currentDeviceLanguage\s*;',
     'final expectedTargetLanguage = _dialogueRightLanguage;', 'expectedTargetLanguage (1031)', 'expectedTargetLanguage')
sub1(r'languageCode:\s*_sourceUsesDeviceLanguage\s*\?\s*_leftTargetLanguage\s*:\s*context\.read<LanguagePreferences>\(\)\.deviceLanguageCode\s*,',
     'languageCode: _dialogueRightLanguage,', 'لغة النطق (1053)', 'languageCode: _sourceUsesDeviceLanguage')

# --- التسميات الأربع + languageCode العرض (مفاتيح مميزة بدل نص كامل) ---
sub1(r"label:\s*_dialogueLeftLanguage\s*\?\s*'[^']*المحرر العلوي[^']*'\s*:\s*'[^']*'\s*,",
     "label: 'المحرر العلوي — لغة المايك',", 'label المحرر العلوي', 'المحرر العلوي')
sub1(r"hint:\s*_dialogueLeftLanguage\s*\?\s*'[^']*اكتب[^']*'\s*:\s*'[^']*'\s*,",
     "hint: 'اكتب أو تحدث بلغة المايك…',", 'hint المحرر العلوي', 'اكتب أو تحدث')
sub1(r"(_DeviceSpeechLanguageLabel\s*\(\s*)languageCode:\s*deviceLanguage\s*,",
     r"\1languageCode: _dialogueLeftLanguage,", 'languageCode العرض الأيسر', '_DeviceSpeechLanguageLabel')
sub1(r"label:\s*_dialogueLeftLanguage\s*\?\s*'مصدر المايك الآن'\s*:\s*'لغة الترجمة الآن'\s*,",
     "label: 'مصدر المايك الآن',", 'label العرض الأيسر', 'مصدر المايك الآن')
sub1(r"label:\s*_dialogueLeftLanguage\s*\?\s*'لغة الترجمة الآن'\s*:\s*'مصدر المايك الآن'\s*,",
     "label: 'لغة الترجمة الآن',", 'label القائمة اليمنى', 'لغة الترجمة الآن')

# --- deviceLanguage اليتيم داخل لوحة الحوار فقط ---
start = s.index('class _DialoguePanelState')
nxt = s.find('\nclass ', start + 10)
end = nxt + 1 if nxt != -1 else len(s)
region = s[start:end]
decl_re = re.compile(r'^[ \t]*final deviceLanguage = context\.(?:read|watch)<LanguagePreferences>\(\)\.deviceLanguageCode;[ \t]*\n', re.M)
while True:
    refs = re.findall(r'\bdeviceLanguage\b', region)
    if decl_re.search(region) and len(refs) == len(decl_re.findall(region)):
        region = decl_re.sub('', region, count=1); print('OK  : حذف تعريف deviceLanguage يتيم')
    else:
        break
s = s[:start] + region + s[end:]

# --- بوابة نهائية ---
counts = {t: len(re.findall(rf'\b{t}\b', s)) for t in
          ('_sourceUsesDeviceLanguage', '_leftTargetLanguage', '_rightSourceLanguage')}
bad = len(re.findall(r'_dialogueLeftLanguage\s*\?', s))
print(f'مراجع متبقية: {counts} (المطلوب: كلها 0)')
print(f'شروط bool على _dialogueLeftLanguage: {bad} (المطلوب 0)')
print(f"توازن الأقواس: {s.count('{') - s.count('}')}")
if fails or any(counts.values()) or bad != 0:
    print('توقف — لا كتابة. أرسل هذا التقرير كاملاً.'); sys.exit(1)

if APPLY:
    FILE.write_text(s, encoding='utf-8'); print('OK: كُتب الملف')
else:
    print('DRY-RUN — أضف --apply')
