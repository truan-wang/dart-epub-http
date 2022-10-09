import 'dart:convert';

import 'package:dart_epub_http/dart_epub_http.dart';
import 'package:test/test.dart';

void main() {
  group('zip epub reader', () {
    final r =
        ZipEpubReader(filename: "./test/the-art-of-war.epub");

    setUp(() {
      // Additional setup goes here.
    });

    test('list files:', () async {
      for (var f in await r.listFiles()) {
        print(f);
      }
    });
    test('get file mimetype:', () async {
      print(Utf8Decoder().convert(await r.getFile("mimetype")));
    });
    test('get file container.xml:', () async {
      print(Utf8Decoder().convert(await r.getFile("META-INF/container.xml")));
    });
    test('get file not exists:', () async {
      print(Utf8Decoder().convert(await r.getFile("META-INF/not-exists.xml")));
    });
  });

  group('zip reader null', () {
    final r = ZipEpubReader();

    setUp(() {
      // Additional setup goes here.
    });

    test('list files:', () async {
      for (var f in await r.listFiles()) {
        print(f);
      }
    });
    test('get file not exists:', () async {
      print(Utf8Decoder().convert(await r.getFile("META-INF/not-exists.xml")));
    });
  });

  group('epub parser', () {
    final r = ZipEpubReader(filename: "./test/the-art-of-war.epub");
    final epub = Epub(reader: r);

    setUp(() {
      // Additional setup goes here.
    });

    test('parse packages:', () async {
      for (final p in await epub.renditions) {
        print(p);
      }
    });
  });
}
