import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.expanded = false,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool expanded;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, const SizedBox(width: 8)],
        Text(label),
      ],
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: expanded ? double.infinity : null,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald600,
              foregroundColor: Colors.white,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: child,
          ),
        );
      case AppButtonVariant.secondary:
        return SizedBox(
          width: expanded ? double.infinity : null,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.gray700,
              backgroundColor: Colors.white,
              padding: padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              side: const BorderSide(color: AppColors.gray200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: child,
          ),
        );
      case AppButtonVariant.ghost:
        return IconButton(
          onPressed: onPressed,
          icon: icon ?? Text(label),
          style: IconButton.styleFrom(
            foregroundColor: AppColors.gray500,
          ),
        );
    }
  }
}
