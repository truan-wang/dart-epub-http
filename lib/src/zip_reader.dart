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
  Future<List<int>> getFile(String fullPath) async {
    final f = arc.findFile(fullPath);
    if (f != null) {
      return f.content;
    }
    return [];
  }
}
