# dart-epub-http
An epub parser and saver(todo) use customable read write file methods.

## Features
  - parse from an epub file or file data in memory
  - parse from web server
  - parse from a directory 
  - save to a directory 
  - parse epub file use custom get file method
  - save epub file use custom write file method


## Example

```dart
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
```

 Add more examples to `/example` folder. 

## Additional information

An epub reader is under development using flutter and this package.
