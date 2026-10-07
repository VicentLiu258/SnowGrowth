import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/widgets/app_button.dart';
import 'package:snow_growth/core/widgets/app_card.dart';
import 'package:snow_growth/core/widgets/app_logo.dart';
import 'package:snow_growth/core/widgets/top_aligned_body.dart';
import 'package:snow_growth/features/about/presentation/legal_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key, this.onOpenChat});

  final VoidCallback? onOpenChat;

  Future<void> _launchEmail() async {
    final uri = Uri(scheme: 'mailto', path: AppStrings.contactEmail);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _showLegal(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showLegalDialog(context, title: title, content: content);
  }

  @override
  Widget build(BuildContext context) {
    return TopAlignedBody(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppLogo(height: 22)),
          const SizedBox(height: 14),
          Text(
            AppStrings.aboutDesc,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
              height: 1.5,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 28),
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
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _SolutionRow(
                  icon: Icons.trending_up,
                  title: AppStrings.solution1Title,
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SolutionRow(
                  icon: Icons.business_outlined,
                  title: AppStrings.solution2Title,
                ),
                const Divider(height: 1, color: AppColors.divider),
                _SolutionRow(
                  icon: Icons.show_chart,
                  title: AppStrings.solution3Title,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            AppStrings.contact.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                AppButton(
                  label: AppStrings.requestStrategyConsultation,
                  expanded: true,
                  onPressed: onOpenChat ?? _launchEmail,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _launchEmail,
                  icon: const Icon(Icons.mail_outline, size: 18),
                  label: const Text(AppStrings.contactEmail),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text(
            AppStrings.legal.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.legalDisclaimer,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _LegalLink(
                      label: AppStrings.privacyPolicy,
                      onTap:
                          () => _showLegal(
                            context,
                            title: AppStrings.privacyPolicy,
                            content: AppStrings.privacyContent,
                          ),
                    ),
                    _LegalLink(
                      label: AppStrings.termsOfService,
                      onTap:
                          () => _showLegal(
                            context,
                            title: AppStrings.termsOfService,
                            content: AppStrings.termsContent,
                          ),
                    ),
                    _LegalLink(
                      label: AppStrings.riskDisclosure,
                      onTap:
                          () => _showLegal(
                            context,
                            title: AppStrings.riskDisclosure,
                            content: AppStrings.riskContent,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 14),
                const Text(
                  AppStrings.copyright,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w400,
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
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.iconBgOrange,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
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
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
