#!/usr/bin/env python3
"""v2 — يرقّع فجوة v1: جرد المراجع المعلّقة لـ _rightSourceLanguage.
- يحذف كل أسطر تعريف الحقل الميت (الأصلية والمكررة) في الذاكرة دائماً، ويُبقي تعليق التوثيق.
- أي مرجع متبقٍّ = توقف مع طباعة سياقه ±3 — لا تخمين.
- _sourceUsesDeviceLanguage ذكياً: حقل موجود = إعادة كتابته false؛ لا حقل = getter انتقالي.
dry-run إجباري. لا كتابة بدون --apply.
Usage: python scripts/fix_dialogue_decoupling_v2.py [--apply]
"""
import pathlib, re, sys

FILE = pathlib.Path('lib/features/feature_hub_screen.dart')
APPLY = '--apply' in sys.argv
report = print

lines = FILE.read_text(encoding='utf-8').splitlines(keepends=True)

STRING_DECL = re.compile(r'^\s*String\s+_rightSourceLanguage\s*=\s*.*;\s*$')
DEVICE_FIELD = re.compile(r'^\s*(?:bool|final)\s+_sourceUsesDeviceLanguage\s*=')
DEVICE_GETTER = re.compile(r'bool\s+get\s+_sourceUsesDeviceLanguage')
ANCHOR = 'class _DialoguePanelState extends State<_DialoguePanel> {'

# ---------- أ: حذف أسطر التعريف الميت (كلها، في الذاكرة) ----------
drop = [i for i, l in enumerate(lines) if STRING_DECL.match(l.rstrip('\n'))]
for i in drop:
    report(f"A: حذف سطر التعريف {i+1}: {lines[i].rstrip()}")
for i in sorted(drop, reverse=True):
    del lines[i]
if not drop:
    report("A: SKIP — لا توجد أسطر تعريف")

# ماذا يوثّق تعليق /// الآن؟ (تأكيد أنه بقي فوق حقل موجود)
for i, l in enumerate(lines):
    if l.strip().startswith('///') and 'المايك' in l:
        report(f"A+: تعليق التوثيق سطر {i+1}: {l.strip()}")
        if i + 1 < len(lines):
            report(f"A+: السطر الذي يوثّقه الآن: {lines[i+1].rstrip()}")

# ---------- أ2: جرد المراجع المتبقية — توقف بسياق كامل ----------
refs = [(i, l) for i, l in enumerate(lines) if '_rightSourceLanguage' in l]
for i, l in refs:
    report(f"A2: مرجع متبقٍّ سطر {i+1}: {l.strip()}")
if refs:
    report("A3: توقف — مراجع قراءة/إسناد لا يمكنني تخمين معناها. أرسل لي المخرجات كاملة:")
    for i, _ in refs:
        st = max(0, i-3); en = min(len(lines), i+4)
        report(f"  --- حول سطر {i+1} ---")
        for j in range(st, en):
            report(f"    {j+1}: {lines[j].rstrip()}")
    sys.exit(1)

# ---------- ب: بقايای _leftTargetLanguage ----------
joined = ''.join(lines)
n_lt = len(re.findall(r'\b_leftTargetLanguage\b', joined))
if n_lt:
    report(f"ب: تحويل _leftTargetLanguage → _dialogueRightLanguage ×{n_lt}")
    joined = joined.replace('_leftTargetLanguage', '_dialogueRightLanguage')
    lines = joined.splitlines(keepends=True)

# ---------- ج: _sourceUsesDeviceLanguage — حقل موجود = false؛ وإلا getter انتقالي ----------
dev = [(i, l) for i, l in enumerate(lines) if DEVICE_FIELD.match(l.rstrip('\n'))]
if dev:
    for i, l in dev:
        report(f"ج: الحقل سطر {i+1} سيعاد كتابته إلى false (كان: {l.strip()})")
    if APPLY:
        for i, _ in sorted(dev, reverse=True):
            indent = re.match(r'^(\s*)', lines[i]).group(1)
            lines[i] = f"{indent}bool _sourceUsesDeviceLanguage = false;\n"
else:
    joined = ''.join(lines)
    if DEVICE_GETTER.search(joined):
        report("ج: getter موجود مسبقاً — لا إدخال مكرر")
    elif ANCHOR in joined:
        report("ج: إدخال getter انتقالي (false) بعد مرساة الكلاس")
        if APPLY:
            idx = joined.index(ANCHOR) + len(ANCHOR)
            shim = ("\n  // TRANSITIONAL SHIM (يُحذف مع مرحلة التوطين):\n"
                    "  bool get _sourceUsesDeviceLanguage => false;\n")
            joined = joined[:idx] + shim + joined[idx:]
            lines = joined.splitlines(keepends=True)
    else:
        report("ج: توقف — لا حقل ولا مرساة. أرسل ناتج: grep -n '_sourceUsesDeviceLanguage' lib/features/feature_hub_screen.dart")
        sys.exit(1)

# ---------- د: deviceLanguage اليتيم ----------
joined = ''.join(lines)
ORPH = re.compile(r'^\s*final deviceLanguage = context\.read<LanguagePreferences>\(\)\.deviceLanguageCode;\s*\n', re.M)
wo = ORPH.sub('', joined)
if not re.search(r'\bdeviceLanguage\b', wo):
    report("د: حذف تعريف deviceLanguage اليتيم")
    if APPLY:
        joined = wo
        lines = joined.splitlines(keepends=True)
else:
    report("د: SKIP — deviceLanguage يُقرأ في فروع ميتة زمنياً (متوقع — يُحذف في مرحلة التوطين)")

# ---------- التحقق ----------
joined = ''.join(lines)
remaining = {t: len(re.findall(rf'\b{t}\b', joined))
             for t in ('_sourceUsesDeviceLanguage', '_leftTargetLanguage', '_rightSourceLanguage')}
report(f"المراجع المتبقية: {remaining}")
report("المتوقع: _rightSourceLanguage=0، _leftTargetLanguage=0، _sourceUsesDeviceLanguage=3 (تعريف انتقالي + شرطان ميتان زمنياً)")
braces = joined.count('{') - joined.count('}')
report(f"توازن الأقواس: {'سليم' if braces == 0 else 'غير متوازن — توقف!'}")
if braces != 0:
    sys.exit(1)

if APPLY:
    FILE.write_text(joined, encoding='utf-8')
    report("OK: كُتب الملف — راجع diff ثم ارفع")
else:
    report("DRY-RUN فقط — أضف --apply")
