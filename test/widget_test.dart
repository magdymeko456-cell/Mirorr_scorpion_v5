import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/app/mirror_scorpion_app.dart';

void main() {
  testWidgets('boots the Royal Dark application shell', (tester) async {
    await tester.pumpWidget(const MirrorScorpionApp());

    expect(find.text('ميرور سكربيون'), findsOneWidget);
    expect(find.text('حيث تُصنع البدايات'), findsOneWidget);
  });
}
