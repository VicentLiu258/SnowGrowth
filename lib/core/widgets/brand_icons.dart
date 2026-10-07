import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Lightweight brand glyphs that can be tinted with [color].
class BrandIcons {
  BrandIcons._();

  static const _whatsapp =
      '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12.04 2C6.58 2 2.13 6.45 2.13 11.91C2.13 13.66 2.59 15.36 3.45 16.86L2.05 22L7.3 20.62C8.75 21.41 10.38 21.83 12.04 21.83C17.5 21.83 21.95 17.38 21.95 11.92C21.95 9.27 20.92 6.78 19.05 4.91C17.18 3.03 14.69 2 12.04 2ZM12.04 20.15C10.56 20.15 9.11 19.76 7.85 19.01L7.55 18.83L4.43 19.65L5.26 16.61L5.06 16.29C4.24 14.99 3.8 13.47 3.8 11.91C3.8 7.37 7.5 3.67 12.05 3.67C14.25 3.67 16.31 4.53 17.87 6.09C19.42 7.65 20.28 9.72 20.28 11.92C20.28 16.46 16.58 20.15 12.04 20.15ZM16.57 14.45C16.32 14.33 15.1 13.73 14.88 13.65C14.65 13.56 14.49 13.52 14.32 13.76C14.16 14.01 13.69 14.56 13.55 14.73C13.4 14.89 13.26 14.91 13.01 14.79C12.77 14.66 11.98 14.41 11.05 13.58C10.32 12.93 9.83 12.13 9.69 11.88C9.54 11.64 9.67 11.5 9.79 11.38C9.9 11.27 10.04 11.09 10.16 10.95C10.28 10.81 10.32 10.7 10.41 10.54C10.49 10.37 10.45 10.23 10.39 10.11C10.33 9.99 9.83 8.76 9.63 8.26C9.43 7.78 9.22 7.84 9.07 7.83C8.93 7.83 8.76 7.83 8.6 7.83C8.44 7.83 8.17 7.89 7.95 8.13C7.72 8.38 7.09 8.97 7.09 10.18C7.09 11.39 7.97 12.55 8.09 12.71C8.22 12.87 9.82 15.34 12.28 16.4C12.86 16.65 13.32 16.81 13.67 16.92C14.26 17.11 14.79 17.08 15.22 17.02C15.7 16.95 16.7 16.41 16.91 15.82C17.12 15.23 17.12 14.73 17.05 14.62C16.99 14.52 16.82 14.46 16.57 14.45Z"/></svg>''';

  static const _telegram =
      '''<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M9.48 14.81L9.12 20.21C9.66 20.21 9.9 19.98 10.18 19.7L12.75 17.23L18.06 21.14C19.03 21.68 19.72 21.39 19.98 20.23L23.47 3.75C23.78 2.3 22.94 1.73 22 2.09L1.47 10.01C0.06 10.56 0.08 11.35 1.23 11.71L6.48 13.35L18.68 5.69C19.25 5.3 19.77 5.52 19.34 5.91L9.48 14.81Z"/></svg>''';

  static Widget whatsapp({double size = 20, Color color = Colors.white}) {
    return SvgPicture.string(
      _whatsapp,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static Widget telegram({double size = 20, Color color = Colors.white}) {
    return SvgPicture.string(
      _telegram,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static const _agent =
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>''';

  static const _inAppChat =
      '''<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"></path><line x1="8" y1="9" x2="16" y2="9"></line><line x1="8" y1="13" x2="13" y2="13"></line></svg>''';

  static Widget chatBubble({double size = 22, Color color = Colors.white}) {
    return Icon(Icons.chat_bubble_outline_rounded, size: size, color: color);
  }

  static Widget inAppChat({
    double size = 20,
    Color color = Colors.white,
  }) {
    final hex =
        color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    final svg = _inAppChat.replaceAll('currentColor', '#$hex');
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
    );
  }

  static Widget agent({
    double size = 19,
    Color color = const Color(0xFF2563EB),
  }) {
    final hex =
        color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2);
    final svg = _agent.replaceAll('currentColor', '#$hex');
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
    );
  }
}
