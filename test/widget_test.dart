import 'package:flutter_test/flutter_test.dart';
import 'package:snow_growth/app.dart';
import 'package:snow_growth/core/constants/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches with home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const SnowGrowthApp());
    await tester.pumpAndSettle();

    expect(find.textContaining(AppStrings.heroTitle), findsOneWidget);
    expect(find.text(AppStrings.tools), findsWidgets);
  });
}
