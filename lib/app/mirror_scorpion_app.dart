import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:provider/provider.dart';

import '../core/localization/language_preferences.dart';
import '../core/localization/supported_app_locales.dart';
import '../core/media/runware_video_service.dart';
import '../core/platform/android_overlay_service.dart';
import '../core/platform/shared_text_inbox.dart';
import '../core/speech/device_speech_recognition_service.dart';
import '../core/speech/elevenlabs_voice_service.dart';
import '../features/home/dashboard_screen.dart';
import 'royal_dark_theme.dart';

class MirrorScorpionApp extends StatelessWidget {
  const MirrorScorpionApp({
    this.languagePreferences,
    this.sharedTextInbox,
    this.androidOverlayService,
    super.key,
  });

  final LanguagePreferences? languagePreferences;
  final SharedTextInbox? sharedTextInbox;
  final AndroidOverlayService? androidOverlayService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguagePreferences>.value(
          value: languagePreferences ?? LanguagePreferences(),
        ),
        ChangeNotifierProvider(create: (_) => ElevenLabsVoiceService()),
        ChangeNotifierProvider(create: (_) => RunwareVideoService()),
        ChangeNotifierProvider(create: (_) => DeviceSpeechRecognitionService()),
        ChangeNotifierProvider<AndroidOverlayService>.value(
          value: androidOverlayService ?? AndroidOverlayService(),
        ),
        ChangeNotifierProvider<SharedTextInbox>.value(
          value: sharedTextInbox ?? SharedTextInbox(),
        ),
      ],
      child: Builder(
        builder: (context) {
          final preferences = context.watch<LanguagePreferences>();
          return MaterialApp(
            title: 'Mirror Scorpion v4',
            debugShowCheckedModeBanner: false,
            theme: royalDarkTheme(),
            locale: preferences.deviceLocale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: {
              ...kMirrorScorpionSupportedLocales,
              ...AppLocalizations.supportedLocales,
            }.toList(growable: false),
            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}
