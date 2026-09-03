import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:snow_growth/core/constants/app_config.dart';

class WebsiteLookupService {
  WebsiteLookupService({
    String? endpoint,
    String? queryParameter,
    http.Client? client,
  }) : endpoint = endpoint ?? AppConfig.toolWebsiteLookupEndpoint,
       queryParameter =
           queryParameter ?? AppConfig.toolWebsiteLookupQueryParameter,
       _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String endpoint;
  final String queryParameter;
  final http.Client _client;
  final bool _ownsClient;

  Future<String?> fetchWebsiteUrl(String query) async {
    if (endpoint.trim().isEmpty) {
      throw const WebsiteLookupException(
        'The website lookup API is not configured.',
      );
    }

    final response = await _client
        .get(
          _buildRequestUri(query),
          headers: const {'Accept': 'application/json'},
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebsiteLookupException(
        'The website lookup API returned HTTP ${response.statusCode}.',
      );
    }

    final dynamic payload;
    try {
      payload = jsonDecode(response.body);
    } on FormatException {
      throw const WebsiteLookupException(
        'The website lookup API returned invalid JSON.',
      );
    }

    final url = _extractUrl(payload);
    if (url == null) {
      throw const WebsiteLookupException(
        'The website lookup API did not return a valid website URL.',
      );
    }
    return url;
  }

  Uri _buildRequestUri(String query) {
    final rawEndpoint = endpoint.trim();
    if (rawEndpoint.contains('{query}')) {
      return Uri.parse(
        rawEndpoint.replaceAll('{query}', Uri.encodeQueryComponent(query)),
      );
    }

    final uri = Uri.parse(rawEndpoint);
    final queryParameters = <String, String>{
      ...uri.queryParameters,
      queryParameter: query,
    };
    return uri.replace(queryParameters: queryParameters);
  }

  String? _extractUrl(dynamic value) {
    if (value is String) return _normalizeUrl(value);

    if (value is List) {
      for (final item in value) {
        final url = _extractUrl(item);
        if (url != null) return url;
      }
      return null;
    }

    if (value is! Map) return null;

    const urlKeys = <String>[
      'url',
      'websiteUrl',
      'website_url',
      'webUrl',
      'web_url',
      'href',
      'link',
      'redirectUrl',
      'redirect_url',
    ];
    for (final key in urlKeys) {
      final url = _extractUrl(value[key]);
      if (url != null) return url;
    }

    for (final key in const ['data', 'result', 'payload']) {
      final url = _extractUrl(value[key]);
      if (url != null) return url;
    }
    return null;
  }

  String? _normalizeUrl(String value) {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) return null;
    if (uri.scheme != 'http' && uri.scheme != 'https') return null;
    return uri.toString();
  }

  void dispose() {
    if (_ownsClient) _client.close();
  }
}

class WebsiteLookupException implements Exception {
  const WebsiteLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
