abstract class EpubWriter {
  Future<void> writeFile(String fullPath, String content);
  Future<void> removeFile(String fullPath);
}
