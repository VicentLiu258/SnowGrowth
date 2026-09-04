import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/widgets/tool_menu.dart';
import 'package:snow_growth/features/about/presentation/about_page.dart';
import 'package:snow_growth/features/home/presentation/home_page.dart';
import 'package:snow_growth/features/tools/data/website_lookup_service.dart';
import 'package:snow_growth/features/tools/presentation/tools_list_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Email address is support@snowgrowth.com in About page and strings', (
    WidgetTester tester,
  ) async {
    expect(AppStrings.contactEmail, 'support@snowgrowth.com');
    expect(AppStrings.riskContent.contains('support@snowgrowth.com'), isTrue);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AboutPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('support@snowgrowth.com'), findsOneWidget);
  });

  testWidgets('Home page contains search bar with no hint text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomePage(
            onOpenTools: () {},
            onOpenAbout: () {},
            onOpenTool: (_) {},
            onOpenWebsite: (_) {},
            websiteLookupService: WebsiteLookupService(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify search bar is present on home page
    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final textField = tester.widget<TextField>(textFieldFinder);
    expect(textField.decoration?.hintText, isNull);
    expect(textField.decoration?.prefixIcon, isNotNull);
  });

  testWidgets('ToolsListPage does not have search bar or hint text', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ToolsListPage(
            onOpenTool: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify search bar is NOT in ToolsListPage
    expect(find.byType(TextField), findsNothing);
    expect(find.text(AppStrings.searchTools), findsNothing);
  });

  testWidgets('Export data is hidden in ToolMenu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [
              ToolMenu(
                onClear: () {},
                onExport: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open tool menu
    final menuButton = find.byType(PopupMenuButton<String>);
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    // Verify Clear Data is present, but Export Data is hidden
    expect(find.text(AppStrings.clearData), findsOneWidget);
    expect(find.text(AppStrings.exportData), findsNothing);
  });
}
