import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:path/path.dart' as p;

import './reader.dart';

class HttpEpubReader extends EpubReader {
  HttpEpubReader({required this.baseUri});

  final Uri baseUri;
  RetryClient? client;

  @override
  Future<Uint8List> getFile(String fullPath) async {
    final url = baseUri.replace(path: p.join(baseUri.path, fullPath));
    client ??= RetryClient(http.Client());

    return await client!.readBytes(url);
  }

  void close() {
    client?.close();
  }

}
