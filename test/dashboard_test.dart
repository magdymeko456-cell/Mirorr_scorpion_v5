import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/app/mirror_scorpion_app.dart';
import 'package:mirror_scorpion_v4/core/localization/language_preferences.dart';

void main() {
  testWidgets('renders the truthful hero status and the six-card grid', (tester) async {
    await tester.pumpWidget(
      MirrorScorpionApp(
        languagePreferences: LanguagePreferences(
          deviceLocale: const Locale('ar'),
        ),
      ),
    );
    // Dashboard has an intentionally repeating pulse animation, so it never
    // reaches the settled state required by pumpAndSettle(). Pump a bounded
    // frame instead and keep the test deterministic.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('ميرور سكربيون'), findsOneWidget);
    expect(find.text('حيث تُصنع البدايات'), findsOneWidget);
    expect(find.text('الفقاعة فوق التطبيقات: متوقفة'), findsOneWidget);
    expect(find.text('ترجمة نصية'), findsOneWidget);
    expect(find.text('ترجمة محلية + مايك'), findsOneWidget);
    expect(find.text('حوار مترجم'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('مستندات وعدسة'), 300);
    expect(find.text('مستندات وعدسة'), findsOneWidget);
    expect(find.text('OCR صور + PDF وTXT محلي'), findsOneWidget);
    expect(find.text('OCR صور + PDF قيد الإعداد'), findsNothing);
    expect(find.text('قصص وإلهام'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('الشطرنج'), 300);
    expect(find.text('الشطرنج'), findsOneWidget);
    expect(find.text('لعب محلي أو ضد الكمبيوتر'), findsOneWidget);
    expect(find.text('ألعاب 3D'), findsNothing);
    await tester.scrollUntilVisible(find.text('الإعدادات'), 300);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
