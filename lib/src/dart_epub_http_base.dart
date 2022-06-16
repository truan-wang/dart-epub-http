import 'dart:typed_data';

abstract class EpubReader {
  Future<List<String>> listFiles() async {
    return <String>["mimetype", "META-INF/container.xml"];
  }

  Future<String> getFile(String fullPath);
}

abstract class EpubWriter {
  Future<void> writeFile(String fullPath, String content);
  Future<void> removeFile(String fullPath) async {}
}

class ZipEpubReader extends EpubReader {
  @override
  Future<String> getFile(String fullPath) {
    // TODO: implement getFile
    throw UnimplementedError();
  }
}

class ZipEpubWriter extends EpubWriter {
  @override
  Future<void> writeFile(String fullPath, String content) {
    // TODO: implement writeFile
    throw UnimplementedError();
  }
}

class DirEpubReader extends EpubReader {
  @override
  Future<String> getFile(String fullPath) {
    // TODO: implement getFile
    throw UnimplementedError();
  }
}

class DirEpubWriter extends EpubWriter {
  @override
  Future<void> writeFile(String fullPath, String content) {
    // TODO: implement writeFile
    throw UnimplementedError();
  }
}

class HttpEpubReader extends EpubReader {
  @override
  Future<String> getFile(String fullPath) {
    // TODO: implement getFile
    throw UnimplementedError();
  }
}

class HttpEpubWriter extends EpubWriter {
  @override
  Future<void> writeFile(String fullPath, String content) {
    // TODO: implement writeFile
    throw UnimplementedError();
  }
}

class Epub {
  EpubReader? reader;
  EpubWriter? writer;

  Epub({this.reader, this.writer});
  Epub.open(
      {String? filename,
      String? folder,
      Uint8List? data,
      String? url,
      bool readonly = true});
}
