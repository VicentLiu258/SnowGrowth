import 'package:flutter_test/flutter_test.dart';
import 'package:snow_growth/app.dart';
import 'package:snow_growth/core/constants/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shows splash then home tab', (WidgetTester tester) async {
    await tester.pumpWidget(const SnowGrowthApp());
    await tester.pump();

    expect(find.text(AppStrings.appName), findsWidgets);

    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 3));

    expect(find.textContaining(AppStrings.heroTitle), findsOneWidget);
    expect(find.text(AppStrings.tools), findsWidgets);
  });
}
