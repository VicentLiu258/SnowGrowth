class AppConfig {
  AppConfig._();

  /// Configure this at build time, for example:
  ///
  /// flutter run --dart-define=TOOLS_LOOKUP_API_URL=https://api.example.com/tools/url
  ///
  /// The endpoint is called with the configured query parameter and the value
  /// `ic`, so the default request is `?keyword=ic`.
  static const String toolWebsiteLookupEndpoint = String.fromEnvironment(
    'TOOLS_LOOKUP_API_URL',
    defaultValue: '',
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
