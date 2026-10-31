import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_list_test_app/design_system/components/rating_badge.dart';
import 'package:product_list_test_app/design_system/theme/app_tokens.dart';

import '../../support/component_test_app.dart';

void main() {
  testWidgets(
    'RatingBadge displays rating, reviews, color and accessible label',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          componentTestApp(const RatingBadge(rating: 4.2, reviewCount: 3)),
        );

        expect(find.text('4.2'), findsOneWidget);
        expect(find.text('(3)'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Rated 4.2 out of 5, 3 reviews'),
          findsOneWidget,
        );
        final star = tester.widget<Icon>(find.byIcon(Icons.star_rounded));
        expect(star.color, AppTokens.light.ratingGood);
      } finally {
        semantics.dispose();
      }
    },
  );
}
