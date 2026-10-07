import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/top_aligned_body.dart';
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
    this.initialQuery = '',
    this.onQueryChange,
  });

  final ValueChanged<ToolRoute> onOpenTool;
  final String initialQuery;
  final ValueChanged<String>? onQueryChange;

  @override
  State<ToolsListPage> createState() => _ToolsListPageState();
}

class _ToolsListPageState extends State<ToolsListPage> {
  late final TextEditingController _controller;
  late String _query;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery;
    _controller = TextEditingController(text: widget.initialQuery);
  }

  @override
  void didUpdateWidget(covariant ToolsListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery &&
        widget.initialQuery != _query) {
      _query = widget.initialQuery;
      _controller.text = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    widget.onQueryChange?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final lower = _query.toLowerCase();
    final filtered =
        allTools
            .where(
              (t) =>
                  t.name.toLowerCase().contains(lower) ||
                  t.description.toLowerCase().contains(lower),
            )
            .toList();
    final calculators =
        filtered.where((t) => t.category == AppStrings.calculators).toList();
    final converters =
        filtered.where((t) => t.category == AppStrings.converters).toList();

    return TopAlignedBody(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.tools,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: AppStrings.searchTools,
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
          const SizedBox(height: 24),
          if (calculators.isNotEmpty) ...[
            const _SectionHeader(title: AppStrings.calculators),
            const SizedBox(height: 12),
            ...calculators.map(
              (tool) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ToolCard(
                  tool: tool,
                  onTap: () => widget.onOpenTool(tool.route),
                ),
              ),
            ),
          ],
          if (converters.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _SectionHeader(title: AppStrings.converters),
            const SizedBox(height: 12),
            ...converters.map(
              (tool) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ToolCard(
                  tool: tool,
                  onTap: () => widget.onOpenTool(tool.route),
                ),
              ),
            ),
          ],
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.gray100,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      AppStrings.noToolsFound,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppStrings.noToolsFoundDescPrefix}$_query${AppStrings.noToolsFoundDescSuffix}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: AppColors.textMuted,
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.iconBgOrange,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(tool.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tool.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tool.description,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
        ],
      ),
    );
  }
}
