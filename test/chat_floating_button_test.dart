import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snow_growth/features/chat/presentation/chat_floating_button.dart';
import 'package:snow_growth/features/chat/presentation/chat_page.dart';
import 'package:snow_growth/features/navigation/presentation/main_scaffold.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class _FakePlatformWebViewController extends PlatformWebViewController {
  _FakePlatformWebViewController(super.params) : super.implementation();

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setBackgroundColor(Color color) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {}

  @override
  Future<void> loadRequest(LoadRequestParams params) async {}

  @override
  Future<bool> canGoBack() async => false;
}

class _FakePlatformNavigationDelegate extends PlatformNavigationDelegate {
  _FakePlatformNavigationDelegate(super.params) : super.implementation();

  @override
  Future<void> setOnProgress(void Function(int progress) onProgress) async {}

  @override
  Future<void> setOnWebResourceError(
    void Function(WebResourceError error) onWebResourceError,
  ) async {}
}

class _FakeWebViewPlatform extends WebViewPlatform {
  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    return _FakePlatformWebViewController(params);
  }

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) {
    return _FakePlatformNavigationDelegate(params);
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) {
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
    WebViewPlatform.instance = _FakeWebViewPlatform();
  });

  group('ChatFloatingButton', () {
    testWidgets('renders icon and badge correctly', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChatFloatingButton(onTap: () => tapCount++, badgeCount: 2),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatFloatingButton), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byType(ChatFloatingButton));
      await tester.pumpAndSettle();
      expect(tapCount, 1);
    });

    testWidgets('hides badge when badgeCount is 0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ChatFloatingButton(onTap: () {}, badgeCount: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.text('0'), findsNothing);
    });
  });

  group('MainScaffold floating button integration', () {
    testWidgets(
      'shows FAB on mobile Home tab and navigates to Chat when tapped',
      (tester) async {
        tester.view.physicalSize = const Size(600, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: MainScaffold()));
        await tester.pumpAndSettle();

        // Mobile Home tab: FAB should be present
        expect(find.byType(ChatFloatingButton), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // Tap FAB to open Chat
        await tester.tap(find.byType(ChatFloatingButton));
        await tester.pumpAndSettle();

        // Should now be on ChatPage and FAB should be hidden
        expect(find.byType(ChatPage), findsOneWidget);
        expect(find.byType(ChatFloatingButton), findsNothing);
      },
    );

    testWidgets('hides FAB on wide desktop screens', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: MainScaffold()));
      await tester.pumpAndSettle();

      // On wide screen, floating action button is hidden
      expect(find.byType(ChatFloatingButton), findsNothing);
    });
  });
}
