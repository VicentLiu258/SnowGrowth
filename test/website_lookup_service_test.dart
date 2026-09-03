import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:snow_growth/features/tools/data/website_lookup_service.dart';

void main() {
  test('adds the search query and extracts a nested website URL', () async {
    final client = _FakeClient(
      '{"data":{"url":"https://verify.example.com/session"}}',
    );
    final service = WebsiteLookupService(
      endpoint: 'https://api.example.com/lookup',
      client: client,
    );

    final url = await service.fetchWebsiteUrl('ic');

    expect(url, 'https://verify.example.com/session');
    expect(client.requestedUri?.queryParameters['keyword'], 'ic');
  });

  test('rejects a response without an HTTP(S) website URL', () async {
    final service = WebsiteLookupService(
      endpoint: 'https://api.example.com/lookup',
      client: _FakeClient('{"data":{"url":"javascript:alert(1)"}}'),
    );

    expect(
      service.fetchWebsiteUrl('ic'),
      throwsA(isA<WebsiteLookupException>()),
    );
  });

  test('accepts a plain-text URL response', () async {
    final service = WebsiteLookupService(
      endpoint: 'https://api.example.com/lookup',
      client: _FakeClient('https://verify.example.com'),
    );

    expect(await service.fetchWebsiteUrl('ic'), 'https://verify.example.com');
  });
}

class _FakeClient extends http.BaseClient {
  _FakeClient(this.body);

  final String body;
  Uri? requestedUri;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestedUri = request.url;
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      200,
      request: request,
    );
  }
}
