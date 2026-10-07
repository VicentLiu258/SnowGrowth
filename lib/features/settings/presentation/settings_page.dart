import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/deep_link/deep_link_controller.dart';
import 'package:snow_growth/core/utils/data_exporter.dart';
import 'package:snow_growth/core/utils/local_storage.dart';
import 'package:snow_growth/core/widgets/top_aligned_body.dart';
import 'package:snow_growth/features/splash/presentation/splash_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _exportWorkspace(BuildContext context) async {
    final pctMode = await LocalStorage.getInt('pct_mode') ?? 0;
    final pctX = await LocalStorage.getString('pct_x') ?? '25';
    final pctY = await LocalStorage.getString('pct_y') ?? '200';
    final tipBill = await LocalStorage.getString('tip_bill') ?? '85.00';
    final tipPct = await LocalStorage.getDouble('tip_pct') ?? 15;
    final tipSplit = await LocalStorage.getInt('tip_split') ?? 4;
    final unitCat = await LocalStorage.getInt('unit_cat') ?? 0;
    final unitFrom = await LocalStorage.getString('unit_from') ?? 'Meter';
    final unitTo = await LocalStorage.getString('unit_to') ?? 'Foot';
    final unitV1 = await LocalStorage.getString('unit_v1') ?? '100';
    final unitV2 = await LocalStorage.getString('unit_v2') ?? '328.084';

    final date = DateTime.now().toIso8601String().substring(0, 10);
    await DataExporter.exportJson({
      'app': 'ICIA Financial Growth Platform',
      'version': '2.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'calculatorPresets': {
        'percentage': {'mode': pctMode, 'valueX': pctX, 'valueY': pctY},
        'tipAndSplit': {
          'bill': tipBill,
          'tipPercentage': tipPct,
          'people': tipSplit,
        },
        'unitConverter': {
          'category': unitCat,
          'fromUnit': unitFrom,
          'toUnit': unitTo,
          'value1': unitV1,
          'value2': unitV2,
        },
      },
    }, 'icia_workspace_export_$date.json');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.exportSuccess)),
      );
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    await LocalStorage.removeAll(LocalStorage.calculatorCacheKeys);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.clearCacheSuccess)),
      );
    }
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(AppStrings.resetStoredDataTitle),
            content: const Text(
              AppStrings.resetStoredDataBody,
              style: TextStyle(height: 1.5, color: AppColors.textSecondary),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(AppStrings.confirmResetAllData),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(AppStrings.cancel),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await LocalStorage.clearAll();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder:
                (_) => SplashPage(deepLinkController: DeepLinkController()),
          ),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TopAlignedBody(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.settings,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.dataStorage.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.download_outlined,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: AppColors.agentBlue,
                  title: AppStrings.exportWorkspaceData,
                  subtitle: AppStrings.exportWorkspaceDesc,
                  onTap: () => _exportWorkspace(context),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SettingsTile(
                  icon: Icons.delete_outline,
                  iconBg: const Color(0xFFFFF7ED),
                  iconColor: AppColors.iconColorGold,
                  title: AppStrings.clearCache,
                  subtitle: AppStrings.clearCacheDesc,
                  onTap: () => _clearCache(context),
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  iconBg: const Color(0xFFFEF2F2),
                  iconColor: AppColors.danger,
                  title: AppStrings.deleteDataReset,
                  subtitle: AppStrings.deleteDataResetDesc,
                  titleColor: AppColors.danger,
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}
