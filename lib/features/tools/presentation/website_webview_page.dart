import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebsiteWebViewPage extends StatefulWidget {
  const WebsiteWebViewPage({
    super.key,
    required this.url,
    this.onBack,
  });

  final String url;
  final VoidCallback? onBack;

  @override
  State<WebsiteWebViewPage> createState() => _WebsiteWebViewPageState();
}

class _WebsiteWebViewPageState extends State<WebsiteWebViewPage> {
  late final WebViewController _controller;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();

    _controller =
        WebViewController.fromPlatformCreationParams(
            const PlatformWebViewControllerCreationParams(),
            onPermissionRequest: _handlePermissionRequest,
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Colors.white)
          ..setNavigationDelegate(
            NavigationDelegate(
              onWebResourceError: (_) {
                // Ignore transient resource errors to avoid terminating the webview
              },
            ),
          );

    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      try {
        platformController.setMediaPlaybackRequiresUserGesture(false);
      } catch (_) {}
      unawaited(_configureFileSelector(platformController));
    }

    unawaited(_loadWebsite());
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
    } catch (_) {
      // The OS can reject a WebView permission after the user changes the
      // system setting. Keep that rejection inside the WebView flow.
    }
  }

  Future<void> _configureFileSelector(
    AndroidWebViewController controller,
  ) async {
    try {
      await controller.setOnShowFileSelector(_selectFiles);
    } catch (_) {
      // Older Android System WebView versions may not expose the file chooser.
    }
  }

  Future<void> _loadWebsite() async {
    try {
      await _controller.loadRequest(Uri.parse(widget.url));
    } catch (_) {
      // Navigation errors are rendered by the System WebView; do not let a
      // transient network failure terminate the Flutter page.
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

      // If capture is not specifically forced, provide choice between camera & gallery
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
      // Returning an empty list cancels the chooser cleanly instead of making
      // the WebView crash when the user denies a system permission.
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

  Future<void> _handleSystemBack() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
        _lastBackPressTime = null;
        return;
      }
    } catch (_) {}

    final now = DateTime.now();
    if (_lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) <= const Duration(seconds: 1)) {
      await SystemNavigator.pop();
      return;
    }

    _lastBackPressTime = now;
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.pressBackAgainToExit),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handleSystemBack());
      },
      child: Scaffold(
        body: SafeArea(
          child: WebViewWidget(controller: _controller),
        ),
      ),
    );
  }
}
