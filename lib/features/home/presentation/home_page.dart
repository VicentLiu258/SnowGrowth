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
    required this.onOpenTool,
    required this.onOpenWebsite,
    required this.onOpenToolsWithQuery,
    required this.onOpenChat,
    required this.websiteLookupService,
  });

  final VoidCallback onOpenTools;
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

  Future<void> _openWhatsApp() {
    return openSupportChannel(
      context,
      channel: SupportChannel.whatsapp,
      source: 'home_whatsapp',
    );
  }

  void _openBSide() {
    _lookupWebsite(AppConfig.toolWebsiteTrigger, ++_lookupRequestId);
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
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
              onWhatsApp: _openWhatsApp,
            ),
            const SizedBox(height: 14),
            _HomeSearchBar(
              controller: _searchController,
              isLoading: _isLookingUpWebsite,
              onChanged: _onSearchChanged,
              onSubmitted: _onSearchSubmitted,
            ),
            const SizedBox(height: 16),
            _ChannelCards(
              onWhatsApp: _openWhatsApp,
              onInAppChat: widget.onOpenChat,
            ),
            const SizedBox(height: 16),
            _HeroSection(
              isLoading: _isLookingUpWebsite,
              onClaimBonus: _openBSide,
            ),
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
  const _HomeHeader({required this.onLogoTap, required this.onWhatsApp});

  final VoidCallback onLogoTap;
  final VoidCallback onWhatsApp;

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
            colors: [Color(0xFF2CD96F), Color(0xFF25D366)],
          ),
          shadowColor: AppColors.whatsapp,
          onTap: onWhatsApp,
          child: BrandIcons.whatsapp(size: 19, color: Colors.white),
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
                    ? Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 1.0,
                    )
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
          const LinearProgressIndicator(minHeight: 2, color: AppColors.primary),
        ],
      ],
    );
  }
}

class _ChannelCards extends StatelessWidget {
  const _ChannelCards({required this.onWhatsApp, required this.onInAppChat});

  final VoidCallback onWhatsApp;
  final VoidCallback onInAppChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChannelCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF25D366), Color(0xFF1EBE5D)],
            ),
            shadowColor: AppColors.whatsapp,
            icon: BrandIcons.whatsapp(size: 22),
            title: AppStrings.whatsapp,
            subtitle: AppStrings.instantSupport,
            onTap: onWhatsApp,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ChannelCard(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryHover],
            ),
            shadowColor: AppColors.primary,
            icon: BrandIcons.inAppChat(size: 22),
            title: AppStrings.inAppChat,
            subtitle: AppStrings.liveSupport,
            onTap: onInAppChat,
          ),
        ),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.gradient,
    required this.shadowColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Gradient gradient;
  final Color shadowColor;
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 108,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: icon,
                    ),
                    const Spacer(),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isLoading, required this.onClaimBonus});

  final bool isLoading;
  final VoidCallback onClaimBonus;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.primaryBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 12,
                  color: AppColors.primaryPress,
                ),
                SizedBox(width: 5),
                Text(
                  AppStrings.heroEyebrow,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                    color: AppColors.primaryPress,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.22,
                letterSpacing: -0.3,
              ),
              children: const [
                TextSpan(text: '${AppStrings.heroTitle}\n'),
                TextSpan(
                  text: AppStrings.heroTitleHighlight,
                  style: TextStyle(color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.6,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: AppStrings.tapToClaimBonus,
            expanded: true,
            onPressed: isLoading ? null : onClaimBonus,
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
                  letterSpacing: 0.35,
                  color: AppColors.textTertiary,
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
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
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
                fontWeight: FontWeight.w400,
                color: Color(0xFF2D3139),
                height: 1.25,
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
            letterSpacing: 0.35,
            color: AppColors.textTertiary,
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
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryBorder),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.primaryPress, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.6,
              fontSize: 11,
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
            letterSpacing: 0.35,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 220,
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
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFF5A623,
                          ).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(
                              0xFFF5A623,
                            ).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          AppStrings.caseTag,
                          style: TextStyle(
                            color: Color(0xFFFBBF24),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            AppStrings.caseMetric,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              AppStrings.caseMetricLabel,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFD1D5DB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppStrings.caseFootnote,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
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
