import 'package:flutter/material.dart';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:ui' as ui;

class ClickableWebImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;

  const ClickableWebImage({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Register a unique view type for this image
    final String viewType = 'clickable-img-${imageUrl.hashCode}';

    // Register the HTML image element
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final html.ImageElement img = html.ImageElement()
          ..src = imageUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '8px'
          ..style.pointerEvents = 'none'; // Allow Flutter to handle clicks
        return img;
      },
    );

    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
