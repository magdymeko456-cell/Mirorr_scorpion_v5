#!/usr/bin/env bash
set -euo pipefail

# مشروع Android مولّد في CI، لذلك يحفظ هذا الجسر بعد flutter create. لا يعيد
# الجسر إلا RAM والمساحة الحرة وABI لفحص المستخدم قبل بدء تفريغ محلي كثيف.
MAIN_ACTIVITY=$(find android/app/src/main/kotlin -type f -name MainActivity.kt -print -quit)
test -n "$MAIN_ACTIVITY" || { echo 'MainActivity.kt was not generated.'; exit 1; }
if grep -q 'mirror_scorpion/device_capabilities' "$MAIN_ACTIVITY"; then exit 0; fi
PACKAGE_NAME=$(sed -n 's/^package[[:space:]]\+//p' "$MAIN_ACTIVITY" | head -n 1)
test -n "$PACKAGE_NAME" || { echo 'MainActivity.kt has no package declaration.'; exit 1; }

cat > "$MAIN_ACTIVITY" <<EOF
package $PACKAGE_NAME

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "mirror_scorpion/device_capabilities")
            .setMethodCallHandler { call, result ->
                if (call.method != "inspect") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
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
    }
}
EOF
grep -q 'mirror_scorpion/device_capabilities' "$MAIN_ACTIVITY" || { echo 'Bridge injection failed.'; exit 1; }
