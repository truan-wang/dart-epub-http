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

import 'dart:io';
import './writer.dart';
import 'package:path/path.dart' as p;

class DirEpubWriter extends EpubWriter {
  DirEpubWriter({required this.baseDir});

  // base dir
  final String baseDir;

  @override
  Future<void> writeFile(String fullPath, String content) async {
    var file = File(p.join(baseDir, fullPath));
    file = await file.create(recursive: true);
    file.writeAsString(content);
  }

  @override
  Future<void> removeFile(String fullPath) async {
    var file = File(p.join(baseDir, fullPath));
    await file.delete(recursive: false);
  }
}
