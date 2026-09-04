import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/widgets/tool_menu.dart';
import 'package:snow_growth/features/about/presentation/about_page.dart';
import 'package:snow_growth/features/home/presentation/home_page.dart';
import 'package:snow_growth/features/tools/data/website_lookup_service.dart';
import 'package:snow_growth/features/tools/presentation/tools_list_page.dart';
import 'package:snow_growth/features/tools/presentation/website_webview_page.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(super.params)
      : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
      PlatformNavigationDelegate handler) async {}

  @override
  Future<void> setOnPlatformPermissionRequest(
      void Function(PlatformWebViewPermissionRequest request)
          onPermissionRequest) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<bool> canGoBack() async => false;
}

class _FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  _FakePlatformNavigationDelegate(super.params)
      : super.implementation();

  @override
  Future<void> setOnProgress(void Function(int progress) onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
      void Function(WebResourceError error) onWebResourceError) async {}
}

class _FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
      PlatformWebViewControllerCreationParams params) {
    return _FakePlatformWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
      PlatformNavigationDelegateCreationParams params) {
    return _FakePlatformNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
      PlatformWebViewWidgetCreationParams params) {
    return _FakePlatformWebViewWidget(params);
  }
}

class _FakePlatformWebViewWidget extends PlatformWebViewWidget {
  _FakePlatformWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

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

  testWidgets('WebView double back press within 1s triggers app exit', (
    WidgetTester tester,
  ) async {
    WebViewPlatform.instance = _FakeWebViewPlatform();

    int systemPopCount = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'SystemNavigator.pop') {
          systemPopCount++;
        }
        return null;
      },
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: WebsiteWebViewPage(
          url: 'https://example.com',
        ),
      ),
    );
    await tester.pump();

    // Find PopScope
    final popScopeFinder = find.byWidgetPredicate((w) => w is PopScope);
    expect(popScopeFinder, findsOneWidget);
    final popScope = tester.widget<PopScope>(popScopeFinder);

    // First back press: should show snackbar prompt and NOT pop app
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(AppStrings.pressBackAgainToExit), findsOneWidget);
    expect(systemPopCount, 0);

    // Second back press within 1s: should call SystemNavigator.pop()
    popScope.onPopInvokedWithResult?.call(false, null);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(systemPopCount, 1);
  });
}
