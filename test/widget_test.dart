import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snow_growth/app.dart';
import 'package:snow_growth/core/constants/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shows splash then home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const SnowGrowthApp());
    await tester.pump();

    expect(find.byType(Image), findsWidgets);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 500));

    // Welcome modal appears on every A-side launch.
    expect(find.text(AppStrings.welcomeOffer), findsOneWidget);
    expect(find.text(AppStrings.maybeLater), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.maybeLater));
    await tester.tap(find.text(AppStrings.maybeLater));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(AppStrings.tapToClaimBonus), findsOneWidget);
    expect(find.text(AppStrings.tools), findsWidgets);
    expect(find.text(AppStrings.whatsapp), findsWidgets);
    expect(find.text(AppStrings.settings), findsOneWidget);
  });
}
