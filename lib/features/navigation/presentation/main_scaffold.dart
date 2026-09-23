import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/deep_link/deep_link_controller.dart';
import 'package:snow_growth/core/utils/local_storage.dart';
import 'package:snow_growth/core/widgets/app_logo.dart';
import 'package:snow_growth/features/about/presentation/about_page.dart';
import 'package:snow_growth/features/chat/presentation/chat_floating_button.dart';
import 'package:snow_growth/features/chat/presentation/chat_page.dart';
import 'package:snow_growth/features/home/presentation/home_page.dart';
import 'package:snow_growth/features/tools/data/website_lookup_service.dart';
import 'package:snow_growth/features/tools/presentation/percentage_calculator_page.dart';
import 'package:snow_growth/features/tools/presentation/tip_calculator_page.dart';
import 'package:snow_growth/features/tools/presentation/tools_list_page.dart';
import 'package:snow_growth/features/tools/presentation/unit_converter_page.dart';
import 'package:snow_growth/features/tools/presentation/website_webview_page.dart';

enum AppTab { home, tools, about }

enum ToolRoute { percentage, unit, tip }

class AppNavigation extends InheritedWidget {
  const AppNavigation({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
    required this.openTool,
    required this.closeTool,
    required super.child,
    this.activeTool,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;
  final ValueChanged<ToolRoute> openTool;
  final VoidCallback closeTool;
  final ToolRoute? activeTool;

  static AppNavigation of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppNavigation>()!;
  }

  @override
  bool updateShouldNotify(AppNavigation oldWidget) {
    return currentTab != oldWidget.currentTab ||
        activeTool != oldWidget.activeTool;
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key, this.deepLinkController});

  final DeepLinkController? deepLinkController;

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static const _cachedWebsiteUrlKey = 'tools_ic_website_url';

  AppTab _currentTab = AppTab.home;
  ToolRoute? _activeTool;
  String? _websiteUrl;
  bool _isRestoringWebsite = true;
  bool _isOpeningDeepLink = false;
  int _deepLinkRequestId = 0;
  int _lastHandledDeepLinkVersion = 0;
  late final DeepLinkController _deepLinkController;
  bool _ownsDeepLinkController = false;
  late final WebsiteLookupService _websiteLookupService;

  @override
  void initState() {
    super.initState();
    if (widget.deepLinkController == null) {
      _deepLinkController = DeepLinkController();
      _ownsDeepLinkController = true;
    } else {
      _deepLinkController = widget.deepLinkController!;
    }
    _deepLinkController.addListener(_handleIncomingDeepLink);
    _websiteLookupService = WebsiteLookupService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // A cold-start deep link takes priority over the normal cached-website
      // restore so the app makes one lookup request and stays on the blank
      // transition page until that deep-link flow finishes.
      final handledDeepLink = _handleIncomingDeepLink();
      if (!handledDeepLink && _deepLinkRequestId == 0) {
        _restoreWebsite();
      }
    });
  }

  Future<void> _restoreWebsite() async {
    final restoreRequestId = _deepLinkRequestId;
    String? cachedUrl;
    try {
      cachedUrl = await LocalStorage.getString(
        _cachedWebsiteUrlKey,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Storage is best-effort for the startup redirect. If it is unavailable,
      // the normal app remains usable and the next launch can try again.
    }
    if (!mounted || restoreRequestId != _deepLinkRequestId) return;

    if (cachedUrl == null || cachedUrl.isEmpty) {
      setState(() => _isRestoringWebsite = false);
      return;
    }

    String url = cachedUrl;
    try {
      final refreshedUrl = await _websiteLookupService
          .fetchWebsiteUrl(AppConfig.toolWebsiteTrigger)
          .timeout(const Duration(seconds: 8));
      if (refreshedUrl != null) {
        url = refreshedUrl;
        if (url != cachedUrl) {
          unawaited(LocalStorage.setString(_cachedWebsiteUrlKey, url));
        }
      }
    } catch (_) {
      // Keep the last successful URL available when the lookup API is
      // temporarily unavailable. The next launch will retry the lookup.
    }

    if (!mounted || restoreRequestId != _deepLinkRequestId) return;
    setState(() {
      _websiteUrl = url;
      _isRestoringWebsite = false;
    });
  }

  bool _handleIncomingDeepLink() {
    final version = _deepLinkController.version;
    final uri = _deepLinkController.latestUri;
    if (uri == null || version <= _lastHandledDeepLinkVersion) return false;
    _lastHandledDeepLinkVersion = version;

    final keyword = DeepLinkParser.keywordFor(uri);
    if (keyword == null) return false;
    unawaited(_openDeepLink(keyword));
    return true;
  }

  Future<void> _openDeepLink(String keyword) async {
    final requestId = ++_deepLinkRequestId;
    setState(() {
      _isRestoringWebsite = false;
      _isOpeningDeepLink = true;
      _websiteUrl = null;
      _activeTool = null;
      _currentTab = AppTab.tools;
    });

    try {
      final url = await _websiteLookupService
          .fetchWebsiteUrl(keyword)
          .timeout(const Duration(seconds: 15));
      if (!mounted || requestId != _deepLinkRequestId) return;

      if (url == null) {
        throw const WebsiteLookupException(
          'The website lookup API did not return a valid website URL.',
        );
      }
      _openWebsite(url);
    } catch (error) {
      if (!mounted || requestId != _deepLinkRequestId) return;
      setState(() => _isOpeningDeepLink = false);
      final message =
          error is WebsiteLookupException
              ? error.message
              : AppStrings.websiteLookupFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void dispose() {
    _deepLinkController.removeListener(_handleIncomingDeepLink);
    if (_ownsDeepLinkController) _deepLinkController.dispose();
    _websiteLookupService.dispose();
    super.dispose();
  }

  void _setTab(AppTab tab) {
    setState(() {
      _currentTab = tab;
      _activeTool = null;
    });
  }

  Future<void> _openChat() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: 1,
          child: Column(
            children: [
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: AppStrings.closeChat,
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    icon: const Icon(Icons.close),
                    color: AppColors.gray600,
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.gray100),
              Expanded(
                child: ChatPage(
                  onChatClosed: () => Navigator.of(sheetContext).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTool(ToolRoute tool) {
    setState(() {
      _currentTab = AppTab.tools;
      _activeTool = tool;
    });
  }

  void _closeTool() {
    setState(() => _activeTool = null);
  }

  void _openWebsite(String url) {
    setState(() {
      _activeTool = null;
      _isOpeningDeepLink = false;
      _websiteUrl = url;
    });
    // The URL is considered visited as soon as the WebView is opened. Do not
    // wait for page load, because the app may be closed during navigation.
    unawaited(LocalStorage.setString(_cachedWebsiteUrlKey, url));
  }

  void _closeWebsite() {
    setState(() {
      _websiteUrl = null;
    });
  }

  Widget _buildToolPage() {
    switch (_activeTool!) {
      case ToolRoute.percentage:
        return PercentageCalculatorPage(onBack: _closeTool);
      case ToolRoute.unit:
        return UnitConverterPage(onBack: _closeTool);
      case ToolRoute.tip:
        return TipCalculatorPage(onBack: _closeTool);
    }
  }

  Widget _buildTabPage() {
    switch (_currentTab) {
      case AppTab.home:
        return HomePage(
          onOpenTools: () => _setTab(AppTab.tools),
          onOpenAbout: () => _setTab(AppTab.about),
          onOpenTool: _openTool,
          onOpenWebsite: _openWebsite,
          websiteLookupService: _websiteLookupService,
        );
      case AppTab.tools:
        return ToolsListPage(onOpenTool: _openTool);
      case AppTab.about:
        return const AboutPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringWebsite || _isOpeningDeepLink) {
      return const _StartupLoading();
    }

    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final showBottomNav = _activeTool == null && _websiteUrl == null;

    return AppNavigation(
      currentTab: _currentTab,
      onTabChanged: _setTab,
      openTool: _openTool,
      closeTool: _closeTool,
      activeTool: _activeTool,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        body: Row(
          children: [
            if (isWide && _websiteUrl == null)
              _Sidebar(currentTab: _currentTab, onTabChanged: _setTab),
            Expanded(
              child: SafeArea(
                top: _websiteUrl == null,
                bottom: false,
                child: Column(
                  children: [
                    if (!isWide &&
                        _activeTool == null &&
                        _websiteUrl == null &&
                        _currentTab == AppTab.home)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(children: const [AppLogo(height: 32)]),
                      ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            fit: StackFit.expand,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(
                            _websiteUrl ??
                                _activeTool?.name ??
                                _currentTab.name,
                          ),
                          child:
                              _websiteUrl != null
                                  ? WebsiteWebViewPage(
                                    url: _websiteUrl!,
                                    onBack: _closeWebsite,
                                  )
                                  : _activeTool != null
                                  ? _buildToolPage()
                                  : _buildTabPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton:
            _activeTool == null &&
                    _websiteUrl == null &&
                    _currentTab == AppTab.home
                ? ChatFloatingButton(onTap: _openChat)
                : null,
        bottomNavigationBar:
            showBottomNav && !isWide
                ? _BottomNav(currentTab: _currentTab, onTabChanged: _setTab)
                : null,
      ),
    );
  }
}

class _StartupLoading extends StatelessWidget {
  const _StartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.currentTab, required this.onTabChanged});

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(right: BorderSide(color: AppColors.gray200)),
      ),
      padding: EdgeInsets.only(
        top: 24 + MediaQuery.paddingOf(context).top,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => onTabChanged(AppTab.home),
            child: const AppLogo(height: 32),
          ),
          const SizedBox(height: 40),
          _NavItem(
            icon: Icons.home_outlined,
            label: AppStrings.home,
            selected: currentTab == AppTab.home,
            onTap: () => onTabChanged(AppTab.home),
          ),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.grid_view_outlined,
            label: AppStrings.tools,
            selected: currentTab == AppTab.tools,
            onTap: () => onTabChanged(AppTab.tools),
          ),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.info_outline,
            label: AppStrings.about,
            selected: currentTab == AppTab.about,
            onTap: () => onTabChanged(AppTab.about),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.emerald50 : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.emerald600 : AppColors.gray500,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? AppColors.emerald600 : AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentTab, required this.onTabChanged});

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(top: BorderSide(color: AppColors.gray100)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        8 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BottomNavItem(
            icon: Icons.home_outlined,
            label: AppStrings.home,
            selected: currentTab == AppTab.home,
            onTap: () => onTabChanged(AppTab.home),
          ),
          _BottomNavItem(
            icon: Icons.grid_view_outlined,
            label: AppStrings.tools,
            selected: currentTab == AppTab.tools,
            onTap: () => onTabChanged(AppTab.tools),
          ),
          _BottomNavItem(
            icon: Icons.info_outline,
            label: AppStrings.about,
            selected: currentTab == AppTab.about,
            onTap: () => onTabChanged(AppTab.about),
          ),
        ],
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.emerald600 : AppColors.gray400;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
