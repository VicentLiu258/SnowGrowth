import 'package:flutter/foundation.dart';
import 'package:snow_growth/core/constants/app_config.dart';

/// Keeps the native deep-link stream available while the splash screen is up.
/// This also lets a running MainScaffold receive a new external link without
/// creating a second navigation stack.
class DeepLinkController extends ChangeNotifier {
  Uri? _latestUri;
  int _version = 0;

  Uri? get latestUri => _latestUri;
  int get version => _version;

  void publish(Uri uri) {
    _latestUri = uri;
    _version++;
    notifyListeners();
  }
}

class DeepLinkParser {
  DeepLinkParser._();

  /// Returns the supported website-lookup keyword, or null for unrelated URLs.
  ///
  /// Supported forms:
  /// - https://www.snowgrowth.com/open/ic
  /// - https://www.snowgrowth.com/open?keyword=ic
  /// - snowgrowth://open/ic
  /// - snowgrowth://open?keyword=ic
  static String? keywordFor(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    final host = uri.host.toLowerCase();

    if (scheme == AppConfig.deepLinkScheme && host == AppConfig.deepLinkHost) {
      final keyword = _firstNonEmpty([
        uri.queryParameters[AppConfig.toolWebsiteLookupQueryParameter],
        if (uri.pathSegments.isNotEmpty) uri.pathSegments.first,
      ]);
      return _normalizeKeyword(keyword ?? AppConfig.toolWebsiteTrigger);
    }

    if (scheme == 'https' && AppConfig.deepLinkWebHosts.contains(host)) {
      final segments = uri.pathSegments;
      if (segments.isEmpty ||
          segments.first.toLowerCase() != AppConfig.deepLinkPathSegment) {
        return null;
      }

      final keyword = _firstNonEmpty([
        uri.queryParameters[AppConfig.toolWebsiteLookupQueryParameter],
        if (segments.length > 1) segments[1],
      ]);
      return _normalizeKeyword(keyword ?? AppConfig.toolWebsiteTrigger);
    }

    return null;
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  static String? _normalizeKeyword(String value) {
    final keyword = value.trim().toLowerCase();
    return keyword == AppConfig.toolWebsiteTrigger ? keyword : null;
  }
}
