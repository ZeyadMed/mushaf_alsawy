import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mushaf_alsawy/core/helpers/custom_shimmer_widget.dart';
import 'package:mushaf_alsawy/core/style/assets.dart';
import 'package:lottie/lottie.dart';


class FlexibleImage extends StatelessWidget {
  final dynamic source;
  final double borderRadius;
  final bool isCircular;
  final Widget? placeholder;
  final double? width;
  final double? height;
  final BoxFit? fit;
  const FlexibleImage({
    super.key,
    required this.source,
    this.borderRadius = 15,
    this.isCircular = false,
    this.placeholder,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  bool _isNetworkImage(String path) {
    final uri = Uri.tryParse(path);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  bool _isFileImage(String path) {
    try {
      return File(path).existsSync();
    } catch (_) {
      return false;
    }
  }

  bool _isMemoryImage(dynamic data) {
    return data is Uint8List;
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (source is String) {
      final src = source as String;

      // Data URI (base64) e.g. data:image/webp;base64,....
      if (src.startsWith('data:')) {
        try {
          final comma = src.indexOf(',');
          final meta = src.substring(5, comma); // image/webp;base64
          final isBase64 = meta.contains('base64');
          if (isBase64) {
            final base64Str = src.substring(comma + 1);
            final bytes = base64Decode(base64Str);
            imageWidget = Image.memory(
              bytes,
              fit: fit,
            );
          } else {
            imageWidget = placeholder ?? const Icon(Icons.image);
          }
        } catch (e) {
          imageWidget = placeholder ?? const Icon(Icons.broken_image);
        }
      } else if (_isFileImage(src)) {
        imageWidget = Image.file(
          File(src),
          fit: fit,
        );
      } else if (_isNetworkImage(src)) {
        imageWidget = CachedNetworkImage(
          imageUrl: src,
          placeholder: (context, url) =>
              placeholder ??
              Center(
                  child: CustomShimmerWidget(
                height: height,
              )),
          errorWidget: (context, url, error) =>
              Lottie.asset(Assets.assetsIconsLoading),
          fit: fit,
        );
      } else {
        // Treat as asset
        imageWidget = Image.asset(
          src,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => Lottie.asset(Assets.assetsIconsLoading),
        );
      }
    } else if (_isMemoryImage(source)) {
      imageWidget = Image.memory(
        source,
        fit: fit,
      );
    } else {
      imageWidget = placeholder ?? const Icon(Icons.image);
    }

    return SizedBox(
      width: width,
      height: height,
      child: imageWidget,
    );
  }
}
