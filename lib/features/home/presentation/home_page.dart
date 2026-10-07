import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/services/appsflyer_service.dart';
import 'package:snow_growth/core/utils/support_launcher.dart';
import 'package:snow_growth/core/widgets/app_button.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/app_logo.dart';
import 'package:snow_growth/core/widgets/brand_icons.dart';
import 'package:snow_growth/features/navigation/presentation/main_scaffold.dart';
import 'package:snow_growth/features/tools/data/website_lookup_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenTools,
    required this.onOpenAbout,
    required this.onOpenTool,
    required this.onOpenWebsite,
    required this.onOpenToolsWithQuery,
    required this.onOpenChat,
    required this.websiteLookupService,
  });

  final VoidCallback onOpenTools;
  final VoidCallback onOpenAbout;
  final ValueChanged<ToolRoute> onOpenTool;
  final ValueChanged<String> onOpenWebsite;
  final ValueChanged<String> onOpenToolsWithQuery;
  final VoidCallback onOpenChat;
  final WebsiteLookupService websiteLookupService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lookupRequestId = 0;
  bool _isLookingUpWebsite = false;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    final shouldLookup = query == AppConfig.toolWebsiteTrigger;
    final requestId = ++_lookupRequestId;

    setState(() {
      _isLookingUpWebsite = shouldLookup;
    });

    if (shouldLookup) {
      _lookupWebsite(query, requestId);
    }
  }

  void _onSearchSubmitted(String value) {
    final query = value.trim();
    if (query.isEmpty) return;
    if (query.toLowerCase() == AppConfig.toolWebsiteTrigger) {
      _lookupWebsite(query.toLowerCase(), ++_lookupRequestId);
      return;
    }
    widget.onOpenToolsWithQuery(query);
  }

  Future<void> _lookupWebsite(String query, int requestId) async {
    setState(() => _isLookingUpWebsite = true);
    try {
      final url = await widget.websiteLookupService.fetchWebsiteUrl(query);
      if (!mounted || requestId != _lookupRequestId) return;
      if (url == null) return;

      FocusManager.instance.primaryFocus?.unfocus();

      if (query == AppConfig.toolWebsiteTrigger) {
        AppsFlyerService().logEvent('af_ic');
      }

      widget.onOpenWebsite(url);
    } catch (error) {
      if (!mounted || requestId != _lookupRequestId) return;
      final message =
          error is WebsiteLookupException
              ? error.message
              : AppStrings.websiteLookupFailed;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted && requestId == _lookupRequestId) {
        setState(() => _isLookingUpWebsite = false);
      }
    }
  }

  // ignore: unused_element
  Future<void> _openChannel(SupportChannel channel) {
    return openSupportChannel(
      context,
      channel: channel,
      onOpenInAppChat: widget.onOpenChat,
      source: 'home_$channel',
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        // Soft lavender→sky gradient behind the top of the home screen.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 320 + topPad,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.gradientStart,
                    AppColors.gradientMid,
                    AppColors.background.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            _HomeHeader(
              onLogoTap: () {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                  );
                }
              },
              onInAppChat: widget.onOpenChat,
            ),
            const SizedBox(height: 14),
            _HomeSearchBar(
              controller: _searchController,
              isLoading: _isLookingUpWebsite,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
            ),
            const SizedBox(height: 16),
            // Quick action buttons are temporarily hidden per user request
            _HeroSection(onOpenAbout: widget.onOpenAbout),
            const SizedBox(height: 18),
            _ToolsSection(
              onOpenTools: widget.onOpenTools,
              onOpenTool: widget.onOpenTool,
            ),
            const SizedBox(height: 24),
            const _SolutionsSection(),
            const SizedBox(height: 24),
            const _FeaturedCaseSection(),
          ],
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onLogoTap,
    required this.onInAppChat,
  });

  final VoidCallback onLogoTap;
  final VoidCallback onInAppChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onLogoTap,
          behavior: HitTestBehavior.opaque,
          child: const AppLogo(height: 20),
        ),
        const Spacer(),
        _HeaderRoundButton(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          ),
          shadowColor: AppColors.primary,
          onTap: onInAppChat,
          child: BrandIcons.inAppChat(size: 19, color: Colors.white),
        ),
      ],
    );
  }
}

class _HeaderRoundButton extends StatelessWidget {
  const _HeaderRoundButton({
    // ignore: unused_element_parameter
    this.background,
    this.gradient,
    this.shadowColor,
    required this.onTap,
    required this.child,
    // ignore: unused_element_parameter
    this.border = false,
  });

  final Color? background;
  final Gradient? gradient;
  final Color? shadowColor;
  final VoidCallback onTap;
  final Widget child;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gradient == null ? (background ?? Colors.white) : null,
            gradient: gradient,
            border:
                border
                    ? Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.0)
                    : null,
            boxShadow: [
              BoxShadow(
                color: (shadowColor ?? Colors.black).withValues(
                  alpha: shadowColor != null ? 0.32 : 0.04,
                ),
                blurRadius: shadowColor != null ? 6 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

class _HomeSearchBar extends StatelessWidget {
  const _HomeSearchBar({
    required this.controller,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: AppStrings.searchHint,
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.textMuted,
              size: 20,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (isLoading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.primary,
          ),
        ],
      ],
    );
  }
}

// ignore: unused_element
class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onWhatsApp,
    required this.onTelegram,
    required this.onInAppChat,
  });

  final VoidCallback onWhatsApp;
  final VoidCallback onTelegram;
  final VoidCallback onInAppChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionItem(
            label: AppStrings.whatsapp,
            background: AppColors.whatsapp,
            shadowColor: AppColors.whatsapp,
            icon: BrandIcons.whatsapp(size: 26),
            onTap: onWhatsApp,
          ),
        ),
        Expanded(
          child: _QuickActionItem(
            label: AppStrings.telegram,
            background: AppColors.telegram,
            shadowColor: AppColors.telegram,
            icon: BrandIcons.telegram(size: 26),
            onTap: onTelegram,
          ),
        ),
        Expanded(
          child: _QuickActionItem(
            label: AppStrings.inAppChat,
            background: AppColors.primary,
            shadowColor: AppColors.primary,
            icon: BrandIcons.chatBubble(size: 26),
            onTap: onInAppChat,
          ),
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  const _QuickActionItem({
    required this.label,
    required this.background,
    required this.shadowColor,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color shadowColor;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: shadowColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.onOpenAbout});

  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, size: 12, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  AppStrings.heroEyebrow,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1.25,
                letterSpacing: -0.3,
              ),
              children: const [
                TextSpan(text: '${AppStrings.heroTitle} '),
                TextSpan(
                  text: AppStrings.heroTitleHighlight,
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/hero.webp',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.heroSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: AppStrings.requestStrategyConsultation,
            expanded: true,
            onPressed: onOpenAbout,
          ),
        ],
      ),
    );
  }
}

class _ToolsSection extends StatelessWidget {
  const _ToolsSection({required this.onOpenTools, required this.onOpenTool});

  final VoidCallback onOpenTools;
  final ValueChanged<ToolRoute> onOpenTool;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                AppStrings.tools.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onOpenTools,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        AppStrings.seeAll,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HomeToolItem(
                  icon: Icons.percent,
                  label: AppStrings.percentageShort,
                  bg: AppColors.iconBgOrange,
                  fg: AppColors.iconColorOrange,
                  onTap: () => onOpenTool(ToolRoute.percentage),
                ),
              ),
              Expanded(
                child: _HomeToolItem(
                  icon: Icons.scale_outlined,
                  label: AppStrings.unitConverter,
                  bg: AppColors.iconBgGold,
                  fg: AppColors.iconColorGold,
                  onTap: () => onOpenTool(ToolRoute.unit),
                ),
              ),
              Expanded(
                child: _HomeToolItem(
                  icon: Icons.attach_money,
                  label: AppStrings.tipCalculator,
                  bg: AppColors.iconBgRose,
                  fg: AppColors.iconColorRose,
                  onTap: () => onOpenTool(ToolRoute.tip),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeToolItem extends StatelessWidget {
  const _HomeToolItem({
    required this.icon,
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: fg, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolutionsSection extends StatelessWidget {
  const _SolutionsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.solutions.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        _SolutionCard(
          icon: Icons.trending_up,
          title: AppStrings.solution1Title,
          description: AppStrings.solution1Desc,
        ),
        const SizedBox(height: 10),
        _SolutionCard(
          icon: Icons.business_outlined,
          title: AppStrings.solution2Title,
          description: AppStrings.solution2Desc,
        ),
        const SizedBox(height: 10),
        _SolutionCard(
          icon: Icons.show_chart,
          title: AppStrings.solution3Title,
          description: AppStrings.solution3Desc,
        ),
      ],
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.iconBgOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.5,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedCaseSection extends StatelessWidget {
  const _FeaturedCaseSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.featuredCase.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 280,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset('assets/case.webp', fit: BoxFit.cover),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.textPrimary.withValues(alpha: 0.15),
                        AppColors.textPrimary.withValues(alpha: 0.65),
                        AppColors.textPrimary,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Text(
                          AppStrings.caseTag,
                          style: TextStyle(
                            color: Color(0xFFFFE0A3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            AppStrings.caseMetric,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              AppStrings.caseMetricLabel,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppStrings.caseFootnote,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
