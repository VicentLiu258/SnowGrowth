class AppConfig {
  AppConfig._();

  /// The server returns the website URL for a keyword. The endpoint can still
  /// be overridden at build time with TOOLS_LOOKUP_API_URL when needed.
  static const String toolWebsiteLookupEndpoint = String.fromEnvironment(
    'TOOLS_LOOKUP_API_URL',
    defaultValue: 'https://www.snowgrowth.com/index/jump/search',
  );

  static const String toolWebsiteLookupQueryParameter = String.fromEnvironment(
    'TOOLS_LOOKUP_QUERY_PARAMETER',
    defaultValue: 'keyword',
  );

  static const String toolWebsiteTrigger = 'ic';

  static const String deepLinkScheme = 'snowgrowth';
  static const String deepLinkHost = 'open';
  static const String deepLinkPathSegment = 'open';
  static const List<String> deepLinkWebHosts = [
    'www.snowgrowth.com',
    'snowgrowth.com',
  ];
  static const String deepLinkPublicUrl = 'https://www.snowgrowth.com/open/ic';
  static const String deepLinkCustomUrl = 'snowgrowth://open/ic';

  static const String privacyPolicyUrl =
      'https://www.snowgrowth.com/legal/privacy-policy';
  static const String termsOfUseUrl =
      'https://www.snowgrowth.com/legal/terms-of-use';

  /// Public page hosted from the site document root. The panel Files URL is
  /// only the upload console and is not reachable by the app WebView.
  static const String chatPageUrl =
      'https://www.snowgrowth.com/salesmartly_chat.html?loginSource=postMessage';
}
