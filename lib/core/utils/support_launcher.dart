import 'package:flutter/material.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/services/salesmartly_channel_service.dart';
import 'package:snow_growth/core/utils/url_launcher.dart';

enum SupportChannel { whatsapp, telegram, inAppChat, agent }

/// Opens the appropriate support channel. WhatsApp / Telegram use external
/// URLs; in-app chat and agent use the provided [onOpenInAppChat] callback.
Future<void> openSupportChannel(
  BuildContext context, {
  required SupportChannel channel,
  VoidCallback? onOpenInAppChat,
  String source = 'general',
}) async {
  switch (channel) {
    case SupportChannel.whatsapp:
      final targetUrl = await SalesmartlyChannelService.resolveWhatsappUrl(
        AppConfig.whatsappUrl,
      );
      final opened = await openExternalUrl(targetUrl);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.linkOpenFailed)),
        );
      }
      break;
    case SupportChannel.telegram:
      final opened = await openExternalUrl(AppConfig.telegramUrl);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.linkOpenFailed)),
        );
      }
      break;
    case SupportChannel.inAppChat:
    case SupportChannel.agent:
      if (onOpenInAppChat != null) {
        onOpenInAppChat();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppStrings.connectingLiveSupport} ($source)'),
          ),
        );
      }
      break;
  }
}
