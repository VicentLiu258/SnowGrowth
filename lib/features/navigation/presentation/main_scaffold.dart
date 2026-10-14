import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/deep_link/deep_link_controller.dart';
import 'package:snow_growth/core/utils/local_storage.dart';
import 'package:snow_growth/core/utils/support_launcher.dart';
import 'package:snow_growth/core/widgets/app_logo.dart';
import 'package:snow_growth/core/widgets/brand_icons.dart';
import 'package:snow_growth/features/about/presentation/about_page.dart';
import 'package:snow_growth/features/chat/presentation/chat_page.dart';
import 'package:snow_growth/features/home/presentation/home_page.dart';
import 'package:snow_growth/features/home/presentation/welcome_modal.dart';
import 'package:snow_growth/features/settings/presentation/settings_page.dart';
import 'package:snow_growth/features/tools/data/website_lookup_service.dart';
import 'package:snow_growth/features/tools/presentation/percentage_calculator_page.dart';
import 'package:snow_growth/features/tools/presentation/tip_calculator_page.dart';
import 'package:snow_growth/features/tools/presentation/tools_list_page.dart';
import 'package:snow_growth/features/tools/presentation/unit_converter_page.dart';
import 'package:snow_growth/features/tools/presentation/website_webview_page.dart';

enum AppTab { home, tools, about, settings }

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
  String _toolsQuery = '';
  bool _showWelcomeModal = true;
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
      if (tab != AppTab.tools) {
        _toolsQuery = '';
      }
    });
  }

  void _openToolsWithQuery(String query) {
    setState(() {
      _currentTab = AppTab.tools;
      _activeTool = null;
      _toolsQuery = query;
    });
  }

  Future<void> _openChat() async {
    double? chatWindowTop;
    bool chatSheetClosing = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      constraints: const BoxConstraints(maxWidth: 440),
      backgroundColor: Colors.white,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) {
        void closeChatSheet() {
          if (chatSheetClosing || !sheetContext.mounted) return;
          if (ModalRoute.of(sheetContext)?.isCurrent != true) return;
          chatSheetClosing = true;
          Navigator.of(sheetContext).pop();
        }

        return StatefulBuilder(
          builder:
              (context, setSheetState) => FractionallySizedBox(
                heightFactor: 1,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        Theme.of(context).platform == TargetPlatform.android
                            ? MediaQuery.viewInsetsOf(context).bottom
                            : 0,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ChatPage(
                          onChatClosed: closeChatSheet,
                          onWindowTopChanged: (top) {
                            if (!chatSheetClosing &&
                                sheetContext.mounted &&
                                chatWindowTop != top) {
                              setSheetState(() => chatWindowTop = top);
                            }
                          },
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        top: (chatWindowTop ?? 0) + 8,
                        right: 28,
                        child: Material(
                          color: Colors.white.withValues(alpha: 0.94),
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: IconButton(
                            tooltip: AppStrings.closeChat,
                            onPressed: closeChatSheet,
                            icon: const Icon(Icons.close, size: 20),
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
          onOpenTool: _openTool,
          onOpenWebsite: _openWebsite,
          onOpenToolsWithQuery: _openToolsWithQuery,
          onOpenChat: _openChat,
          websiteLookupService: _websiteLookupService,
        );
      case AppTab.tools:
        return ToolsListPage(
          onOpenTool: _openTool,
          initialQuery: _toolsQuery,
          onQueryChange: (q) => _toolsQuery = q,
        );
      case AppTab.about:
        return AboutPage(onOpenChat: _openChat);
      case AppTab.settings:
        return const SettingsPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringWebsite || _isOpeningDeepLink) {
      return const _StartupLoading();
    }

    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final showBottomNav = _activeTool == null && _websiteUrl == null;
    // Welcome modal only on A-side (native tabs), every cold launch once.
    final showWelcome =
        _showWelcomeModal &&
        _websiteUrl == null &&
        _activeTool == null &&
        !_isRestoringWebsite &&
        !_isOpeningDeepLink;

    return AppNavigation(
      currentTab: _currentTab,
      onTabChanged: _setTab,
      openTool: _openTool,
      closeTool: _closeTool,
      activeTool: _activeTool,
      child: Stack(
        children: [
          Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                if (isWide && _websiteUrl == null)
                  _Sidebar(
                    currentTab: _currentTab,
                    onTabChanged: _setTab,
                    onOpenWhatsApp: _openWhatsApp,
                  ),
                Expanded(
                  child: SafeArea(
                    top: _websiteUrl == null,
                    bottom: false,
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
                          _websiteUrl ?? _activeTool?.name ?? _currentTab.name,
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
                ),
              ],
            ),
            bottomNavigationBar:
                showBottomNav && !isWide
                    ? _BottomNav(
                      currentTab: _currentTab,
                      onTabChanged: _setTab,
                      onOpenWhatsApp: _openWhatsApp,
                    )
                    : null,
          ),
          if (showWelcome)
            Positioned.fill(
              child: WelcomeModal(
                onClose: () {
                  if (!mounted) return;
                  setState(() => _showWelcomeModal = false);
                },
                onSelectChannel: (channel) {
                  if (!mounted) return;
                  setState(() => _showWelcomeModal = false);
                  if (channel == WelcomeChannel.whatsapp) {
                    unawaited(_openWhatsApp());
                  } else {
                    unawaited(_openChat());
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openWhatsApp() {
    return openSupportChannel(
      context,
      channel: SupportChannel.whatsapp,
      source: 'nav_whatsapp',
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
  const _Sidebar({
    required this.currentTab,
    required this.onTabChanged,
    required this.onOpenWhatsApp,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;
  final VoidCallback onOpenWhatsApp;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(right: BorderSide(color: AppColors.border)),
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
            child: const AppLogo(height: 22),
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
            icon: Icons.chat_bubble_outline,
            label: AppStrings.whatsapp,
            selected: false,
            onTap: onOpenWhatsApp,
            selectedColor: AppColors.whatsapp,
          ),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.info_outline,
            label: AppStrings.about,
            selected: currentTab == AppTab.about,
            onTap: () => onTabChanged(AppTab.about),
          ),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.settings_outlined,
            label: AppStrings.settings,
            selected: currentTab == AppTab.settings,
            onTap: () => onTabChanged(AppTab.settings),
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
    this.selectedColor,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? selectedColor;

  @override
  Widget build(BuildContext context) {
    final active = selectedColor ?? AppColors.primary;
    return Material(
      color: selected ? AppColors.primaryLight : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: selected ? active : AppColors.textTertiary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? active : AppColors.textTertiary,
                  ),
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
  const _BottomNav({
    required this.currentTab,
    required this.onTabChanged,
    required this.onOpenWhatsApp,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onTabChanged;
  final VoidCallback onOpenWhatsApp;

  static const double archRise = 16.0;
  static const double archHalfWidth = 44.0;
  static const double baseHeight = 58.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final totalHeight = baseHeight + archRise + bottomInset;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ContinuousDomePainter(
                archRise: archRise,
                archHalfWidth: archHalfWidth,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            top: 0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.home_outlined,
                    label: AppStrings.home,
                    selected: currentTab == AppTab.home,
                    archRise: archRise,
                    onTap: () => onTabChanged(AppTab.home),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.grid_view_outlined,
                    label: AppStrings.tools,
                    selected: currentTab == AppTab.tools,
                    archRise: archRise,
                    onTap: () => onTabChanged(AppTab.tools),
                  ),
                ),
                Expanded(child: _WhatsAppCenterItem(onTap: onOpenWhatsApp)),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.info_outline,
                    label: AppStrings.about,
                    selected: currentTab == AppTab.about,
                    archRise: archRise,
                    onTap: () => onTabChanged(AppTab.about),
                  ),
                ),
                Expanded(
                  child: _BottomNavItem(
                    icon: Icons.settings_outlined,
                    label: AppStrings.settings,
                    selected: currentTab == AppTab.settings,
                    archRise: archRise,
                    onTap: () => onTabChanged(AppTab.settings),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppCenterItem extends StatefulWidget {
  const _WhatsAppCenterItem({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_WhatsAppCenterItem> createState() => _WhatsAppCenterItemState();
}

class _WhatsAppCenterItemState extends State<_WhatsAppCenterItem> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AnimatedScale(
            scale: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            child: Container(
              width: 42,
              height: 42,
              margin: const EdgeInsets.only(top: 5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2CD96F),
                    Color(0xFF25D366),
                    Color(0xFF1EBE5D),
                  ],
                ),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF25D366).withValues(alpha: 0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: BrandIcons.whatsapp(size: 21, color: Colors.white),
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            AppStrings.whatsapp,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF128C7E),
              letterSpacing: -0.1,
              height: 1,
            ),
          ),
          const SizedBox(height: 7),
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
    required this.archRise,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final double archRise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFF8C93A4);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.only(top: archRise),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
                letterSpacing: -0.1,
                height: 1,
              ),
            ),
            const SizedBox(height: 7),
          ],
        ),
      ),
    );
  }
}

/// Draws the continuous white bottom bar with an integrated center dome arch.
class _ContinuousDomePainter extends CustomPainter {
  const _ContinuousDomePainter({
    required this.archRise,
    required this.archHalfWidth,
  });

  final double archRise;
  final double archHalfWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width / 2;
    final w = size.width;
    final h = size.height;

    // Smooth continuous dome path
    final path =
        Path()
          ..moveTo(0, archRise)
          ..lineTo(midX - archHalfWidth, archRise)
          ..cubicTo(
            midX - archHalfWidth * 0.55,
            archRise,
            midX - archHalfWidth * 0.45,
            0,
            midX,
            0,
          )
          ..cubicTo(
            midX + archHalfWidth * 0.45,
            0,
            midX + archHalfWidth * 0.55,
            archRise,
            midX + archHalfWidth,
            archRise,
          )
          ..lineTo(w, archRise)
          ..lineTo(w, h)
          ..lineTo(0, h)
          ..close();

    // Subtle upward drop shadow
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.04), 8, true);

    // Continuous white fill
    final fillPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Continuous 1px subtle top border line
    final borderPaint =
        Paint()
          ..color = const Color(0xFFE5E7EB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    final borderPath =
        Path()
          ..moveTo(0, archRise)
          ..lineTo(midX - archHalfWidth, archRise)
          ..cubicTo(
            midX - archHalfWidth * 0.55,
            archRise,
            midX - archHalfWidth * 0.45,
            0,
            midX,
            0,
          )
          ..cubicTo(
            midX + archHalfWidth * 0.45,
            0,
            midX + archHalfWidth * 0.55,
            archRise,
            midX + archHalfWidth,
            archRise,
          )
          ..lineTo(w, archRise);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
