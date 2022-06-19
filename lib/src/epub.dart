import 'dart:convert';
import 'package:xml/xml.dart';

import './reader.dart';
import './zip_reader.dart';
import './writer.dart';

const mimetypeContent = "application/epub+zip";
const containerPath = "META-INF/container.xml";

String getBaseDir(String path) {
  int i = path.indexOf("/");
  if (i == -1) {
    return "";
  }
  return path.substring(0, i);
}

enum MediaType {
  noop,
  oebps,
  xhtml;

  @override
  String toString() {
    switch (this) {
      case oebps:
        return "application/oebps-package+xml";
      case xhtml:
        return "TODO";
      default:
        return "unknown";
    }
  }

  static MediaType fromString(String str) {
    switch (str) {
      case "application/oebps-package+xml":
        return oebps;
    }
    return noop;
  }
}

class Base {
  final Map<String, String> attributes = {};
}

class Rootfile extends Base {
  final String fullPath;
  MediaType mediaType = MediaType.oebps;
  // todo: render-

  String get baseDir {
    return getBaseDir(fullPath);
  }

  Rootfile({required this.fullPath, this.mediaType = MediaType.oebps});
  static Rootfile fromXmlElement(XmlElement e) {
    final fullPath = e.getAttribute("full-path") ?? "content.opf";
    final mediaType =
        e.getAttribute("media-type") ?? MediaType.oebps.toString();

    return Rootfile(
        fullPath: fullPath, mediaType: MediaType.fromString(mediaType));
  }
}

class Metadata {
  static Metadata fromXmlElement(XmlElement e) {
    // todo:
    return Metadata();
  }
}

class ManifestItem {
  final String id;
  final String href;
  final String mediaType;
  final String? properties;
  final String? fallback;
  final String? mediaOverlay;

  ManifestItem(
      {required this.id,
      required this.href,
      required this.mediaType,
      this.properties,
      this.fallback,
      this.mediaOverlay});
}

class Manifest {
  final List<ManifestItem> items;
  Manifest(this.items);
  static Manifest fromXmlElement(XmlElement e) {
    return Manifest(e.children
        .map((n) => ManifestItem(
              id: n.getAttribute("id") ?? "",
              href: n.getAttribute("href") ?? "",
              mediaType: n.getAttribute("media-type") ?? "",
              properties: n.getAttribute("properties"),
              fallback: n.getAttribute("fallback"),
              mediaOverlay: n.getAttribute("media-overlay"),
            ))
        .where((n) => n.id != "" && n.href != "" && n.mediaType != "")
        .toList());
  }
}

class Spine {
  static Spine fromXmlElement(XmlElement e) {
    // todo:
    return Spine();
  }
}

class Package {
  final String baseDir;

  final String version;
  final String uniqueIdentifier;
  final String? id;
  final String? dir;
  final String? prefix;
  final String? xmlLang;

  final Metadata metadata;
  final Manifest manifest;
  final Spine spine;
  // guide
  // hinding
  // collection

  Package(
      {required this.baseDir,
      required this.version,
      required this.uniqueIdentifier,
      this.id,
      this.dir,
      this.prefix,
      this.xmlLang,
      required this.metadata,
      required this.manifest,
      required this.spine});

  static Package fromXML(String xmlContent, String baseDir) {
    final document = XmlDocument.parse(xmlContent);
    final package = document.getElement("package",
        namespace: "http://www.idpf.org/2007/opf");
    if (package == null) {
      throw Exception("invalid xml");
    }
    final version = package.getAttribute("version")!;
    final uniqueIdentifier = package.getAttribute("unique-identifier")!;
    final manifestXML = package.getElement("manifest");
    final metadataXML = package.getElement("metadata");
    final spineXML = package.getElement("spine");
    Manifest manifest;
    Metadata metadata;
    Spine spine;
    if (manifestXML != null) {
      manifest = Manifest.fromXmlElement(manifestXML);
    } else {
      manifest = Manifest([]);
    }
    if (metadataXML != null) {
      metadata = Metadata.fromXmlElement(metadataXML);
    } else {
      metadata = Metadata();
    }
    if (spineXML != null) {
      spine = Spine.fromXmlElement(spineXML);
    } else {
      spine = Spine();
    }
    return Package(
        baseDir: baseDir,
        version: version,
        uniqueIdentifier: uniqueIdentifier,
        metadata: metadata,
        manifest: manifest,
        spine: spine);
  }
}

class Epub {
  Epub({this.reader, this.writer});

  static Epub open(
      {String? filename,
      List<int>? data,
      String? password,
      String? folder,
      String? url}) {
    EpubReader? reader;
    if (filename != null || data != null) {
      reader =
          ZipEpubReader(filename: filename, data: data, password: password);
    } else if (folder != null) {
      // todo:
    } else if (url != null) {
      // todo:
    }
    final e = Epub(reader: reader);
    return e;
  }

  EpubReader? reader;
  EpubWriter? writer;

  Future<List<Package>> get packages async {
    List<Package> result = [];
    for (final rootfileFullPath in await getRootFiles()) {
      final content =
          Utf8Decoder().convert(await reader!.getFile(rootfileFullPath));

      result.add(Package.fromXML(content, getBaseDir(rootfileFullPath)));
    }
    return result;
  }

  Future<Package?> get package async {
    final ps = await packages;
    return ps.isEmpty ? null : ps[0];
  }

  Future<List<String>> getRootFiles() async {
    assert(reader != null);

    final content = Utf8Decoder().convert(await reader!.getFile(containerPath));
    final document = XmlDocument.parse(content);
    final container = document.getElement("container",
        namespace: "urn:oasis:names:tc:opendocument:xmlns:container");
    if (container == null) {
      return [];
    }
    final rootfiles = container!.getElement("rootfiles");
    if (rootfiles != null) {
      return rootfiles.children
          .map((n) => n.getAttribute("full-path") ?? "")
          .where((n) => n != "")
          .toList(growable: false);
    }
    return [];
  }
}
