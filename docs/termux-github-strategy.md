# استراتيجية إعادة البناء عبر Termux وGitHub Actions لمشروع Mirror Scorpion v3

## نظرة عامة
تعتمد هذه الاستراتيجية على فصل بيئة التحرير عن بيئة التجميع لتجنب حدود الموارد ونقص أدوات Android SDK داخل بيئة التحرير المحلية (Termux أو Sandbox). يقوم المستخدم بالتحرير وإدارة الملفات عبر Termux، بينما تتولى منصة GitHub Actions (مع بيئة Java 17 وAndroid SDK 34) عملية بناء الـ APK بشكل آلي ومستقر.

---

## 1. السكربت الآمن لإعادة الهيكلة والرفع (Termux / Bash)
يمكن حفظ هذا السكربت باسم `reset_and_push.sh` داخل مستودع المشروع في Termux وتشغيله لتنظيم الأكواد، أخذ نسخة احتياطية آمنة، وتنظيف الملفات المؤقتة ثم الرفع إلى GitHub:

```bash
#!/usr/bin/env bash
# ==============================================================================
# Mirror Scorpion v3 - Termux Safe Reset & Git Push Workflow
# ==============================================================================
set -Eeuo pipefail

C_CYN='\033[0;36m'; C_GRN='\033[0;32m'; C_YEL='\033[0;33m'; C_END='\033[0m'
log() { echo -e "${C_CYN}[MIRROR-V3]${C_END} $*"; }
ok()  { echo -e "${C_GRN}  [✔] $*${C_END}"; }
warn(){ echo -e "${C_YEL}  [!] $*${C_END}"; }

WORKDIR="${MIRROR_WORKDIR:-$HOME/mirror_scorpion_mobile_v3}"
BACKUP_DIR="${MIRROR_BACKUP_DIR:-$HOME/ms_v3_backup}"

for required in git pnpm npx; do
    if ! command -v "$required" >/dev/null 2>&1; then
        warn "الأداة المطلوبة غير موجودة: $required"
        exit 1
    fi
done

if [ ! -d "$WORKDIR" ]; then
    warn "مجلد المشروع غير موجود في المسار المتوقع: $WORKDIR"
    exit 1
fi
cd "$WORKDIR"

log "1/4. أخذ نسخة احتياطية للملفات الحيوية (lib, app.config.ts, assets, modules, package.json)..."
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
[ -d "lib" ] && cp -r lib "$BACKUP_DIR/"
[ -d "modules" ] && cp -r modules "$BACKUP_DIR/"
[ -d "assets" ] && cp -r assets "$BACKUP_DIR/"
[ -f "app.config.ts" ] && cp app.config.ts "$BACKUP_DIR/"
[ -f "package.json" ] && cp package.json "$BACKUP_DIR/"
ok "تم حفظ النسخة الاحتياطية بنجاح."

log "2/4. تنظيف المخلفات وملفات الكاش المؤقتة..."
rm -rf .expo .metro .git/index.lock .dart_tool build dist android/.gradle android/build android/app/build ios/build node_modules/.cache 2>/dev/null || true
ok "تم التنظيف بنجاح."

log "3/4. استعادة الموارد والأكواد وتحديث المستودع المحلي..."
[ -d "$BACKUP_DIR/lib" ] && cp -r "$BACKUP_DIR/lib" ./
[ -d "$BACKUP_DIR/modules" ] && cp -r "$BACKUP_DIR/modules" ./
[ -d "$BACKUP_DIR/assets" ] && cp -r "$BACKUP_DIR/assets" ./
[ -f "$BACKUP_DIR/app.config.ts" ] && cp "$BACKUP_DIR/app.config.ts" ./
[ -f "$BACKUP_DIR/package.json" ] && cp "$BACKUP_DIR/package.json" ./

if [ -f "package.json" ] && [ -f "pnpm-lock.yaml" ]; then
    pnpm install --lockfile-only
fi

if [ -f "app.config.ts" ] && [ -d "modules/floating-translator" ]; then
    npx expo prebuild --platform android --no-install
fi

git config http.postBuffer.json" ] && [ -f "pnpm-lock.yaml" ]; then
    pnpm install --lockfile-only
fi

if [ -f "app.config.ts" ] && [ -d "modules/floating-translator" ]; then
    npx expo prebuild --platform android --no-install
fi

git config http.postBuffer 524288000 2>/dev/null || true
CURRENT_BRANCH="$(git branch --show-current)"
if [ "$CURRENT_BRANCH" != "main" ]; then
    warn "الفرع الحالي هو $CURRENT_BRANCH وليس main؛ لن يتم الدفع لتجنب رفع غير مقصود."
    exit 1
fi

if ! git remote get-url origin >/dev/null 2>&1; then
    warn "لا يوجد remote باسم origin. أضفه أولاً ثم أعد التشغيل."
    exit 1
fi

git add -A
git commit -m "refactor(termux): sync Expo native structure and v3 modules" || echo "لا توجد تغييرات معلقة للالتزام"

log "4/4. دفع التحديثات إلى فرع الرئيسية في GitHub..."
if [ "${FORCE_PUSH:-0}" = "1" ]; then
    warn "FORCE_PUSH=1: سيتم استخدام force-with-lease وليس force العادي."
    git push origin main --force-with-lease
else
    git push origin main
fi
rm -rf "$BACKUP_DIR"

ok "تمت العملية بنجاح! راقب GitHub Actions الآن لبدء البناء الآلي للـ APK. 🦂🚀"
```

---

## 2. ملف GitHub Actions Workflow للبناء المستقر (Java 17 + Android SDK 34)
يتم وضع هذا الملف في المسار `.github/workflows/build_apk.yml`:

```yaml
name: Mirror Scorpion v3 APK Build

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 22

      - name: Setup Java 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Android SDK
        uses: android-actions/setup-android@v3

      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 9.12.0
          run_install: false

      - name: Install Dependencies
        run: pnpm install --frozen-lockfile=false

      - name: Run Expo Prebuild (Generate Native Android Boilerplate)
        run: npx expo prebuild --platform android --no-install

      - name: Build Android Release APK
        run: |
          cd android
          chmod +x gradlew
          ./gradlew assembleRelease --no-daemon

      - name: Upload APK Artifact
        uses: actions/upload-artifact@v4
        with:
          name: mirror-scorpion-v3-release
          path: android/app/build/outputs/apk/release/app-release.apk
```

---

## 3. الضمانات والتوافقات التي تم تثبيتها
1. **توحيد إصدار Java و Kotlin**: اعتماد Java 17 في Gradle وKotlin options لتجنب خطأ `compileReleaseKotlin` الذي واجهناه سابقاً.
2. **التعامل مع ملفات الموارد**: تجنب ملفات PNG التالفة أو غير الصالحة عبر استخدام أيقونات وتصميمات واضحة وتوافقية مع AAPT2.
3. **حماية التعديلات الأصلية**: لا يحذف السكربت مجلد `android`؛ ينظف مخرجات البناء فقط، ويعيد تشغيل Prebuild دون `--clean` حتى لا يفقد تعديلات MainActivity أو خدمة الفقاعة.
4. **فصل بيئة التحرير عن البناء**: Termux مخصص للتحرير الذكي وكتابة الأكواد والرفع، بينما GitHub Actions يتولى التجميع الكامل بوجود Android SDK الحقيقي.
