import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/constants/app_theme.dart';
import 'package:snow_growth/features/splash/presentation/splash_page.dart';

class SnowGrowthApp extends StatelessWidget {
  const SnowGrowthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) {
        return AnnotatedRegion(
          value: AppTheme.lightOverlay,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashPage(),
    );
  }
}
