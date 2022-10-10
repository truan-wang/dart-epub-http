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

import 'dart:convert';

import 'package:dart_epub_http/dart_epub_http.dart';

void main() async{

  var f = Epub.open(filename: "./test/the-art-of-war.epub");
  // f = Epub.open(folder: "./test/the-art-of-war");
  // f = Epub.open(url: "https://ebooks.k6-12.com/epub/the-art-of-war");

  final r = await f.rendition;
  final m = r!.metadata;
  print(m.title);
  print(m.creator);
  for (var k in m.metas.keys){
    print("$k = ${m.metas[k]}");
  }

  for (var id in r.spine.items) {
    final fullPath = r.getFullPath(id)!;
    print(Utf8Decoder().convert(await f.readFile(fullPath)));
  }

}