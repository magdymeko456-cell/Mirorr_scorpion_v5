import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/features/chess_club_screen.dart';
import 'package:mirror_scorpion_v4/features/feature_hub_screen.dart';
import 'package:mirror_scorpion_v4/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('games feature opens the updated SVG chess screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FeatureHubScreen(kind: FeatureKind.games),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChessClubScreen), findsOneWidget);
  });
}
