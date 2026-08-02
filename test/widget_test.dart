
import 'package:flutter_test/flutter_test.dart';

import 'package:ratnesh_gold_app/app/app.dart';

void main() {
  testWidgets('Splash loads brand text', (WidgetTester tester) async {
    await tester.pumpWidget(RatneshGoldApp());

    expect(find.text('RATNESHGOLD'), findsOneWidget);
    expect(find.text('Purity  •  Quality  •  Trust'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Welcome'), findsOneWidget);
  });
}
