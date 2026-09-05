#!/usr/bin/env python3
"""v3 — الباتش الختامي لفصل لغات الحوار. مبني على النص الفعلي للمستودع.
كل عملية = تطابق واحد بالضبط؛ أي انحراف = توقف مع طباعة السياق. لا تخمين.
Usage: python scripts/fix_dialogue_decoupling_v3.py [--apply]
"""
import pathlib, re, sys

FILE = pathlib.Path('lib/features/feature_hub_screen.dart')
APPLY = '--apply' in sys.argv
s = FILE.read_text(encoding='utf-8')
ok = True

def show(token):
    lines = s.splitlines()
    for i, l in enumerate(lines):
        if token in l:
            print('  ---')
            for j in range(max(0, i-2), min(len(lines), i+3)):
                print(f"  {j+1}: {lines[j]}")

def sub1(pattern, repl, label, token):
    global s, ok
    new, n = re.subn(pattern, repl, s)
    if n == 1:
        print(f"OK: {label}"); s = new
    else:
        print(f"ABORT: {label} — تطابقات {n} (المتوقع 1). السياق:"); show(token); ok = False

def drop_line(pattern, label, token):
    global s, ok
    n = len(re.findall(pattern, s, flags=re.M))
    if n == 1:
        s = re.sub(pattern, '', s, count=1, flags=re.M); print(f"OK: حذف — {label}")
    else:
        print(f"ABORT: {label} — تطابقات {n} (المتوقع 1). السياق:"); show(token); ok = False

# ---------- حذف مؤكد (من dry-run v2) ----------
drop_line(r'^[ \t]*/// true: المايك يعمل بلغة الجهاز، false: المايك يعمل باللغة المقابلة\.\n',
          'تعليق التوثيق اليتيم (862)', 'المايك يعمل بلغة الجهاز')
drop_line(r'^[ \t]*\?[ \t]*_rightSourceLanguage[ \t]*\n',
          'شظية ternary اليتيمة (871)', '_rightSourceLanguage')
drop_line(r'^[ \t]*_rightSourceLanguage = preferences\.deviceLanguageCode;[ \t]*\n',
          'إسناد الحقل الميت في initState (889)', '_rightSourceLanguage')

# ---------- استبدال ternaries كاملة (من sed الفعلي) ----------
sub1(r'final expectedTargetLanguage = _sourceUsesDeviceLanguage\s*\?\s*_leftTargetLanguage\s*:\s*currentDeviceLanguage;',
     'final expectedTargetLanguage = _dialogueRightLanguage;',
     'expectedTargetLanguage (1031-1033)', 'expectedTargetLanguage')
sub1(r'languageCode: _sourceUsesDeviceLanguage\s*\?\s*_leftTargetLanguage\s*:\s*context\.read<LanguagePreferences>\(\)\.deviceLanguageCode,',
     'languageCode: _dialogueRightLanguage,',
     'لغة النطق (1053-1056)', '_sourceUsesDeviceLanguage')

# ---------- التسميات الأربع (non_bool_condition) ----------
sub1(r"label: _dialogueLeftLanguage\s*\?\s*'المحرر العلوي — المتحدث بلغة الجهاز'\s*:\s*'المحرر العلوي — المتحدث باللغة المقابلة',",
     "label: 'المحرر العلوي — لغة المايك',",
     'label المحرر العلوي', 'المحرر العلوي')
sub1(r"hint: _dialogueLeftLanguage\s*\?\s*'اكتب أو تحدث بلغة جهازك…'\s*:\s*'اكتب أو تحدث باللغة المقابلة…',",
     "hint: 'اكتب أو تحدث بلغة المايك…',",
     'hint المحرر العلوي', 'اكتب أو تحدث')
sub1(r"(_DeviceSpeechLanguageLabel\(\s*)languageCode: deviceLanguage,",
     r"\1languageCode: _dialogueLeftLanguage,",
     'languageCode العرض الأيسر (يُظهر لغة المايك الفعلية)', '_DeviceSpeechLanguageLabel(')
sub1(r"label: _dialogueLeftLanguage\s*\?\s*'مصدر المايك الآن'\s*:\s*'لغة الترجمة الآن',",
     "label: 'مصدر المايك الآن',",
     'label العرض الأيسر', 'مصدر المايك الآن')
sub1(r"label: _dialogueLeftLanguage\s*\?\s*'لغة الترجمة الآن'\s*:\s*'مصدر المايك الآن',",
     "label: 'لغة الترجمة الآن',",
     'label القائمة اليمنى', 'لغة الترجمة الآن')

# ---------- حذف تعريفات deviceLanguage اليتيمة داخل لوحة الحوار فقط ----------
if ok:
    start = s.index('class _DialoguePanelState')
    nxt = s.find('\nclass ', start + 10)
    end = nxt + 1 if nxt != -1 else len(s)
    region = s[start:end]
    decl_re = re.compile(r'^[ \t]*final deviceLanguage = context\.(?:read|watch)<LanguagePreferences>\(\)\.deviceLanguageCode;[ \t]*\n', re.M)
    while True:
        refs = re.findall(r'\bdeviceLanguage\b', region)
        decls = decl_re.findall(region)
        if decls and len(refs) == len(decls):   # كل المراجع هي التعريفات نفسها = يتيمة
            region = decl_re.sub('', region, count=1)
            print('OK: حذف تعريف deviceLanguage يتيم داخل لوحة الحوار')
        else:
            break
    s = s[:start] + region + s[end:]
    left = len(re.findall(r'\bdeviceLanguage\b', region))
    print(f'مراجع deviceLanguage المتبقية في لوحة الحوار: {left} (المتوقع 0)')

# ---------- تحقق نهائي ----------
counts = {t: len(re.findall(rf'\b{t}\b', s)) for t in (
    '_sourceUsesDeviceLanguage', '_leftTargetLanguage', '_rightSourceLanguage', 'currentDeviceLanguage')}
print(f'المراجع المتبقية: {counts} (المتوقع: كلها 0)')
bad = len(re.findall(r'_dialogueLeftLanguage\s*\?', s))
print(f'شروط bool على _dialogueLeftLanguage: {bad} (المتوقع 0)')
braces = s.count('{') - s.count('}')
print(f"توازن الأقواس: {'سليم' if braces == 0 else 'غير متوازن — توقف!'}")
if not ok or braces != 0 or bad != 0 or any(counts.values()):
    print('توقف — لا كتابة. أرسل المخرجات كاملة.'); sys.exit(1)

if APPLY:
    FILE.write_text(s, encoding='utf-8')
    print('OK: كُتب الملف — راجع diff ثم ارفع')
else:
    print('DRY-RUN فقط — أضف --apply')
