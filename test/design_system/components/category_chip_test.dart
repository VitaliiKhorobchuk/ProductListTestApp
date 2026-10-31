import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_list_test_app/design_system/components/category_chip.dart';

import '../../support/component_test_app.dart';

void main() {
  testWidgets('CategoryChip reports taps while the parent owns selection', (
    tester,
  ) async {
    final proposals = <bool>[];
    Widget chip({required bool selected}) => componentTestApp(
      CategoryChip(
        label: 'Beauty',
        selected: selected,
        onSelected: proposals.add,
      ),
      themeMode: ThemeMode.dark,
    );

    await tester.pumpWidget(chip(selected: false));
    await tester.tap(find.text('Beauty'));
    await tester.pumpAndSettle();

    expect(proposals, [true]);
    expect(
      tester.widget<ChoiceChip>(find.byType(ChoiceChip)).selected,
      isFalse,
    );

    await tester.pumpWidget(chip(selected: true));
    await tester.pumpAndSettle();

    expect(tester.widget<ChoiceChip>(find.byType(ChoiceChip)).selected, isTrue);
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}
