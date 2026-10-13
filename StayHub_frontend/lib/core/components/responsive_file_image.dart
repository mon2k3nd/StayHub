import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Cross-platform image widget that works with [XFile].
/// On web: uses FutureBuilder + Image.memory (content URI safe).
/// On native: uses Image.file with File(xfile.path).
class XFileImage extends StatefulWidget {
  final XFile xfile;
  final BoxFit? fit;
  final double? width;
  final double? height;

  const XFileImage(this.xfile, {super.key, this.fit, this.width, this.height});

  @override
  State<XFileImage> createState() => _XFileImageState();
}

class _XFileImageState extends State<XFileImage> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.xfile.readAsBytes();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On web, always read as bytes — File path is a blob URL
      return FutureBuilder<Uint8List>(
        future: _bytesFuture,
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return Container(
              width: widget.width,
              height: widget.height,
              color: const Color(0xFFF3F4F6),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return Image.memory(
            snap.data!,
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
          );
        },
      );
    }
    // On native: use File directly — faster, no need for async
    return Image.file(
      File(widget.xfile.path),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
    );
  }
}

/// Legacy widget kept for backward compatibility (uses File, not XFile).
class ResponsiveFileImage extends StatelessWidget {
  final File file;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const ResponsiveFileImage(
    this.file, {
    super.key,
    this.fit,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        file.path,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    } else {
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder,
      );
    }
  }
}

/// A wrapper around [FileImage] that automatically falls back to [NetworkImage]
/// when running on the web.
ImageProvider getResponsiveFileImageProvider(String path) {
  if (kIsWeb) {
    return NetworkImage(path);
  } else {
    return FileImage(File(path));
  }
}
