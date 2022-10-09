import 'dart:typed_data';
import 'dart:io';
import 'package:path/path.dart' as p;

import './reader.dart';

class DirEpubReader extends EpubReader {

  DirEpubReader({required this.baseDir});

  // base dir
  final String baseDir;

  @override
  Future<Uint8List> getFile(String fullPath) {
    final file = File(p.join(baseDir, fullPath));

    return file.readAsBytes();
  }
}
