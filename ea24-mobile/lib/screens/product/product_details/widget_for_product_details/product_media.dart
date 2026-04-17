import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ProductMedia {
  final String type;
  final String url;
  final String? thumbnail;
  final bool isShort;

  ProductMedia({
    required this.type,
    required this.url,
    this.thumbnail,
    this.isShort = false,
  });
}

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
    try {
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
    } catch (e) {
      if (kDebugMode) {
        print("Error generating thumbnail: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailPath == null) {
      return const Center(child: CircularProgressIndicator());
    } else {
      return Image.file(
        File(_thumbnailPath!),
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }
  }
}

// Player screen for self-hosted videos.
class VideoScreen extends StatefulWidget {
  final String videoUrl;
  const VideoScreen({super.key, required this.videoUrl});
  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _videoPlayerController;
  late ChewieController _chewieController;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    initializePlayer();
  }

  Future<void> initializePlayer() async {
    _videoPlayerController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    await _videoPlayerController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: true,
      looping: false,
      materialProgressColors: ChewieProgressColors(
        playedColor: Color(0xff0078D7),
        handleColor: Color(0xff0078D7),
        bufferedColor: Color(0xffEFEFEF),
        backgroundColor: Colors.white,
      ),

      cupertinoProgressColors: ChewieProgressColors(
        playedColor: Color(0xff0078D7),
        handleColor: Color(0xff0078D7),
        bufferedColor: Color(0xffEFEFEF),
        backgroundColor: Colors.white,
      ),
    );
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Chewie(controller: _chewieController),
          ),
          Positioned(
            top: 40.0,
            left: 10.0,
            child: IconButton(
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30.0,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class YoutubePlayerScreen extends StatefulWidget {
  final String youtubeUrl;
  const YoutubePlayerScreen({super.key, required this.youtubeUrl});

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  bool _isShorts = false;

  @override
  void initState() {
    super.initState();
    _enterFullScreen();

    final videoId = YoutubePlayer.convertUrlToId(widget.youtubeUrl)!;
    _isShorts = widget.youtubeUrl.contains('/shorts/');

    _controller = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
    );
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _exitFullScreen();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: YoutubePlayer(
              controller: _controller,
              aspectRatio: _isShorts ? 9 / 16 : 16 / 9,
              showVideoProgressIndicator: true,
              progressColors: const ProgressBarColors(
                playedColor: Colors.white,
                handleColor: Colors.white,
                bufferedColor: Colors.white54,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
