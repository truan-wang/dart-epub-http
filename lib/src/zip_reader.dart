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

import 'package:archive/archive_io.dart';
import "./reader.dart";

class ZipEpubReader extends EpubReader {
  ZipEpubReader({String? filename, List<int>? data, String? password}) {
    if (filename != null) {
      arc = ZipDecoder()
          .decodeBuffer(InputFileStream(filename), password: password);
    } else if (data != null) {
      arc = ZipDecoder().decodeBytes(data, password: password);
    } else {
      arc = Archive();
    }
  }

  late Archive arc;

  @override
  Future<List<String>> listFiles() async {
    return arc.files
        .where((f) => f.isFile)
        .map((f) => f.name)
        .toList(growable: false);
  }

  @override
  Future<List<int>> readFile(String fullPath) async {
    final f = arc.findFile(fullPath);
    if (f != null) {
      return f.content;
    }
    return [];
  }
}
