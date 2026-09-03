import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/utils/url_launcher.dart';
import 'package:snow_growth/core/widgets/app_button.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/app_logo.dart';
import 'package:snow_growth/core/widgets/top_aligned_body.dart';
import 'package:snow_growth/features/about/presentation/legal_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: AppStrings.contactEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openLegalUrl(BuildContext context, String url) async {
    final opened = await openExternalUrl(url);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.linkOpenFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TopAlignedBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppLogo(height: 64)),
          const SizedBox(height: 16),
          Text(
            AppStrings.aboutDesc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.solutions.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.gray400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SolutionRow(
                  icon: Icons.trending_up,
                  title: AppStrings.solution1Title,
                ),
                const Divider(height: 1),
                _SolutionRow(
                  icon: Icons.business_outlined,
                  title: AppStrings.solution2Title,
                ),
                const Divider(height: 1),
                _SolutionRow(
                  icon: Icons.show_chart,
                  title: AppStrings.solution3Title,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.contact.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.gray400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                AppButton(
                  label: AppStrings.requestGrowthAudit,
                  expanded: true,
                  onPressed: _launchEmail,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _launchEmail,
                  icon: const Icon(Icons.mail_outline),
                  label: const Text(AppStrings.contactEmail),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.gray700,
                    side: const BorderSide(color: AppColors.gray100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.legal.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: AppColors.gray400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.legalDisclaimer,
                  style: TextStyle(
                    color: AppColors.gray500,
                    fontWeight: FontWeight.w500,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _LegalLink(
                      label: AppStrings.privacyPolicy,
                      onTap: () => _openLegalUrl(
                        context,
                        AppConfig.privacyPolicyUrl,
                      ),
                    ),
                    _LegalLink(
                      label: AppStrings.termsOfService,
                      onTap: () => _openLegalUrl(
                        context,
                        AppConfig.termsOfUseUrl,
                      ),
                    ),
                    _LegalLink(
                      label: AppStrings.riskDisclosure,
                      onTap: () => showLegalDialog(
                        context,
                        title: AppStrings.riskDisclosure,
                        content: AppStrings.riskContent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.copyright,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w500,
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

class _SolutionRow extends StatelessWidget {
  const _SolutionRow({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.emerald600, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.emerald600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
