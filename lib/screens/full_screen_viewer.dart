import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

class FullScreenViewer extends StatefulWidget {
  final String url;
  final String type;

  const FullScreenViewer({required this.url, required this.type});

  @override
  _FullScreenViewerState createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  VideoPlayerController? controller;

  @override
  void initState() {
    super.initState();

    if (widget.type == "video") {
      controller = VideoPlayerController.network(widget.url)
        ..initialize().then((_) {
          setState(() {});
          controller!.play();
        });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: widget.type == "image"
            ? PhotoView(
          imageProvider: NetworkImage(widget.url),
        )
            : controller != null && controller!.value.isInitialized
            ? AspectRatio(
          aspectRatio: controller!.value.aspectRatio,
          child: VideoPlayer(controller!),
        )
            : CircularProgressIndicator(),
      ),
    );
  }
}