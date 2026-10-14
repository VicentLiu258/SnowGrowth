import 'dart:async';

import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/deep_link/deep_link_controller.dart';
import 'package:snow_growth/core/services/salesmartly_channel_service.dart';
import 'package:snow_growth/features/chat/presentation/chat_page.dart';
import 'package:snow_growth/features/navigation/presentation/main_scaffold.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            'assets/brand_mark.png',
            width: 220,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.deepLinkController});

  final DeepLinkController deepLinkController;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 2500);
  Timer? _timer;
  bool _didNavigate = false;
  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    SalesmartlyChannelService.prefetch();
    ChatPreloadService.instance.ensureInitialized();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    widget.deepLinkController.addListener(_onDeepLink);

    if (_hasPendingDeepLink) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToApp());
    } else {
      _timer = Timer(_duration, _goToApp);
    }
  }

  bool get _hasPendingDeepLink {
    final uri = widget.deepLinkController.latestUri;
    return uri != null && DeepLinkParser.keywordFor(uri) != null;
  }

  void _onDeepLink() {
    if (_hasPendingDeepLink) _goToApp();
  }

  void _goToApp() {
    if (!mounted || _didNavigate) return;
    _didNavigate = true;
    _timer?.cancel();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder:
            (_, __, ___) =>
                MainScaffold(deepLinkController: widget.deepLinkController),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.deepLinkController.removeListener(_onDeepLink);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade, child: const SplashView());
  }
}
