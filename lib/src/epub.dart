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

import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'reader.dart';
import 'zip_reader.dart';
import 'dir_reader.dart';
import 'http_reader.dart';
import 'writer.dart';
//import 'dir_writer.dart';

const mimetypeContent = "application/epub+zip";
const containerPath = "META-INF/container.xml";

/// media-type 
enum MediaType {
  unknown,
  xml,
  oebps,
  xhtml,
  html,
  svg,
  css,
  ttf,
  otf,
  woff,
  woff2,
  jpg,
  png,
  webp,
  gif,
  mp3,
  mp4,
  opus,
  smil,
  ncx,
  jsonld,
  javascript;

  static Map<String, MediaType> m = {
    "application/xml": xml,
    "text/html": html,
    "application/smil+xml": smil,
    "application/oebps-package+xml": oebps,
    "application/xhtml+xml": xhtml,
    "application/x-dtbncx+xml": ncx,
    "image/svg+xml": svg,
    "image/gif": gif,
    "image/jpeg": jpg,
    "image/png": png,
    "image/webp": webp,
    "audio/mpeg": mp3,
    "audio/mp4": mp4,
    "audio/opus": opus,
    "text/css": css,
    "application/font-sfnt": ttf,
    "font/ttf": ttf,
    "application/vnd.ms-opentype": otf,
    "font/otf": otf,
    "application/font-woff": woff,
    "font/woff": woff,
    "font/woff2": woff2,
    "text/javascript": javascript,
    "application/ecmascript": javascript,
    "application/javascript": javascript,
    "application/ld+json": jsonld,
  };
  static Map<MediaType, String> mr = m.map((k, v) => MapEntry(v, k));

  @override
  String toString() {
    return MediaType.mr[this] ?? "unknown";
  }

  static MediaType fromString(String str) {
    return MediaType.m[str] ?? unknown;
  }
}

/// metadata 
class Metadata {
  /// dc namespaces
  List<String> identifiers = [];
  List<String> titles = [];
  List<String> languages = [];
  /// first identifer
  String get identifier => identifiers.isNotEmpty ? identifiers.first : "";
  /// first title
  String get title => titles.isNotEmpty ? titles.first : "";
  /// first language
  String get language => languages.isNotEmpty ? languages.first : "";

  /// The dc:contributor element [dcterms] is used to represent the name of a person, organization, etc. that played a secondary role in the creation of the content.
  String? contributor;
  /// The dc:creator element [dcterms] represents the name of a person, organization, etc. responsible for the creation of the content. EPUB creators MAY associate a role property with the element to indicate the function the creator played.
  String? creator;
  /// The dc:date element [dcterms] defines the publication date of the EPUB publication. The publication date is not the same as the last modified date (the last time the EPUB creator changed the EPUB publication).
  String? date;
  /// The dc:subject element [dcterms] identifies the subject of the EPUB publication.
  String? subject;
  /// The dc:type element [dcterms] is used to indicate that the EPUB publication is of a specialized type (e.g., annotations or a dictionary packaged in EPUB format).
  String? type;
  /// publish by
  String? publisher;
  /// copyrights info
  String? rights;

  /// epubs 3.0 use meta.property : meta.text()
  /// epubs 2.0 use meta.name : meta.content
  Map<String, String> metas = {};

  /// last modified date
  /// meta property=dectems:modified
  DateTime? lastModified;

  Metadata();

  static Metadata fromXmlElement(XmlElement e,
      {String uniqueIdentifier = "bookid", String packageVersion = "3.0"}) {
    final m = Metadata();
    e.findElements("*").forEach((n) {
      if (n.name.toString() == "dc:identifier") {
        if (n.getAttribute("id") != null) {
          m.identifiers.insert(0, n.innerText.trim());
        } else {
          m.identifiers.add(n.innerText.trim());
        }
      } else if (n.name.toString() == "dc:title") {
        m.titles.add(n.innerText.trim());
      } else if (n.name.toString() == "dc:language") {
        m.languages.add(n.innerText.trim());
      } else if (n.name.toString() == "dc:date") {
        m.date = n.innerText.trim();
      } else if (n.name.toString() == "dc:contributor") {
        m.contributor = n.innerText.trim();
      } else if (n.name.toString() == "dc:creator") {
        m.creator = n.innerText.trim();
      } else if (n.name.toString() == "dc:subject") {
        m.subject = n.innerText.trim();
      } else if (n.name.toString() == "dc:type") {
        m.type = n.innerText.trim();
      } else if (n.name.toString() == "dc:publisher") {
        m.publisher = n.innerText.trim();
      } else if (n.name.toString() == "dc:rights") {
        m.rights = n.innerText.trim();
      } else if (n.name.toString() == "meta") {
        String k = "", v = n.innerText.trim();
        for (var a in n.attributes) {
          if (a.name.local == "property" && a.value == "dcterms:modified") {
            m.lastModified = DateTime.parse(n.innerText.trim());
          } else if (a.name.local == "name" || a.name.local == "property") {
            k = a.value;
          } else if (a.name.local == "content") {
            v = a.value;
          }
        }
        if (k != "" && v != "") {
          m.metas[k] = v;
        }
      } else {
        print(n.name.toString()); // TODO: 
      }
    });
    return m;
  }
}

/// a resource item in epub
class ResourceItem {
  final String id;
  final String href;
  final MediaType mediaType;
  final String? properties;
  final String? fallback;
  final String? mediaOverlay;

  ResourceItem(
      {required this.id,
      required this.href,
      required this.mediaType,
      this.properties,
      this.fallback,
      this.mediaOverlay});
}

/// manifest, all resource items in epub should be defined is manifest
class Manifest {
  final Map<String, ResourceItem> items = {};

  static Manifest fromXmlElement(XmlElement e) {
    final m = Manifest();
    e
        .findElements("item")
        .map((n) => ResourceItem(
              id: n.getAttribute("id")!,
              href: n.getAttribute("href")!,
              mediaType: MediaType.fromString(n.getAttribute("media-type")!),
              properties: n.getAttribute("properties"),
              fallback: n.getAttribute("fallback"),
              mediaOverlay: n.getAttribute("media-overlay"),
            ))
        .forEach((element) {
      m.items[element.id] = element;
    });
    return m;
  }
}

/// define liner read order of an epub file
class Spine {
  String? id;
  /// The NCX [opf-201] is a legacy feature that previously provided the table of contents.
  String? toc;
  /// The page-progression-direction attribute sets the global direction in which the content flows. Allowed values are ltr (left-to-right), rtl (right-to-left) and default. When EPUB creators specify the default value, they are expressing no preference and the reading system can choose the rendering direction.
  String? pageProgressionDirection;

  List<String> items = [];

  static Spine fromXmlElement(XmlElement e) {
    final s = Spine();
    s.id = e.getAttribute("id");
    s.toc = e.getAttribute("toc");
    s.pageProgressionDirection = e.getAttribute("page-progression-direction");

    e
        .findElements("itemref")
        .where((r) => r.getAttribute("idref") != null)
        .forEach((r) {
      s.items.add(r.getAttribute("idref")!);
    });

    return s;
  }
}

/// describe one way to read an epub file.
/// an epub file may have muliple renditions
class Rendition {
  /// rootfile element attributes
  String fullPath;

  /// all resource under the baseDir
  String get baseDir {
    int i = fullPath.lastIndexOf("/");
    if (i == -1) {
      return "";
    }
    return fullPath.substring(0, i);
  }

  /// default and not change able
  final MediaType mediaType = MediaType.oebps;

  /// rootfile attributes, namespace: http://www.idpf.org/2013/rendition
  /// A CSS 3 media query [mediaqueries], where the media type, if specified, MUST only be the value "all".
  String? media;
  /// The value of the attribute MUST be reflowable or pre-paginated.
  String? layout;
  /// MUST contain a valid language code conforming to [rfc5646]
  String? language;
  /// MUST be one or more of the values: auditory, tactile, textual or visual
  String? accessMode;
  /// name for manual rendition selection
  String? label;

  /// package element attributes
  /// support 2.0, 3.0, default 3.0
  String version;
  /// id of element which hold real unique identifier, default bookid
  String uniqueIdentifier;
  /// useless
  String? id;
  /// reading direction, allowed values are: ltr, rtl, auto
  String? dir;
  /// todo:
  String? prefix;
  ///  MUST be a well-formed language tag [bcp47]
  String? xmlLang;

  /// The metadata element encapsulates meta information
  Metadata metadata = Metadata();

  /// The manifest element provides an exhaustive list of publication resources used in the rendering of the content
  Manifest manifest = Manifest();

  /// The spine element defines an ordered list of manifest item references that represent the default reading order
  Spine spine = Spine();

  /// todo: guide

  /// todo: collection

  Rendition({
    this.fullPath = "content.opf",
    this.version = "3.0",
    this.uniqueIdentifier = "bookid",
    this.media,
    this.layout,
    this.language,
    this.accessMode,
    this.label,
    this.id,
    this.dir,
    this.prefix,
    this.xmlLang,
  });

  void parsePackageXml(String xmlContent) {
    final document = XmlDocument.parse(xmlContent);
    final package = document.getElement("package",
        namespace: "http://www.idpf.org/2007/opf");
    if (package == null) {
      throw Exception("invalid xml");
    }

    version = package.getAttribute("version")!;
    uniqueIdentifier = package.getAttribute("unique-identifier")!;
    id = package.getAttribute("id");
    dir = package.getAttribute("dir");
    prefix = package.getAttribute("prefix");
    xmlLang = package.getAttribute("xml:lang"); // fixme? xml namespace?

    final manifestXML = package.getElement("manifest");
    final metadataXML = package.getElement("metadata");
    final spineXML = package.getElement("spine");
    if (manifestXML != null) {
      manifest = Manifest.fromXmlElement(manifestXML);
    }
    if (metadataXML != null) {
      metadata = Metadata.fromXmlElement(metadataXML);
    }
    if (spineXML != null) {
      spine = Spine.fromXmlElement(spineXML);
    }
  }

  void parseRootfile(XmlNode rootfile) {
    fullPath = rootfile.getAttribute("full-path")!;
    media = rootfile.getAttribute("media",
        namespace: "http://www.idpf.org/2013/rendition");
    layout = rootfile.getAttribute("layout",
        namespace: "http://www.idpf.org/2013/rendition");
    language = rootfile.getAttribute("language",
        namespace: "http://www.idpf.org/2013/rendition");
    accessMode = rootfile.getAttribute("accessMode",
        namespace: "http://www.idpf.org/2013/rendition");
    label = rootfile.getAttribute("label",
        namespace: "http://www.idpf.org/2013/rendition");
  }

  /// get full path of the resource item with id [id]
  String? getFullPath(String id) {
    final href = manifest.items[id]?.href;
    if (href != null) {
      return p.join(baseDir, href);
    }
    return null;
  }

}

/// an .epub package
class Epub {
  Epub({this.reader, this.writer});

  /// Open an epub file for readonly.
  /// If filename [filename] or data [data] is not null, build a ZipEpubReader use filename or data;
  /// If folder [folder] is not null, build a DirEpubReader use the folder;
  /// If url [url] is not null, build a HttpEpubReader use the url.
  static Epub open(
      {
      String? filename,
      List<int>? data,
      String? password,
      String? folder,
      String? url}) {
    EpubReader? reader;
    if (filename != null || data != null) {
      reader =
          ZipEpubReader(filename: filename, data: data, password: password);
    } else if (folder != null) {
      reader = DirEpubReader(baseDir: folder);
    } else if (url != null) {
      reader = HttpEpubReader(baseUri: Uri.parse(url));
    }
    final e = Epub(reader: reader);
    return e;
  }

  /// define how to read a file in the epub package.
  EpubReader? reader;

  /// define how to write a file to the epub package.
  EpubWriter? writer;

  /// get all renditions of the epub package.
  Future<List<Rendition>> get renditions async {
    List<Rendition> result = [];
    for (final rootfile in await getRootFiles()) {
      final rootfileFullPath = rootfile.getAttribute("full-path")!;
      final content =
          Utf8Decoder().convert(await reader!.readFile(rootfileFullPath));

      final r = Rendition();

      r.parseRootfile(rootfile);
      r.parsePackageXml(content);
      result.add(r);
    }
    return result;
  }

  /// get first rendition of the epub package.
  /// most epub package have only one rendition.
  Future<Rendition?> get rendition async {
    final ps = await renditions;
    return ps.isEmpty ? null : ps[0];
  }

  /// an rootfile define a rendition of the epub package.
  Future<List<XmlNode>> getRootFiles() async {
    assert(reader != null);

    final content = Utf8Decoder().convert(await reader!.readFile(containerPath));
    final document = XmlDocument.parse(content);
    final container = document.getElement("container",
        namespace: "urn:oasis:names:tc:opendocument:xmlns:container");
    if (container == null) {
      return [];
    }
    final rootfiles = container.getElement("rootfiles");
    if (rootfiles != null) {
      return rootfiles.findElements("rootfile").toList(growable: false);
    }
    return [];
  }

  /// read a file in the epub package.
  Future<List<int>> readFile(String fullPath) => reader!.readFile(fullPath);
  
}
