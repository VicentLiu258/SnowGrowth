import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snow_growth/core/constants/app_colors.dart';
import 'package:snow_growth/core/constants/app_strings.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

class WebsiteWebViewPage extends StatefulWidget {
  const WebsiteWebViewPage({
    super.key,
    required this.url,
    required this.onBack,
  });

  final String url;
  final VoidCallback onBack;

  @override
  State<WebsiteWebViewPage> createState() => _WebsiteWebViewPageState();
}

class _WebsiteWebViewPageState extends State<WebsiteWebViewPage> {
  late final WebViewController _controller;
  int _loadingProgress = 0;

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
              onProgress: (progress) {
                if (mounted) setState(() => _loadingProgress = progress);
              },
            ),
          );

    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
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
    final canGrant = request.types.every(
      (type) =>
          type == WebViewPermissionResourceType.camera ||
          type == WebViewPermissionResourceType.microphone,
    );
    try {
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

      final image = await picker.pickImage(
        source:
            params.isCaptureEnabled ? ImageSource.camera : ImageSource.gallery,
      );
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
      return normalized.startsWith('image/') ||
          normalized.endsWith('.jpg') ||
          normalized.endsWith('.jpeg') ||
          normalized.endsWith('.png') ||
          normalized.endsWith('.heic') ||
          normalized.endsWith('.webp');
    });
  }

  Future<void> _handleSystemBack() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
        return;
      }
    } catch (_) {
      // Fall through to the app-level back action if the WebView is not ready.
    }
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handleSystemBack());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: AppStrings.back,
            onPressed: _handleSystemBack,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text(AppStrings.icWebsiteTitle),
          bottom:
              _loadingProgress < 100
                  ? PreferredSize(
                    preferredSize: const Size.fromHeight(2),
                    child: LinearProgressIndicator(
                      value:
                          _loadingProgress == 0 ? null : _loadingProgress / 100,
                      minHeight: 2,
                      color: AppColors.emerald600,
                      backgroundColor: AppColors.gray100,
                    ),
                  )
                  : null,
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
