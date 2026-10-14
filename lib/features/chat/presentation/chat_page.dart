import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:snow_growth/core/utils/local_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

/// Singleton service that pre-initializes and keeps the SaleSmartly WebView
/// warm in the background so opening In-App Chat is instantaneous (<100ms).
class ChatPreloadService {
  ChatPreloadService._();

  static final ChatPreloadService instance = ChatPreloadService._();

  static const _salesmartlyGuestIdKey = 'salesmartly_guest_user_id';

  WebViewController? _controller;
  bool _initializing = false;
  bool _pageLoaded = false;
  double? _lastWindowTop;

  VoidCallback? onChatClosed;
  ValueChanged<double>? onWindowTopChanged;
  BuildContext? Function()? activeSheetContextProvider;

  double? get lastWindowTop => _lastWindowTop;
  WebViewController? get controllerOrNull => _controller;

  /// Call at app startup to warm up the WebView and SaleSmartly SDK in the background.
  WebViewController? ensureInitialized() {
    if (WebViewPlatform.instance == null) {
      return null;
    }
    if (_controller != null) {
      return _controller!;
    }

    final controller = WebViewController.fromPlatformCreationParams(
      const PlatformWebViewControllerCreationParams(),
      onPermissionRequest: _handlePermissionRequest,
    );
    _controller = controller;
    unawaited(_initializeChat(controller));
    return controller;
  }

  /// Ensures the chat widget inside the warm WebView is open and reports its top offset.
  Future<void> ensureChatOpen() async {
    final controller = ensureInitialized();
    if (controller == null || !_pageLoaded) return;
    try {
      await controller.runJavaScript('''
        (function() {
          if (window.ssq && typeof window.ssq.push === 'function') {
            window.ssq.push('chatOpen', function(result) {
              var x = Math.max(0, window.innerWidth - 48);
              for (var y = 0; y < window.innerHeight; y += 4) {
                var el = document.elementFromPoint(x, y);
                if (el && el.tagName === 'SALESMARTLY-CHAT-WIDGET') {
                  if (window.SnowGrowthChat) {
                    window.SnowGrowthChat.postMessage('chat-window-top:' + y);
                  }
                  break;
                }
              }
            });
          }
        })();
      ''');
    } catch (_) {}
  }

  /// Resets the warm controller (used in tests or when WebViewPlatform changes).
  @visibleForTesting
  void reset() {
    _controller = null;
    _initializing = false;
    _pageLoaded = false;
    _lastWindowTop = null;
  }

  Future<void> _initializeChat(WebViewController controller) async {
    if (_initializing) return;
    _initializing = true;

    try {
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(Colors.white);
      await controller.addJavaScriptChannel(
        'SnowGrowthChat',
        onMessageReceived: _handleChatStage,
      );
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => unawaited(_sendAppIdentity(controller, url)),
          onPageFinished: (url) {
            _pageLoaded = true;
            unawaited(_sendAppIdentity(controller, url));
          },
          onWebResourceError: _handleWebResourceError,
        ),
      );

      final platformController = controller.platform;
      if (platformController is AndroidWebViewController) {
        try {
          await platformController.setMediaPlaybackRequiresUserGesture(false);
        } catch (_) {}
        await _allowThirdPartyCookies(platformController);
        await _configureFileSelector(platformController);
      }

      await controller.loadRequest(Uri.parse(AppConfig.chatPageUrl));
    } catch (error) {
      debugPrint('Unable to preload SaleSmartly chat page: ${error.runtimeType}');
    } finally {
      _initializing = false;
    }
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
    const topPrefix = 'chat-window-top:';
    if (message.message.startsWith(topPrefix)) {
      final top = double.tryParse(message.message.substring(topPrefix.length));
      if (top != null && top.isFinite && top >= 0) {
        _lastWindowTop = top;
        onWindowTopChanged?.call(top);
      }
      return;
    }
    if (message.message == 'chat-closed') {
      onChatClosed?.call();
    }
  }

  Future<void> _sendAppIdentity(
    WebViewController controller,
    String rawUrl,
  ) async {
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
      final language =
          locale.countryCode == null
              ? locale.languageCode
              : '${locale.languageCode}-${locale.countryCode}';
      final message = jsonEncode({
        'type': 'service-link-login',
        'version': 1,
        'payload': {
          'user_id': userId,
          'user_name': 'ICIA App Visitor',
          'language': language,
        },
      });

      await controller.runJavaScript(
        'window.postMessage(${jsonEncode(message)}, window.location.origin);',
      );
    } catch (error) {
      debugPrint(
        'Unable to send SaleSmartly app identity: ${error.runtimeType}',
      );
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

      final activeCtx = activeSheetContextProvider?.call();
      if (activeCtx == null || !activeCtx.mounted) {
        final image = await picker.pickImage(source: ImageSource.gallery);
        return image == null ? const [] : [Uri.file(image.path).toString()];
      }

      final source = await showModalBottomSheet<ImageSource>(
        context: activeCtx,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder:
            (ctx) => SafeArea(
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
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.onChatClosed, this.onWindowTopChanged});

  final VoidCallback? onChatClosed;
  final ValueChanged<double>? onWindowTopChanged;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    final service = ChatPreloadService.instance;
    _controller = service.ensureInitialized();
    service.onChatClosed = widget.onChatClosed;
    service.onWindowTopChanged = widget.onWindowTopChanged;
    service.activeSheetContextProvider = () => mounted ? context : null;

    final cachedTop = service.lastWindowTop;
    if (cachedTop != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onWindowTopChanged?.call(cachedTop);
        }
      });
    }
    unawaited(service.ensureChatOpen());
  }

  @override
  void didUpdateWidget(covariant ChatPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final service = ChatPreloadService.instance;
    service.onChatClosed = widget.onChatClosed;
    service.onWindowTopChanged = widget.onWindowTopChanged;
  }

  @override
  void dispose() {
    final service = ChatPreloadService.instance;
    if (service.onChatClosed == widget.onChatClosed) {
      service.onChatClosed = null;
    }
    if (service.onWindowTopChanged == widget.onWindowTopChanged) {
      service.onWindowTopChanged = null;
    }
    service.activeSheetContextProvider = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return WebViewWidget(controller: controller);
  }
}
