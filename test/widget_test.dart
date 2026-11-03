import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/app/mirror_scorpion_app.dart';
import 'package:mirror_scorpion_v4/core/localization/language_preferences.dart';

void main() {
  testWidgets('boots the Royal Dark application shell', (tester) async {
    await tester.pumpWidget(
      MirrorScorpionApp(
        languagePreferences: LanguagePreferences(
          deviceLocale: const Locale('ar'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ميرور سكربيون'), findsOneWidget);
    expect(find.text('حيث تُصنع البدايات'), findsOneWidget);
  });
}
