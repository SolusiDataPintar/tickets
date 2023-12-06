import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

@RoutePage()
class ImageViewerPage extends StatelessWidget {
  final String name;
  final String url;
  const ImageViewerPage({
    super.key,
    required this.name,
    required this.url,
  });
  @override
  Widget build(final BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: PhotoView(imageProvider: NetworkImage(url)),
      );
}
