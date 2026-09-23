import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snow_growth/core/constants/app_strings.dart';

const String _chatIconSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 955 799" fill="white">
  <path d="M317 416L317 416Q343 416 361 398Q379 380 379 354Q379 328 361 309.50Q343 291 317 291Q291 291 273 309.50Q255 328 255 354Q255 380 273 398Q291 416 317 416ZM638 416L638 416Q664 416 682.50 398Q701 380 701 354Q701 328 682.50 309.50Q664 291 638.50 291Q613 291 594.50 309.50Q576 328 576 354Q576 380 594.50 398Q613 416 638 416ZM478 416L478 416Q504 416 522 398Q540 380 540 354Q540 328 522 309.50Q504 291 478 291Q452 291 433.50 309.50Q415 328 415 354Q415 380 433.50 398Q452 416 478 416ZM955 373L821 373L821 382Q821 433 803 477Q785 521 755.50 547Q726 573 692 573L692 573L263 573Q229 573 199.50 547Q170 521 152.50 477Q135 433 135 382L135 382L135 373L0 373L0 382Q0 445 18.50 502.50Q37 560 71 605L71 605Q108 654 158.50 680.50Q209 707 263 707L263 707L299 707L297 765Q297 779 306.50 789Q316 799 329.50 799Q343 799 353 790L353 790L441 707L692 707Q747 707 797 680.50Q847 654 884 605L884 605Q918 560 936.50 502.50Q955 445 955 382L955 382L955 373ZM0 334L135 334L135 325Q135 275 152.50 231Q170 187 199.50 161Q229 135 263 135L263 135L414 135Q426 135 436.50 129Q447 123 453 112L453 112L478 69L502 112Q508 123 518.50 129Q529 135 541 135L541 135L692 135Q726 135 755.50 161Q785 187 803 231Q821 275 821 325L821 325L821 334L955 334L955 325Q955 263 937 205.50Q919 148 884 102L884 102Q847 54 797 27Q747 0 692 0L692 0L263 0Q209 0 158.50 27Q108 54 71 102L71 102Q37 148 18.50 205.50Q0 263 0 325L0 325L0 334Z" />
</svg>
''';

/// A floating action button for chat, styled after SaleSmartly launcher button
/// with blue circular background, custom speech-bubble icon, and red unread badge.
class ChatFloatingButton extends StatelessWidget {
  const ChatFloatingButton({
    super.key,
    required this.onTap,
    this.badgeCount = 2,
  });

  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppStrings.chat,
      child: SizedBox(
        width: 62,
        height: 62,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 2,
              bottom: 2,
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  splashColor: Colors.white.withValues(alpha: 0.25),
                  highlightColor: Colors.white.withValues(alpha: 0.15),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5A88FD),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF5A88FD,
                          ).withValues(alpha: 0.38),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.string(
                      _chatIconSvg,
                      width: 28,
                      height: 28,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFA5151),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
