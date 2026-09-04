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

  static const String privacyPolicyUrl =
      'https://www.snowgrowth.com/legal/privacy-policy';
  static const String termsOfUseUrl =
      'https://www.snowgrowth.com/legal/terms-of-use';
}
