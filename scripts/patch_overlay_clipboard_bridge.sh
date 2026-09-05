#!/usr/bin/env bash
set -euo pipefail

# flutter_overlay_window يشغّل محرك Flutter مستقلاً للفقاعة، ولذلك لا يكون
# Clipboard من SystemChannels متاحاً دائماً. هذا الجسر يضيف قناة Android أصلية
# إلى محرك الفقاعة ولا تُستدعى إلا من زر «الصق النص» الذي ضغطه المستخدم.
PLUGIN_DIR=$(find "${PUB_CACHE:-$HOME/.pub-cache}/hosted/pub.dev" -maxdepth 1 \
  -type d -name 'flutter_overlay_window-0.5.0' -print -quit)
test -n "$PLUGIN_DIR" || {
  echo 'flutter_overlay_window 0.5.0 was not installed.'
  exit 1
}

SERVICE="$PLUGIN_DIR/android/src/main/java/flutter/overlay/window/flutter_overlay_window/OverlayService.java"
test -f "$SERVICE" || {
  echo 'OverlayService.java was not found.'
  exit 1
}

if grep -q 'mirror_scorpion/overlay_clipboard' "$SERVICE"; then
  exit 0
fi

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
    print "                if (!\"readUserRequestedText\".equals(call.method)) {"
    print "                    result.notImplemented();"
    print "                    return;"
    print "                }"
    print "                ClipboardManager clipboard = (ClipboardManager)"
    print "                        getSystemService(Context.CLIPBOARD_SERVICE);"
    print "                if (clipboard == null || !clipboard.hasPrimaryClip()"
    print "                        || clipboard.getPrimaryClip() == null"
    print "                        || clipboard.getPrimaryClip().getItemCount() == 0) {"
    print "                    result.success(\"\");"
    print "                    return;"
    print "                }"
    print "                CharSequence text = clipboard.getPrimaryClip()"
    print "                        .getItemAt(0).coerceToText(OverlayService.this);"
    print "                result.success(text == null ? \"\" : text.toString());"
    print "            });"
    next
  }
  { print }
' "$SERVICE" > "$TEMP_SERVICE"

grep -q 'mirror_scorpion/overlay_clipboard' "$TEMP_SERVICE" || {
  rm -f "$TEMP_SERVICE"
  echo 'Clipboard bridge injection did not match the plugin source.'
  exit 1
}
mv "$TEMP_SERVICE" "$SERVICE"
