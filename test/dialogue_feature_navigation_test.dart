import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/core/localization/language_preferences.dart';
import 'package:mirror_scorpion_v4/l10n/generated/app_localizations.dart';
import 'package:mirror_scorpion_v4/core/speech/device_speech_recognition_service.dart';
import 'package:mirror_scorpion_v4/features/feature_hub_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('dialogue feature opens with the app recognition lifecycle', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => LanguagePreferences(deviceLocale: const Locale('ar')),
          ),
          ChangeNotifierProvider(create: (_) => DeviceSpeechRecognitionService()),
        ],
        child: MaterialApp(
          locale: const Locale('ar'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const FeatureHubScreen(kind: FeatureKind.dialogue),
        ),
      ),
    );

    expect(find.text('المحرر العلوي — لغة المايك'), findsOneWidget);
    expect(find.byTooltip('تبديل المتحدث ولغة المايك'), findsOneWidget);
  });
}
