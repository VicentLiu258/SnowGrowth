import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/widgets/app_logo.dart';
import 'package:snow_growth/core/widgets/brand_icons.dart';

enum WelcomeChannel { whatsapp, inAppChat }

/// Startup Welcome / Bonus modal. Matches the 1013 Demo interactions:
/// backdrop / close / "Maybe later" / swipe-down dismiss.
class WelcomeModal extends StatefulWidget {
  const WelcomeModal({
    super.key,
    required this.onClose,
    required this.onSelectChannel,
  });

  final VoidCallback onClose;
  final ValueChanged<WelcomeChannel> onSelectChannel;

  @override
  State<WelcomeModal> createState() => _WelcomeModalState();
}

class _WelcomeModalState extends State<WelcomeModal>
    with TickerProviderStateMixin {
  static const _exitMs = 220;
  static const _swipeDismissPx = 90.0;

  late final AnimationController _enterController;
  late final AnimationController _exitController;
  late final Animation<double> _overlayOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardScale;

  double _dragDy = 0;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _exitMs),
    );

    _overlayOpacity = CurvedAnimation(
      parent: _enterController,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );
    _cardScale = Tween<double>(begin: 0.96, end: 1).animate(
      CurvedAnimation(parent: _enterController, curve: Curves.easeOutCubic),
    );

    _enterController.forward();
  }

  @override
  void dispose() {
    _enterController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _requestClose([VoidCallback? afterClose]) async {
    if (_closing) return;
    _closing = true;
    await _exitController.forward();
    if (!mounted) return;
    widget.onClose();
    afterClose?.call();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_closing) return;
    setState(() {
      _dragDy = (_dragDy + details.delta.dy).clamp(0.0, 320.0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (_closing) return;
    if (_dragDy > _swipeDismissPx) {
      _requestClose();
    } else {
      setState(() => _dragDy = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exitT = _exitController.value;
    final overlayOpacity =
        (1 - exitT) *
        (_overlayOpacity.value) *
        (1 - (_dragDy / 320).clamp(0, 0.45));
    final dragEased =
        _dragDy < _swipeDismissPx
            ? _dragDy
            : _swipeDismissPx + (_dragDy - _swipeDismissPx) * 0.4;

    return AnimatedBuilder(
      animation: Listenable.merge([_enterController, _exitController]),
      builder: (context, _) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _requestClose(),
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: Color.fromRGBO(17, 24, 39, 0.46 * overlayOpacity),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.paddingOf(context).top + 20,
                    20,
                    MediaQuery.paddingOf(context).bottom + 20,
                  ),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 1, end: 0).animate(
                      CurvedAnimation(
                        parent: _exitController,
                        curve: Curves.easeIn,
                      ),
                    ),
                    child: SlideTransition(
                      position: _cardSlide,
                      child: Transform.translate(
                        offset: Offset(0, dragEased + 16 * exitT),
                        child: Transform.scale(
                          scale: _cardScale.value * (1 - 0.03 * exitT),
                          child: GestureDetector(
                            onVerticalDragUpdate: _onDragUpdate,
                            onVerticalDragEnd: _onDragEnd,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 344),
                              child: _WelcomeCard(
                                onClose: () => _requestClose(),
                                onMaybeLater: () => _requestClose(),
                                onWhatsApp:
                                    () => _requestClose(
                                      () => widget.onSelectChannel(
                                        WelcomeChannel.whatsapp,
                                      ),
                                    ),
                                onInAppChat:
                                    () => _requestClose(
                                      () => widget.onSelectChannel(
                                        WelcomeChannel.inAppChat,
                                      ),
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.onClose,
    required this.onMaybeLater,
    required this.onWhatsApp,
    required this.onInAppChat,
  });

  final VoidCallback onClose;
  final VoidCallback onMaybeLater;
  final VoidCallback onWhatsApp;
  final VoidCallback onInAppChat;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      elevation: 16,
      shadowColor: Colors.black54,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 128,
              width: double.infinity,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.homeTopGradient,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(painter: _DotGridPainter()),
                  ),
                  Positioned(
                    top: -70,
                    right: -50,
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.30),
                            AppColors.primary.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -90,
                    left: -60,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.brandBlue.withValues(alpha: 0.20),
                            AppColors.brandBlue.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 18,
                    right: 14,
                    child: Row(
                      children: [
                        const AppLogo(height: 16),
                        const Spacer(),
                        Material(
                          color: Colors.white.withValues(alpha: 0.72),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onClose,
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -36,
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.primaryBorder),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFFD27A),
                                AppColors.primary,
                                AppColors.primaryHover,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.card_giftcard_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 50, 22, 18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.primaryBorder),
                    ),
                    child: const Text(
                      AppStrings.welcomeOffer,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                        color: AppColors.primaryPress,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        height: 1.28,
                        letterSpacing: -0.3,
                        color: AppColors.textPrimary,
                      ),
                      children: const [
                        TextSpan(text: AppStrings.welcomeTitlePrefix),
                        TextSpan(
                          text: AppStrings.welcomeTitleAccent,
                          style: TextStyle(color: AppColors.primary),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    AppStrings.welcomeSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ChannelButton(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF2CD96F),
                        AppColors.whatsapp,
                        Color(0xFF1EBE5D),
                      ],
                    ),
                    shadowColor: AppColors.whatsapp,
                    icon: BrandIcons.whatsapp(size: 20),
                    title: AppStrings.whatsapp,
                    subtitle: AppStrings.instantSupport,
                    onTap: onWhatsApp,
                  ),
                  const SizedBox(height: 10),
                  _ChannelButton(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF8B240),
                        AppColors.primary,
                        AppColors.primaryHover,
                      ],
                    ),
                    shadowColor: AppColors.primary,
                    icon: BrandIcons.inAppChat(size: 20),
                    title: AppStrings.inAppChat,
                    subtitle: AppStrings.liveSupport,
                    onTap: onInAppChat,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onMaybeLater,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textTertiary,
                      minimumSize: const Size.fromHeight(40),
                    ),
                    child: const Text(
                      AppStrings.maybeLater,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelButton extends StatelessWidget {
  const _ChannelButton({
    required this.gradient,
    required this.shadowColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Gradient gradient;
  final Color shadowColor;
  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: icon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.textPrimary.withValues(alpha: 0.07)
          ..style = PaintingStyle.fill;
    const step = 14.0;
    for (var y = 0.0; y < size.height; y += step) {
      for (var x = 0.0; x < size.width; x += step) {
        final fade = (1 - (y / size.height)).clamp(0.0, 1.0);
        paint.color = AppColors.textPrimary.withValues(alpha: 0.07 * fade);
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
