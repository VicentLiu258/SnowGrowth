import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Dynamically fetches the WhatsApp link configured in SaleSmartly (`g210pqn`),
/// falling back to [fallbackUrl] if the network request fails.
class SalesmartlyChannelService {
  SalesmartlyChannelService._();

  static const _pluginId = 'g210pqn';
  static const _overTime = '1790143164';
  static const _env = 'pro';
  static const _signSecret = '62767a26b6abd87a258eeb52d16371ee';
  static const _endpoint = 'https://widget.salesmartly.com/plugin/info';

  static String? _cachedWhatsappUrl;
  static Future<String?>? _inflight;

  static void prefetch() {
    if (_cachedWhatsappUrl != null || _inflight != null) return;
    _inflight = _fetchWhatsappUrl().whenComplete(() => _inflight = null);
  }

  static Future<String> resolveWhatsappUrl(String fallbackUrl) async {
    if (_cachedWhatsappUrl != null && _cachedWhatsappUrl!.isNotEmpty) {
      return _cachedWhatsappUrl!;
    }
    try {
      final future = _inflight ?? _fetchWhatsappUrl();
      _inflight = future;
      final url = await future.timeout(const Duration(seconds: 3));
      _inflight = null;
      if (url != null && url.isNotEmpty) {
        _cachedWhatsappUrl = url;
        return url;
      }
    } catch (_) {
      _inflight = null;
    }
    return fallbackUrl;
  }

  static Future<String?> _fetchWhatsappUrl() async {
    try {
      final ts = DateTime.now().millisecondsSinceEpoch.toString();
      final params = <String, String>{
        'plugin_id': _pluginId,
        'over_time': _overTime,
        'env': _env,
        '_': ts,
        '_lt': '',
        '_u': '',
        '_xma_': '',
      };

      final sortedKeys = params.keys.toList()..sort();
      final queryStr = sortedKeys.map((k) => '$k=${params[k]}').join('&');
      final sign =
          md5.convert(utf8.encode('$_signSecret&$queryStr')).toString();

      final uri = Uri.parse(_endpoint).replace(queryParameters: params);
      final response = await http
          .get(uri, headers: {'external-sign': sign})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body);
      if (body is! Map || body['code'] != 0) return null;
      final data = body['data'];
      if (data is! Map) return null;

      final whatsappConfig = data['show_whatsapp_config'];
      if (whatsappConfig is! Map) return null;

      final redirectUrl =
          (whatsappConfig['redirect_url'] as String?)?.trim() ?? '';
      if (redirectUrl.isEmpty) return null;

      final prolusion = (whatsappConfig['prolusion'] as String?)?.trim() ?? '';
      final type = (whatsappConfig['type'] as String?)?.trim() ?? '1';

      var finalUrl = redirectUrl;
      if (prolusion.isNotEmpty && !finalUrl.contains('text=')) {
        final encodedText = Uri.encodeComponent(prolusion);
        final separator =
            (type == '3' || !finalUrl.contains('?')) ? '?' : '&';
        finalUrl = '$finalUrl${separator}text=$encodedText';
      }

      _cachedWhatsappUrl = finalUrl;
      return finalUrl;
    } catch (_) {
      return null;
    }
  }
}
