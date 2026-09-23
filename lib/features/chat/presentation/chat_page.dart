import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/utils/local_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  static const _salesmartlyGuestIdKey = 'salesmartly_guest_user_id';

  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController.fromPlatformCreationParams(
      const PlatformWebViewControllerCreationParams(),
      onPermissionRequest: _handlePermissionRequest,
    );

    unawaited(_initializeChat());
  }

  Future<void> _initializeChat() async {
    await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _controller.setBackgroundColor(Colors.white);
    await _controller.addJavaScriptChannel(
      'SnowGrowthChat',
      onMessageReceived: _handleChatStage,
    );
    await _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) => unawaited(_sendAppIdentity(url)),
        onWebResourceError: _handleWebResourceError,
      ),
    );

    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      try {
        await platformController.setMediaPlaybackRequiresUserGesture(false);
      } catch (_) {}
      // Apply cookie and file picker settings before the first page request.
      await _allowThirdPartyCookies(platformController);
      await _configureFileSelector(platformController);
    }

    await _loadChat();
  }

  void _handleWebResourceError(WebResourceError error) {
    final host = Uri.tryParse(error.url ?? '')?.host ?? 'unknown host';
    debugPrint(
      'Chat WebView resource error: code=${error.errorCode}, '
      'mainFrame=${error.isForMainFrame}, host=$host, '
      'description=${error.description}',
    );
  }

  void _handleChatStage(JavaScriptMessage message) {
    debugPrint('SaleSmartly chat stage: ${message.message}');
  }

  Future<void> _sendAppIdentity(String rawUrl) async {
    final pageUri = Uri.tryParse(rawUrl);
    final chatUri = Uri.parse(AppConfig.chatPageUrl);
    if (pageUri == null ||
        pageUri.scheme != 'https' ||
        pageUri.host != chatUri.host ||
        pageUri.path != chatUri.path) {
      return;
    }

    try {
      final userId = await _getSalesmartlyGuestId();
      final locale = WidgetsBinding.instance.platformDispatcher.locale;
      final language = locale.countryCode == null
          ? locale.languageCode
          : '${locale.languageCode}-${locale.countryCode}';
      final message = jsonEncode({
        'type': 'service-link-login',
        'version': 1,
        'payload': {
          'user_id': userId,
          'user_name': 'Snow Growth App Visitor',
          'language': language,
        },
      });

      await _controller.runJavaScript(
        'window.postMessage(${jsonEncode(message)}, window.location.origin);',
      );
    } catch (error) {
      debugPrint('Unable to send SaleSmartly app identity: ${error.runtimeType}');
    }
  }

  Future<String> _getSalesmartlyGuestId() async {
    final storedId = await LocalStorage.getString(_salesmartlyGuestIdKey);
    if (storedId != null && storedId.isNotEmpty) return storedId;

    final random = Random.secure();
    final randomBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final nonce = base64UrlEncode(randomBytes).replaceAll('=', '');
    final userId = sha256.convert(utf8.encode(nonce)).toString();
    await LocalStorage.setString(_salesmartlyGuestIdKey, userId);
    return userId;
  }

  void _handlePermissionRequest(WebViewPermissionRequest request) {
    unawaited(_resolvePermissionRequest(request));
  }

  Future<void> _resolvePermissionRequest(
    WebViewPermissionRequest request,
  ) async {
    try {
      final canGrant = request.types.every(
        (type) =>
            type == WebViewPermissionResourceType.camera ||
            type == WebViewPermissionResourceType.microphone,
      );
      if (canGrant) {
        await request.grant();
      } else {
        await request.deny();
      }
    } catch (_) {}
  }

  Future<void> _allowThirdPartyCookies(
    AndroidWebViewController controller,
  ) async {
    try {
      await AndroidWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
      ).setAcceptThirdPartyCookies(controller, true);
    } catch (_) {}
  }

  Future<void> _configureFileSelector(
    AndroidWebViewController controller,
  ) async {
    try {
      await controller.setOnShowFileSelector(_selectFiles);
    } catch (_) {}
  }

  Future<void> _loadChat() async {
    try {
      await _controller.loadRequest(Uri.parse(AppConfig.chatPageUrl));
    } catch (error) {
      debugPrint('Unable to load SaleSmartly chat page: ${error.runtimeType}');
    }
  }

  Future<List<String>> _selectFiles(FileSelectorParams params) async {
    if (params.mode == FileSelectorMode.save || !_acceptsImages(params)) {
      return const [];
    }

    final picker = ImagePicker();
    try {
      if (params.mode == FileSelectorMode.openMultiple) {
        final files = await picker.pickMultiImage();
        return files.map((file) => Uri.file(file.path).toString()).toList();
      }

      if (params.isCaptureEnabled) {
        final image = await picker.pickImage(source: ImageSource.camera);
        return image == null ? const [] : [Uri.file(image.path).toString()];
      }

      if (!mounted) return const [];
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.emerald600,
                ),
                title: const Text(
                  AppStrings.takePhoto,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.emerald600,
                ),
                title: const Text(
                  AppStrings.chooseFromGallery,
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.close, color: AppColors.gray400),
                title: const Text(
                  AppStrings.cancel,
                  style: TextStyle(color: AppColors.gray500),
                ),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
        ),
      );

      if (source == null) return const [];

      final image = await picker.pickImage(source: source);
      return image == null ? const [] : [Uri.file(image.path).toString()];
    } catch (_) {
      return const [];
    }
  }

  bool _acceptsImages(FileSelectorParams params) {
    if (params.acceptTypes.isEmpty) return true;
    return params.acceptTypes.any((type) {
      final normalized = type.toLowerCase().trim();
      return normalized.isEmpty ||
          normalized == '*/*' ||
          normalized.startsWith('image/') ||
          normalized.endsWith('.jpg') ||
          normalized.endsWith('.jpeg') ||
          normalized.endsWith('.png') ||
          normalized.endsWith('.heic') ||
          normalized.endsWith('.webp') ||
          normalized.endsWith('.pdf');
    });
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
