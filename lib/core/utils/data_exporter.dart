import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataExporter {
  DataExporter._();

  static Future<void> exportJson(
    Map<String, dynamic> data,
    String filename,
  ) async {
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json);

    await Share.shareXFiles([XFile(file.path)], subject: filename);
  }
}
