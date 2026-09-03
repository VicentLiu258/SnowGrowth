import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snow_growth/core/constants/app_colors.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.height = 32}) : markOnly = false;

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
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: 'Snow',
            style: TextStyle(
              fontSize: height * 0.6,
              fontWeight: FontWeight.bold,
              color: AppColors.gray900,
            ),
          ),
          TextSpan(
            text: 'Growth',
            style: TextStyle(
              fontSize: height * 0.6,
              fontWeight: FontWeight.bold,
              color: AppColors.emerald600,
            ),
          ),
        ],
      ),
    );
  }
}
