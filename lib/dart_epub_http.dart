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

/// Reading and writing (TODO) epub file.
///
/// Beside reading normal epub file, support reading a folder as epub file,
/// support reading epub file on web server, and you can define your reader
/// to define how to get a file in the epub package.
library dart_epub_http;

export 'src/reader.dart' show EpubReader;
export 'src/writer.dart' show EpubWriter;
export 'src/zip_reader.dart' show ZipEpubReader;
export 'src/http_reader.dart' show HttpEpubReader;
export 'src/dir_reader.dart' show DirEpubReader;
export 'src/dir_writer.dart' show DirEpubWriter;
export 'src/epub.dart' show Epub, MediaType, Rendition, ResourceItem, Spine, Manifest, Metadata;
