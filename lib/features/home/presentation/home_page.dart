import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/widgets/app_button.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/top_aligned_body.dart';
import 'package:snow_growth/features/navigation/presentation/main_scaffold.dart';
import 'package:snow_growth/features/tools/data/website_lookup_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.onOpenTools,
    required this.onOpenAbout,
    required this.onOpenTool,
    required this.onOpenWebsite,
    required this.websiteLookupService,
  });

  final VoidCallback onOpenTools;
  final VoidCallback onOpenAbout;
  final ValueChanged<ToolRoute> onOpenTool;
  final ValueChanged<String> onOpenWebsite;
  final WebsiteLookupService websiteLookupService;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _lookupRequestId = 0;
  bool _isLookingUpWebsite = false;

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

  Future<void> _lookupWebsite(String query, int requestId) async {
    try {
      final url = await widget.websiteLookupService.fetchWebsiteUrl(query);
      if (!mounted || requestId != _lookupRequestId) return;
      if (url == null) return;

      FocusManager.instance.primaryFocus?.unfocus();
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

  @override
  Widget build(BuildContext context) {
    return TopAlignedBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            onChanged: _onSearchChanged,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, color: AppColors.gray400),
            ),
          ),
          if (_isLookingUpWebsite) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 24),
          _HeroSection(onOpenAbout: widget.onOpenAbout),
          const SizedBox(height: 40),
          _ToolsSection(
            onOpenTools: widget.onOpenTools,
            onOpenTool: widget.onOpenTool,
          ),
          const SizedBox(height: 40),
          const _SolutionsSection(),
          const SizedBox(height: 40),
          const _FeaturedCaseSection(),
        ],
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.gray900,
                height: 1.2,
              ),
              children: const [
                TextSpan(text: '${AppStrings.heroTitle}\n'),
                TextSpan(
                  text: AppStrings.heroTitleHighlight,
                  style: TextStyle(color: AppColors.emerald600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/hero-illustration.webp',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.heroSubtitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          AppButton(
            label: AppStrings.requestGrowthAudit,
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppStrings.tools.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.gray400,
              ),
            ),
            TextButton.icon(
              onPressed: onOpenTools,
              icon: const Icon(Icons.chevron_right, size: 16),
              label: const Text(AppStrings.seeAll),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.emerald600,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ToolQuickCard(
          icon: Icons.percent,
          title: AppStrings.percentage,
          onTap: () => onOpenTool(ToolRoute.percentage),
        ),
        const SizedBox(height: 12),
        _ToolQuickCard(
          icon: Icons.scale_outlined,
          title: AppStrings.unitConverter,
          onTap: () => onOpenTool(ToolRoute.unit),
        ),
        const SizedBox(height: 12),
        _ToolQuickCard(
          icon: Icons.attach_money,
          title: AppStrings.tipCalculator,
          onTap: () => onOpenTool(ToolRoute.tip),
        ),
      ],
    );
  }
}

class _ToolQuickCard extends StatelessWidget {
  const _ToolQuickCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.emerald600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gray300),
        ],
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppColors.gray400,
          ),
        ),
        const SizedBox(height: 16),
        _SolutionCard(
          icon: Icons.trending_up,
          title: AppStrings.solution1Title,
          description: AppStrings.solution1Desc,
        ),
        const SizedBox(height: 12),
        _SolutionCard(
          icon: Icons.business_outlined,
          title: AppStrings.solution2Title,
          description: AppStrings.solution2Desc,
        ),
        const SizedBox(height: 12),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.gray600, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
              height: 1.5,
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
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppColors.gray400,
          ),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 340,
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
                        AppColors.gray900.withValues(alpha: 0.2),
                        AppColors.gray900.withValues(alpha: 0.7),
                        AppColors.gray900,
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.emerald500.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Text(
                          AppStrings.caseTag,
                          style: TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Flexible(
                            child: Text(
                              AppStrings.caseMetric,
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              AppStrings.caseMetricLabel,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.caseFootnote,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
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
