#!/usr/bin/env bash
set -euo pipefail
PLUGIN_DIR=$(find "${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev" -maxdepth 1 -type d -name 'flutter_overlay_window-0.5.0' -print -quit)
test -n "$PLUGIN_DIR" || { echo 'flutter_overlay_window 0.5.0 was not installed.'; exit 1; }
SERVICE="$PLUGIN_DIR/android/src/main/java/flutter/overlay/window/flutter_overlay_window/OverlayService.java"
test -f "$SERVICE" || { echo 'OverlayService.java was not found.'; exit 1; }
if grep -q 'readDirectCapture' "$SERVICE"; then exit 0; fi
TEMP_SERVICE="$SERVICE.mirror-scorpion.tmp"
awk '
  /import android.content.Context;/ {
    print
    print "import android.content.ClipboardManager;"
    next
  }
  /private BasicMessageChannel<Object> overlayMessageChannel;/ {
    print
    print "    private MethodChannel mirrorClipboardChannel;"
    next
  }
  /overlayMessageChannel = new BasicMessageChannel\(flutterEngine.getDartExecutor\(\), OverlayConstants.MESSENGER_TAG, JSONMessageCodec.INSTANCE\);/ {
    print
    print "            mirrorClipboardChannel = new MethodChannel("
    print "                    flutterEngine.getDartExecutor(), \"mirror_scorpion/overlay_clipboard\");"
    print "            mirrorClipboardChannel.setMethodCallHandler((call, result) -> {"
    print "                if (\"readDirectCapture\".equals(call.method)) {"
    print "                    android.content.SharedPreferences p = getSharedPreferences(\"mirror_scorpion_direct\", MODE_PRIVATE);"
    print "                    java.util.HashMap<String, Object> payload = new java.util.HashMap<>();"
    print "                    payload.put(\"text\", p.getString(\"text\", \"\"));"
    print "                    payload.put(\"package\", p.getString(\"package\", \"\"));"
    print "                    payload.put(\"generation\", p.getInt(\"generation\", 0));"
    print "                    result.success(payload);"
    print "                    return;"
    print "                }"
    print "                if (\"writeDirectTranslation\".equals(call.method)) {"
    print "                    java.util.Map<?, ?> args = (java.util.Map<?, ?>) call.arguments;"
    print "                    String value = args == null || args.get(\"text\") == null ? \"\" : args.get(\"text\").toString();"
    print "                    int gen = args == null || args.get(\"generation\") == null ? 0 : ((Number) args.get(\"generation\")).intValue();"
    print "                    getSharedPreferences(\"mirror_scorpion_direct\", MODE_PRIVATE).edit().putString(\"translation\", value).putInt(\"translationGeneration\", gen).apply();"
    print "                    result.success(null);"
    print "                    return;"
    print "                }"
    print "                if (\"disableDirectCapture\".equals(call.method)) {"
    print "                    getSharedPreferences(\"mirror_scorpion_direct\", MODE_PRIVATE).edit().remove(\"text\").remove(\"translation\").putInt(\"translationGeneration\", 0).apply();"
    print "                    result.success(null);"
    print "                    return;"
    print "                }"
    print "                if (!\"readUserRequestedText\".equals(call.method)) {"
    print "                    result.notImplemented();"
    print "                    return;"
    print "                }"
    print "                ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);"
    print "                if (clipboard == null || !clipboard.hasPrimaryClip() || clipboard.getPrimaryClip() == null || clipboard.getPrimaryClip().getItemCount() == 0) {"
    print "                    result.success(\"\");"
    print "                    return;"
    print "                }"
    print "                CharSequence text = clipboard.getPrimaryClip().getItemAt(0).coerceToText(OverlayService.this);"
    print "                result.success(text == null ? \"\" : text.toString());"
    print "            });"
    next
  }
  { print }
' "$SERVICE" > "$TEMP_SERVICE"
grep -q 'readDirectCapture' "$TEMP_SERVICE" || { rm -f "$TEMP_SERVICE"; echo 'Overlay bridge injection did not match plugin source.'; exit 1; }
mv "$TEMP_SERVICE" "$SERVICE"
