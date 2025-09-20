import 'package:flutter/material.dart';
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:ui' as ui;

class WebImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  
  const WebImage({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Register a unique view type for this image
    final String viewType = 'img-${imageUrl.hashCode}';
    
    // Register the HTML image element
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final html.ImageElement img = html.ImageElement()
          ..src = imageUrl
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'  // Changed from 'cover' to 'contain' to show full image
          ..style.borderRadius = '8px';
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