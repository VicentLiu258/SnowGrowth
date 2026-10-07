import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snow_growth/core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 20}) : markOnly = false;

  const AppLogo.mark({super.key, this.height = 88}) : markOnly = true;

  final double height;
  final bool markOnly;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      markOnly ? 'assets/logo_mark.svg' : 'assets/logo.svg',
      height: height,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => _TextLogo(height: height),
    );
  }
}

class _TextLogo extends StatelessWidget {
  const _TextLogo({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Text(
      'ICIA',
      style: TextStyle(
        fontSize: height * 0.85,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.4,
      ),
    );
  }
}
