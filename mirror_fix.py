#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
mirror_fix.py — أداة مزامنة/فحص/رفع لمستودع Mirorr_scorpion_v5 في ترمكس.
- لا تعدّل أي كود Dart تلقائياً بشكل عشوائي (حماية للبناء).
- مهمتها: سحب آخر نسخة، فحص تشخيصي دقيق للملفات الفعلية، ورفع آمن.
المكتبات: قياسية فقط. Python3 فقط.
"""
import sys, os, re, shutil, subprocess, datetime, argparse

REPO_URL   = "https://github.com/magdymeko456-cell/Mirorr_scorpion_v5.git"
LOCAL_DIR  = os.path.expanduser("~/Mirorr_scorpion_v5")
REMOTE     = "origin"
BASE_BRANCH = "main"
# ملف اختياري فيه الـ GitHub Token (سطر واحد) لتجنّب طلب كلمة السر كل مرة:
TOKEN_FILE = os.path.expanduser("~/.github_token")

ANSI = {"G": "\033[92m", "Y": "\033[93m", "R": "\033[91m", "C": "\033[96m", "0": "\033[0m"}
def p(tag, msg, color="C"):
    print(f"{ANSI[color]}[{tag}]{ANSI['0']} {msg}")

def run(cmd, cwd=None, check=True):
    p("RUN", cmd, "G")
    r = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
    if check and r.returncode != 0:
        p("ERR", (r.stderr or r.stdout).strip()[:800], "R")
        sys.exit(1)
    return r.stdout.strip()

def ensure_repo():
    if not os.path.isdir(os.path.join(LOCAL_DIR, ".git")):
        p("CLONE", f"استنساخ المستودع إلى {LOCAL_DIR} ...")
        run(f"git clone {REPO_URL} \"{LOCAL_DIR}\"")
    else:
        p("PULL", "سحب آخر تحديث من origin ...")
        run("git fetch --all --prune", cwd=LOCAL_DIR)
        run(f"git reset --hard {REMOTE}/{BASE_BRANCH}", cwd=LOCAL_DIR)
    p("OK", f"النسخة المحلية جاهزة في {LOCAL_DIR}", "G")

# ----------------------------- الفحص التشخيصي -----------------------------
# أنماط المشاكل المعروفة. يُقرأ الكود الفعلي فلا يُبنى الفحص على تخمين.
KNOWN_PATTERNS = [
    ("ربط المايك بلغة مثبّتة على الجهاز (جذر مشكلة 'اللغة غير مثبتة')",
     r"preferredLocaleId|installedLocaleIds|\.locales\(\)|SpeechLocaleResolver"),
    ("ربط/تخمين لغة إجبارية داخل الكود",
     r"Locale\(['\"]ar['\"]\)|supportedLocales\s*=|localeResolutionCallback"),
    ("استدعاء فوري للتعرف دون فحص جاهزية",
     r"_speechToText\.listen\(|speechToText\.listen\("),
    ("تغيير حالة/لغة أثناء استماع نشط (خطر تعارض الميكروفون)",
     r"isListening\s*&&|cancelAndWait|stopAndWait"),
    ("hardcode لنص عربي/إنجليزي (كسر للترجمة)",
     r"(?<![A-Za-z_])['\"][^'\"]*[\u0600-\u06FF][^'\"]*['\"]"),
    ("مفاتيح SharedPreferences بلا مساحة أسماء موحّدة",
     r"SharedPreferences\.getInstance|prefs\.getString|prefs\.setString"),
]

def walk_dart(base):
    out = []
    for root, _, files in os.walk(base):
        if "build" in root or ".dart_tool" in root:
            continue
        for f in files:
            if f.endswith(".dart"):
                out.append(os.path.join(root, f))
    return out

def audit():
    libdir = os.path.join(LOCAL_DIR, "lib")
    files = walk_dart(libdir)
    p("AUDIT", f"تم العثور على {len(files)} ملف Dart. قراءة الأنماط ...")
    report = []
    for fp in sorted(files):
        rel = os.path.relpath(fp, LOCAL_DIR)
        try:
            txt = open(fp, encoding="utf-8", errors="replace").read()
        except Exception as e:
            report.append(f"  ! تعذّر القراءة {rel}: {e}")
            continue
        for name, pat in KNOWN_PATTERNS:
            for m in re.finditer(pat, txt):
                line = txt[:m.start()].count("\n") + 1
                snippet = txt.splitlines()[line-1].strip()[:90]
                report.append(f"  * [{name}]\n      {rel}:{line}  →  {snippet}")
    # ملاحظة pubspec
    pub = os.path.join(LOCAL_DIR, "pubspec.yaml")
    if os.path.exists(pub):
        txt = open(pub, encoding="utf-8").read()
        name = re.search(r"^name:\s*(.+)$", txt, re.M)
        ver  = re.search(r"^version:\s*(.+)$", txt, re.M)
        p("PUB", f"الاسم داخل pubspec: {name.group(1) if name else '?'} | "
                 f"النسخة: {ver.group(1) if ver else '?'} | المستودع: v5", "Y")
    if not report:
        p("AUDIT", "لا توجد أنماط معروفة من المشاكل في الكود الحالي.", "G")
    else:
        p("AUDIT", f"عدد النتائج: {len(report)}\n" + "\n".join(report), "Y")
    # خلاصة فنية مهمة تُطبع دائماً
    p("NOTE",
      "رسالة 'اللغة غير مثبتة على جوجل' = خطأ نظام (حزمة لغة التعرف غير منزّلة "
      "على الهاتف). لا يُحل بتعديل نص. الحل المعماري = محرك داخل التطبيق (whisper_ggml "
      "موجود أصلاً في pubspec) أو تنبيه المستخدم لتحميل الحزمة من إعدادات Google.", "Y")

def make_backup_tag():
    tag = f"backup-{datetime.datetime.now():%Y%m%d-%H%M%S}"
    run(f"git tag -f {tag}", cwd=LOCAL_DIR)
    p("BACKUP", f"وُضعت علامة أمان: {tag} (يمكن الرجوع إليها بـ git checkout {tag})", "G")
    return tag

def commit_push(message):
    if message is None:
        message = f"mirror_fix audit {datetime.datetime.now():%Y-%m-%d %H:%M}"
    st = run("git status --porcelain", cwd=LOCAL_DIR)
    if not st:
        p("COMMIT", "لا توجد تغييرات لرفعها.", "Y")
        return
    make_backup_tag()
    run("git add -A", cwd=LOCAL_DIR)
    run(f"git commit -m {shlex_quote(message)}", cwd=LOCAL_DIR)
    push_url = REPO_URL
    if os.path.exists(TOKEN_FILE):
        tok = open(TOKEN_FILE).read().strip()
        if tok:
            push_url = REPO_URL.replace("https://", f"https://{tok}@")
    p("PUSH", "جارٍ الرفع إلى origin ...")
    run(f"git push {REMOTE} HEAD:{BASE_BRANCH}", cwd=LOCAL_DIR)
    p("DONE", "تم الرفع بنجاح. ستبدأ GitHub Actions البناء الآن.", "G")

def shlex_quote(s):
    return "'" + s.replace("'", "'\\''") + "'"

def main():
    ap = argparse.ArgumentParser(description="أداة Mirorr_scorpion_v5 في ترمكس")
    ap.add_argument("--audit", action="store_true", help="فحص فقط بدون أي تعديل أو رفع")
    ap.add_argument("--commit", metavar="MSG", nargs="?", const=None,
                    help="رفع التغييرات المحلية إلى main")
    args = ap.parse_args()
    ensure_repo()
    if args.audit:
        audit()
        p("INFO", "وضع الفحص: لم يتغيّر أي ملف ولم يُرفع شيء.", "G")
        return
    if args.commit is not None:
        audit()
        commit_push(args.commit)
        return
    ap.print_help()

if __name__ == "__main__":
    main()
