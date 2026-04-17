import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class VideoThumbnailGenerator extends StatefulWidget {
  final String videoUrl;
  const VideoThumbnailGenerator({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailGenerator> createState() =>
      _VideoThumbnailGeneratorState();
}

class _VideoThumbnailGeneratorState extends State<VideoThumbnailGenerator> {
  String? _thumbnailPath;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final thumbnailPath = await VideoThumbnail.thumbnailFile(
      video: widget.videoUrl,
      thumbnailPath: (await getTemporaryDirectory()).path,
      imageFormat: ImageFormat.WEBP,
      quality: 75,
    );
    if (mounted) {
      setState(() {
        _thumbnailPath = thumbnailPath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailPath == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Image.file(File(_thumbnailPath!), fit: BoxFit.cover);
    }
  }
}
