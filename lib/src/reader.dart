
abstract class EpubReader {
  Future<List<String>> listFiles() async {
    return <String>["mimetype", "META-INF/container.xml"];
  }

  Future<List<int>> getFile(String fullPath);
}
