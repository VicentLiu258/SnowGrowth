import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/constants/app_theme.dart';
import 'package:snow_growth/core/deep_link/deep_link_controller.dart';
import 'package:snow_growth/features/splash/presentation/splash_page.dart';

class SnowGrowthApp extends StatefulWidget {
  const SnowGrowthApp({super.key});

  @override
  State<SnowGrowthApp> createState() => _SnowGrowthAppState();
}

class _SnowGrowthAppState extends State<SnowGrowthApp> {
  final DeepLinkController _deepLinkController = DeepLinkController();
  StreamSubscription<Uri>? _deepLinkSubscription;

  @override
  void initState() {
    super.initState();

    // Subscribe at the app root so an initial link is not lost while the
    // splash page is displayed. The same stream also covers warm launches.
    _deepLinkSubscription = AppLinks().uriLinkStream.listen(
      _deepLinkController.publish,
      onError: (_, __) {},
    );
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    _deepLinkController.dispose();
    super.dispose();
  }

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
      home: SplashPage(deepLinkController: _deepLinkController),
    );
  }
}
