import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:safe_room/game/components/breakable_object.dart';
import 'package:safe_room/presentation/widgets/shop_overlay.dart';

void main() {
  testWidgets('ShopOverlay shows multiple decor items and buy callback',
      (tester) async {
    BreakableDecorType? bought;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShopOverlay(
            userPoints: 200,
            onClose: () {},
            onBuy: (type) => bought = type,
          ),
        ),
      ),
    );

    expect(find.text('Potted Plant'), findsOneWidget);
    expect(find.text('Ceramic Vase'), findsOneWidget);
    expect(find.text('Table Lamp'), findsOneWidget);
    expect(find.text('Mini Globe'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Buy (75 pts)'));
    await tester.pump();

    expect(bought, BreakableDecorType.vase);
  });

  testWidgets('ShopOverlay disables items the player cannot afford',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShopOverlay(
            userPoints: 60,
            onClose: () {},
            onBuy: (_) {},
          ),
        ),
      ),
    );

    final plantButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Buy (50 pts)'),
    );
    final vaseButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Need 75 pts'),
    );

    expect(plantButton.onPressed, isNotNull);
    expect(vaseButton.onPressed, isNull);
  });
}
