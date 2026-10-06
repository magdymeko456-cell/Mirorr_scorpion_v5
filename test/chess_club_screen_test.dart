import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mirror_scorpion_v4/features/chess_club_screen.dart';
import 'package:mirror_scorpion_v4/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('ChessClubScreen يبني الشاشة', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ChessClubScreen(),
      ),
    );
    expect(find.byType(ChessClubScreen), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(32));
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
  });
}
