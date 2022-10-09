# 技术笔记

epub 是一个广泛使用的标准电子书格式，支持epub标准格式，即可以方便导入大量现有的电子书，也有利于与其它组织的合作交流。但是epub格式电子书将一本书打包后作为一个整体，需要下载到本地才能阅读，我们希望无需下载就可以直接在线阅读EPUB文件，所以我们需要对EPUB进行了一些扩展。

## EPUB格式简介，详情参考[EPUB3标准文档](https://www.w3.org/publishing/epub3/epub-spec.html)

EPUB OCF(Open Container Format) 使用 zip 将一本电子书的所有资源打包在一个文件里，一个epub文件夹里的内容的示例结构如下：

```bash
mimetype
META-INF |
   container.xml
content.opf
content.ncx
nav.xhtml
xhtml |
    cover.xhtml
    chapter1.xhtml
    chapter2.xhtml
styles |
    stylesheet.css
images |
    cover.jpg
```

其中 mimetype 文件内容固定为“application/epub+zip"；

container.xml的示例格式如下：（主要作用是告诉我们content.opf文件的位置信息）

```xml
<?xml version="1.0" encoding="UTF-8"?>
<container xmlns="urn:oasis:names:tc:opendocument:xmlns:container" version="1.0">
  <rootfiles>
    <rootfile full-path="content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
```

content.opf的示例格式如下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/" version="2.0" unique-identifier="bookid">
  <metadata>
    <dc:title>Sample</dc:title>
    <dc:identifier id="bookid">123456</dc:identifier>
    <dc:language>zh-CN</dc:language>
    <dc:creator>truan wang</dc:creator>
    <dc:publisher>k6-12.com</dc:publisher>
    <dc:source>123456</dc:source>
    <dc:rights>All rights reserved</dc:rights>
    <dc:type>demo</dc:type>
    <meta name="cover" content="cover-image"/>
  </metadata>
  <manifest>
    <item id="html-cover-page" href="xhtml/cover.xhtml" media-type="application/xhtml+xml"/>
    <item id="chapter1" href="xhtml/chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="chapter2" href="xhtml/chapter2.xhtml" media-type="application/xhtml+xml"/>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="cover-image" href="images/cover.jpg" media-type="image/jpeg"/>
    <item id="css" href="styles/stylesheet.css" media-type="text/css"/>
    <item id="content" href="content.ncx" media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="content">
    <itemref idref="html-cover-page" linear="yes"/>
    <itemref idref="chapter1" linear="yes"/>
    <itemref idref="chapter2" linear="yes"/>
  </spine>
  <guide>
    <reference type="cover" title="Cover Image" href="xhtml/cover.xhtml"/>
  </guide>
</package>

```
其中 metadata 为书本加入一些元信息；
其中manifest 列出所有 不在META-INF文件夹下的文件；
其中spine表示顺序阅读情况下的文档加载顺序（可以通过toc指定目录信息）;
此外 content.ncx 是epub2中规定的目录，epub3中使用 nav.html （properties="nav"）作为目录；

当阅读epub文件时候，需要使用zip解压文件，从 META-INF/container.xml 开始 获取 epub文件的 rootfile，rootfile 必须是一个 OPF(Open Packaging Format)的xml文件， 在这个xml文件里有个 manifest 的 元素，里面包含整个epub包里的所有资源文档及其属性（id，链接地址，类型）。阅读epub文件的过程就是按照spine或者nav去打开对应的资源文档的过程。可以简划为三个主要步骤：
1. 解析META-INF/container.xml 获得根文件信息
2. 解析根文件opf，获得package的结构信息
3. 按需加载资源文档（事实上，很多epub阅读器会一次性加载所有资源文档到内存）

## 设计思路

实现一个epub解析器（编辑器）能够直接读取（写入）远程服务器上的epub文件，而不需要完整地下载到本地；支持读取下载到本地的epub文件；支持直接读取在内存中的一个完整的epub文件；支持将本地的一个文件夹当作epub文件来读取（写入），也许这个本地文件夹恰巧是远程服务器上某个epub文件的本地缓存；可以将一个提供静态内容服务的web服务器的一个目录当作epub文件来读去。

这中间主要的区别只是如何读区（写入）epub包中的文件列表以及指定的一个文件，我们只在这一层面上做抽象，而不像[Radium](https://readium.org/architecture/)那样在文档内容上做抽象。

我们通过一个抽象接口提供两个方法：

1. 列出epub包的文件列表（这个接口都不是必须，我们只需要直接读取META-INF/container.xml文件即可）
2. 获取epub包中一个文件的内容

在可编辑情况下，需要额外提供两个方法：

1. 添加一个文件到包
2. 删除包里一个文件（可选的）
3. 删除包里没有使用到的所有文件（可选的）

我们可以根据需要实现一些服务通过http/websocket/rpc/... 协议来提供这些接口。

## 接口定义

```dart
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

class ZipEpubReader extends EpubReader {}

class DirEpubReader extends EpubReader {}
class DirEpubWriter extends EpubWriter {}

class HttpEpubReader extends EpubReader {}
class HttpEpubWriter extends EpubWriter {}

class Epub{
EpubReader? reader;
EpubWriter? writer;

Epub({this.reader, this.writer});
static Epub open({String? filename, String? folder, Uint8list? fileData, String? url, bool readonly=true});

}
```
