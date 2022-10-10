//
// Copyright 2022 truan.wang.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

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
  Future<Uint8List> readFile(String fullPath) async {
    final url = baseUri.replace(path: p.join(baseUri.path, fullPath));
    client ??= RetryClient(http.Client());

    return await client!.readBytes(url);
  }

  void close() {
    client?.close();
  }

}
