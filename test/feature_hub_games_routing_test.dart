import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mirror_scorpion_v4/features/chess_club_screen.dart';
import 'package:mirror_scorpion_v4/features/feature_hub_screen.dart';

void main() {
  testWidgets('games feature opens the updated SVG chess screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FeatureHubScreen(kind: FeatureKind.games)),
    );

    expect(find.byType(ChessClubScreen), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(32));
  });
}
