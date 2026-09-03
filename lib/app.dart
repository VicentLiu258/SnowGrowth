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
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      builder: (context, child) {
        final overlay = Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkOverlay
            : AppTheme.lightOverlay;
        return AnnotatedRegion(
          value: overlay,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashPage(),
    );
  }
}
