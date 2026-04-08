import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

class FullScreenViewer extends StatefulWidget {
  final String url;
  final String type;

  const FullScreenViewer({super.key, required this.url, required this.type});

  @override
  _FullScreenViewerState createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<FullScreenViewer> {
  VideoPlayerController? controller;
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();

    if (widget.type == 'video') {
      controller = VideoPlayerController.network(widget.url)
        ..initialize().then((_) {
          controller!.setLooping(true);
          controller!.setVolume(1);
          if (!mounted) return;
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

  void _togglePlayback() {
    final videoController = controller;
    if (videoController == null || !videoController.value.isInitialized) return;

    setState(() {
      if (videoController.value.isPlaying) {
        videoController.pause();
      } else {
        videoController.play();
      }
    });
  }

  void _toggleMute() {
    final videoController = controller;
    if (videoController == null || !videoController.value.isInitialized) return;

    setState(() {
      _isMuted = !_isMuted;
      videoController.setVolume(_isMuted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: widget.type == 'image'
          ? PhotoView(
              imageProvider: NetworkImage(widget.url),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            )
          : _buildVideoViewer(),
    );
  }

  Widget _buildVideoViewer() {
    final videoController = controller;
    if (videoController == null || !videoController.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final isPlaying = videoController.value.isPlaying;

    return Stack(
      children: [
        Center(
          child: GestureDetector(
            onTap: _togglePlayback,
            child: AspectRatio(
              aspectRatio: videoController.value.aspectRatio,
              child: VideoPlayer(videoController),
            ),
          ),
        ),
        Positioned.fill(
          child: Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.28),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _togglePlayback,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                padding: const EdgeInsets.all(18),
                splashRadius: 30,
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    videoController,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Color(0xB3FFFFFF),
                      backgroundColor: Color(0x66FFFFFF),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _togglePlayback,
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_formatDuration(videoController.value.position)} / ${_formatDuration(videoController.value.duration)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _toggleMute,
                        icon: Icon(
                          _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
