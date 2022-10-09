import 'dart:io';
import './writer.dart';
import 'package:path/path.dart' as p;

class DirEpubWriter extends EpubWriter {

  DirEpubWriter({required this.baseDir});

  // base dir
  final String baseDir;

  @override
  Future<void> writeFile(String fullPath, String content) async{
    var file = File(p.join(baseDir, fullPath));
    file = await file.create(recursive: true);
    file.writeAsString(content);
  }
  
  @override
  Future<void> removeFile(String fullPath) async{
    var file = File(p.join(baseDir, fullPath));
    await file.delete(recursive: false);
  }
}
