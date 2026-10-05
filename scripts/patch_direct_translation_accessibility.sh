#!/usr/bin/env bash
set -euo pipefail

# Android is generated in CI by flutter create. This patch adds the native
# opt-in Accessibility bridge after generation, without reading any app until
# the user enables the service and selects an allowlisted package.
MANIFEST=android/app/src/main/AndroidManifest.xml
MAIN_ACTIVITY=$(find android/app/src/main/kotlin -type f -name MainActivity.kt -print -quit)
test -n "$MAIN_ACTIVITY" || { echo 'MainActivity.kt was not generated.'; exit 1; }
PACKAGE_NAME=$(sed -n 's/^package[[:space:]]\+//p' "$MAIN_ACTIVITY" | head -n 1)
test -n "$PACKAGE_NAME" || { echo 'MainActivity.kt has no package declaration.'; exit 1; }
PACKAGE_PATH=${PACKAGE_NAME//./\/}
JAVA_DIR="android/app/src/main/java/$PACKAGE_PATH"
mkdir -p "$JAVA_DIR" android/app/src/main/res/xml

cat > android/app/src/main/res/xml/mirror_scorpion_accessibility_service.xml <<'EOF'
<?xml version="1.0" encoding="utf-8"?>
<accessibility-service xmlns:android="http://schemas.android.com/apk/res/android"
    android:accessibilityEventTypes="typeWindowStateChanged|typeWindowContentChanged|typeViewTextChanged"
    android:accessibilityFeedbackType="feedbackGeneric"
    android:notificationTimeout="100"
    android:canRetrieveWindowContent="true"
    android:description="يقرأ النص الظاهر فقط من التطبيقات التي يختارها المستخدم لوضع الترجمة فوقه."
    android:accessibilityFlags="flagReportViewIds|flagRetrieveInteractiveWindows" />
EOF

cat > "$JAVA_DIR/MirrorAccessibilityService.java" <<EOF
package $PACKAGE_NAME;

import android.accessibilityservice.AccessibilityService;
import android.graphics.Color;
import android.graphics.Rect;
import android.graphics.PixelFormat;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.WindowManager;
import android.view.accessibility.AccessibilityEvent;
import android.view.accessibility.AccessibilityNodeInfo;
import android.widget.TextView;
import java.util.HashSet;
import java.util.Set;

public class MirrorAccessibilityService extends AccessibilityService {
    private static final String PREFS = "mirror_scorpion_direct";
    private final Handler handler = new Handler(Looper.getMainLooper());
    private WindowManager windowManager;
    private TextView translationView;
    private int lastGeneration = 0;
    private String lastCapturedText = "";
    private String lastCapturedPackage = "";

    @Override public void onServiceConnected() {
        super.onServiceConnected();
        windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
        handler.post(pollTranslation);
    }

    @Override public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null) return;
        final String packageName = event.getPackageName() == null ? "" : event.getPackageName().toString();
        Set<String> allowed = allowedPackages();
        if (packageName.isEmpty() || !allowed.contains(packageName)) return;
        AccessibilityNodeInfo root = getRootInActiveWindow();
        if (root == null) return;
        AccessibilityNodeInfo candidate = findReadableText(root);
        if (candidate == null) return;
        String text = candidate.getText() == null ? "" : candidate.getText().toString().trim();
        if (text.length() < 3 || text.length() > 1800 || candidate.isPassword()) return;
        if (text.equals(lastCapturedText) && packageName.equals(lastCapturedPackage)) return;
        lastCapturedText = text;
        lastCapturedPackage = packageName;
        Rect bounds = new Rect();
        candidate.getBoundsInScreen(bounds);
        if (bounds.width() <= 0 || bounds.height() <= 0) return;
        int generation = getSharedPreferences(PREFS, MODE_PRIVATE).getInt("generation", 0) + 1;
        getSharedPreferences(PREFS, MODE_PRIVATE).edit()
            .putString("text", text)
            .putString("package", packageName)
            .putInt("generation", generation)
            .putInt("left", bounds.left).putInt("top", bounds.top)
            .putInt("right", bounds.right).putInt("bottom", bounds.bottom)
            .remove("translation").apply();
        showTranslation("جارٍ الترجمة…", bounds);
    }

    private AccessibilityNodeInfo findReadableText(AccessibilityNodeInfo node) {
        if (node == null || node.isPassword()) return null;
        CharSequence text = node.getText();
        if (text != null && text.toString().trim().length() >= 3 && text.toString().trim().length() <= 1800) return node;
        for (int i = 0; i < node.getChildCount(); i++) {
            AccessibilityNodeInfo found = findReadableText(node.getChild(i));
            if (found != null) return found;
        }
        return null;
    }

    private Set<String> allowedPackages() {
        Set<String> result = new HashSet<>();
        result.addAll(getSharedPreferences(PREFS, MODE_PRIVATE).getStringSet("allowedPackages", new HashSet<String>()));
        return result;
    }

    private final Runnable pollTranslation = new Runnable() {
        @Override public void run() {
            android.content.SharedPreferences prefs = getSharedPreferences(PREFS, MODE_PRIVATE);
            int generation = prefs.getInt("translationGeneration", 0);
            String translation = prefs.getString("translation", "");
            if (generation == lastGeneration || translation == null || translation.trim().isEmpty()) {
                handler.postDelayed(this, 450);
                return;
            }
            lastGeneration = generation;
            Rect bounds = new Rect(prefs.getInt("left", 20), prefs.getInt("top", 120), prefs.getInt("right", 320), prefs.getInt("bottom", 180));
            showTranslation(translation, bounds);
            handler.postDelayed(this, 450);
        }
    };

    private void showTranslation(String text, Rect bounds) {
        if (windowManager == null) return;
        if (translationView == null) {
            translationView = new TextView(this);
            translationView.setTextColor(Color.WHITE);
            translationView.setTextSize(14);
            translationView.setGravity(Gravity.CENTER);
            translationView.setPadding(14, 8, 14, 8);
            translationView.setBackgroundColor(Color.rgb(16, 40, 64));
        }
        translationView.setText(text);
        WindowManager.LayoutParams params = new WindowManager.LayoutParams(
            Math.max(220, Math.min(900, bounds.width())), WindowManager.LayoutParams.WRAP_CONTENT,
            android.os.Build.VERSION.SDK_INT >= 26 ? WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY : WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT);
        params.gravity = Gravity.TOP | Gravity.LEFT;
        params.x = Math.max(0, bounds.left);
        params.y = Math.max(0, bounds.top - 90);
        try {
            if (translationView.getWindowToken() == null) windowManager.addView(translationView, params);
            else windowManager.updateViewLayout(translationView, params);
        } catch (Exception ignored) {}
    }

    private void removeTranslation() {
        if (translationView != null && windowManager != null) {
            try { windowManager.removeView(translationView); } catch (Exception ignored) {}
            translationView = null;
        }
    }

    @Override public void onInterrupt() { removeTranslation(); }
    @Override public boolean onUnbind(android.content.Intent intent) { removeTranslation(); handler.removeCallbacksAndMessages(null); return super.onUnbind(intent); }
}
EOF

cat > "$MAIN_ACTIVITY" <<EOF
package $PACKAGE_NAME

import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Context
import android.content.Intent
import android.app.ActivityManager
import android.os.Build
import android.provider.Settings
import android.os.StatFs
import android.view.accessibility.AccessibilityManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val directChannel = "mirror_scorpion/direct_translation"
    private val directPrefs = "mirror_scorpion_direct"
    private val serviceName = "$PACKAGE_NAME.MirrorAccessibilityService"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mirror_scorpion/device_capabilities").setMethodCallHandler { call, result ->
            if (call.method != "inspect") { result.notImplemented(); return@setMethodCallHandler }
            val manager = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val memory = ActivityManager.MemoryInfo()
            manager.getMemoryInfo(memory)
            val storage = StatFs(filesDir.absolutePath)
            result.success(mapOf(
                "totalRamBytes" to memory.totalMem,
                "availableRamBytes" to memory.availMem,
                "availableStorageBytes" to storage.availableBytes,
                "supportedAbis" to Build.SUPPORTED_ABIS.toList()
            ))
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, directChannel).setMethodCallHandler { call, result ->
            val prefs = getSharedPreferences(directPrefs, Context.MODE_PRIVATE)
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    val manager = getSystemService(Context.ACCESSIBILITY_SERVICE) as AccessibilityManager
                    val enabled = manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)
                        .any { it.resolveInfo.serviceInfo.packageName == packageName && it.resolveInfo.serviceInfo.name == serviceName }
                    result.success(enabled)
                }
                "openAccessibilitySettings" -> { startActivity(Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)); result.success(null) }
                "getAllowedPackages" -> result.success(prefs.getStringSet("allowedPackages", emptySet<String>())?.toList() ?: emptyList<String>())
                "setAllowedPackages" -> {
                    val packages = (call.arguments as? List<*>)?.filterIsInstance<String>()?.toSet() ?: emptySet()
                    prefs.edit().putStringSet("allowedPackages", packages).apply(); result.success(null)
                }
                "setTargetLanguage" -> { prefs.edit().putString("targetLanguage", call.arguments as? String ?: "ar").apply(); result.success(null) }
                "disableDirectCapture" -> { prefs.edit().remove("text").remove("translation").putInt("translationGeneration", 0).apply(); result.success(null) }
                else -> result.notImplemented()
            }
        }
    }
}
EOF

if ! grep -q 'MirrorAccessibilityService' "$MANIFEST"; then
  awk '/<\/application>/ { print "        <service android:name=\".MirrorAccessibilityService\" android:permission=\"android.permission.BIND_ACCESSIBILITY_SERVICE\" android:exported=\"true\">"; print "            <intent-filter><action android:name=\"android.accessibilityservice.AccessibilityService\" /></intent-filter>"; print "            <meta-data android:name=\"android.accessibilityservice\" android:resource=\"@xml/mirror_scorpion_accessibility_service\" />"; print "        </service>" } { print }' "$MANIFEST" > "$MANIFEST.tmp"
  mv "$MANIFEST.tmp" "$MANIFEST"
fi

grep -q 'MirrorAccessibilityService' "$MAIN_ACTIVITY"
grep -q 'mirror_scorpion_accessibility_service' "$MANIFEST"
