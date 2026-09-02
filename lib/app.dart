import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/constants/app_theme.dart';
import 'package:snow_growth/features/navigation/presentation/main_scaffold.dart';

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
      home: const MainScaffold(),
    );
  }
}
