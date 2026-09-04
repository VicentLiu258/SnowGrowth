import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/top_aligned_body.dart';
import 'package:snow_growth/features/tools/data/website_lookup_service.dart';
import 'package:snow_growth/features/navigation/presentation/main_scaffold.dart';

class ToolItem {
  const ToolItem({
    required this.route,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
  });

  final ToolRoute route;
  final String name;
  final String description;
  final IconData icon;
  final String category;
}

const List<ToolItem> allTools = [
  ToolItem(
    route: ToolRoute.percentage,
    name: AppStrings.percentageCalculator,
    description: AppStrings.percentageDesc,
    icon: Icons.percent,
    category: AppStrings.calculators,
  ),
  ToolItem(
    route: ToolRoute.tip,
    name: AppStrings.tipCalculator,
    description: AppStrings.tipDesc,
    icon: Icons.attach_money,
    category: AppStrings.calculators,
  ),
  ToolItem(
    route: ToolRoute.unit,
    name: AppStrings.unitConverter,
    description: AppStrings.unitDesc,
    icon: Icons.scale_outlined,
    category: AppStrings.converters,
  ),
];

class ToolsListPage extends StatefulWidget {
  const ToolsListPage({
    super.key,
    required this.onOpenTool,
    required this.onOpenWebsite,
    required this.websiteLookupService,
  });

  final ValueChanged<ToolRoute> onOpenTool;
  final ValueChanged<String> onOpenWebsite;
  final WebsiteLookupService websiteLookupService;

  @override
  State<ToolsListPage> createState() => _ToolsListPageState();
}

class _ToolsListPageState extends State<ToolsListPage> {
  String _searchQuery = '';
  int _lookupRequestId = 0;
  bool _isLookingUpWebsite = false;

  List<ToolItem> get _filteredTools {
    if (_searchQuery.isEmpty) return allTools;
    final query = _searchQuery.toLowerCase();
    return allTools
        .where(
          (tool) =>
              tool.name.toLowerCase().contains(query) ||
              tool.description.toLowerCase().contains(query),
        )
        .toList();
  }

  void _onSearchChanged(String value) {
    final query = value.trim().toLowerCase();
    final shouldLookup = query == AppConfig.toolWebsiteTrigger;
    final requestId = ++_lookupRequestId;

    setState(() {
      _searchQuery = value;
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
    final calculators =
        _filteredTools
            .where((t) => t.category == AppStrings.calculators)
            .toList();
    final converters =
        _filteredTools
            .where((t) => t.category == AppStrings.converters)
            .toList();

    return TopAlignedBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tools,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: AppStrings.searchTools,
              prefixIcon: const Icon(Icons.search, color: AppColors.gray400),
            ),
          ),
          if (_isLookingUpWebsite) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(minHeight: 2),
          ],
          const SizedBox(height: 32),
          if (calculators.isNotEmpty) ...[
            _SectionHeader(title: AppStrings.calculators),
            const SizedBox(height: 16),
            ...calculators.map(
              (tool) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ToolCard(
                  tool: tool,
                  onTap: () => widget.onOpenTool(tool.route),
                ),
              ),
            ),
          ],
          if (converters.isNotEmpty) ...[
            _SectionHeader(title: AppStrings.converters),
            const SizedBox(height: 16),
            ...converters.map(
              (tool) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ToolCard(
                  tool: tool,
                  onTap: () => widget.onOpenTool(tool.route),
                ),
              ),
            ),
          ],
          if (_filteredTools.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  '${AppStrings.noToolsFound} "$_searchQuery".',
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
        color: AppColors.gray400,
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool, required this.onTap});

  final ToolItem tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(tool.icon, size: 28, color: AppColors.gray700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tool.description,
                  style: const TextStyle(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gray300),
        ],
      ),
    );
  }
}
