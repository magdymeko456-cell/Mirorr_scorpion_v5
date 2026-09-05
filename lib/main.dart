import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'app/mirror_scorpion_app.dart';
import 'core/localization/language_preferences.dart';
import 'core/platform/android_overlay_service.dart';
import 'core/platform/shared_text_inbox.dart';
import 'core/pro/premium_verification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp();
  }
  final premiumService = PremiumVerificationService();
  await premiumService.initialize();
  final languagePreferences = LanguagePreferences();
  await languagePreferences.initialize();
  final sharedTextInbox = SharedTextInbox();
  await sharedTextInbox.initialize();
  final androidOverlayService = AndroidOverlayService();
  await androidOverlayService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: premiumService),
      ],
      child: MirrorScorpionApp(
        languagePreferences: languagePreferences,
        sharedTextInbox: sharedTextInbox,
        androidOverlayService: androidOverlayService,
      ),
    ),
  );
}

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MirrorScorpionOverlayApp());
}
