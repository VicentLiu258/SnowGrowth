import 'package:flutter_test/flutter_test.dart';
import 'package:snow_growth/core/constants/app_config.dart';
import 'package:snow_growth/core/deep_link/deep_link_controller.dart';

void main() {
  test('parses the canonical HTTPS deep link', () {
    final uri = Uri.parse(AppConfig.deepLinkPublicUrl);

    expect(DeepLinkParser.keywordFor(uri), AppConfig.toolWebsiteTrigger);
  });

  test('parses the custom scheme deep link with a query keyword', () {
    final uri = Uri.parse(
      '${AppConfig.deepLinkScheme}://${AppConfig.deepLinkHost}?keyword=ic',
    );

    expect(DeepLinkParser.keywordFor(uri), 'ic');
  });

  test('ignores unrelated hosts and keywords', () {
    expect(
      DeepLinkParser.keywordFor(Uri.parse('https://example.com/open/ic')),
      isNull,
    );
    expect(
      DeepLinkParser.keywordFor(
        Uri.parse('https://www.snowgrowth.com/open/other'),
      ),
      isNull,
    );
  });
}
